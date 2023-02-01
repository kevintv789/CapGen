//
//  TextAreaView.swift
//  CapGen
//
//  Created by Kevin Vu on 12/29/22.
//

import SwiftUI

extension TextEditor {
    func customStyle() -> some View {
        self
            .font(.ui.headlineRegular)
            .foregroundColor(Color.ui.richBlack)
            .padding(14)
            .lineSpacing(6)
            .scrollContentBackground(.hidden)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.black, lineWidth: 2)
                    .shadow(
                        color: Color.ui.shadowGray.opacity(0.8),
                        radius: 2,
                        x: 1,
                        y: 2
                    )
                
            )
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.ui.lightOldPaper)
            )
    }
}

struct TextAreaView: View {
    let charLimit: Int = 500
    @Binding var text: String
    @State var placeholderText: String = "Example: Please generate a caption for a photo of my dog playing in the park. She's a rescue and brings so much joy to my life. Please come up with a caption that celebrates the love and happiness that pets bring into our lives."
    
    @State private var lastText: String = ""
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                if (text.isEmpty) {
                    TextEditor(text: $placeholderText)
                        .customStyle()
                        .disabled(true)
                }
                
                TextEditor(text: $text)
                    .customStyle()
                    .opacity(text.isEmpty ? 0.75 : 1)
                    .onChange(of: text) { text in
                        // Limit number of characters typed
                        if (text.count <= charLimit) {
                            lastText = text
                        } else {
                            self.text = lastText
                        }
                        
                        // Detect when 'done' or a newline is generated
                        if !text.filter({ $0.isNewline }).isEmpty {
                            self.text = String(text.dropLast())
                            hideKeyboard()
                        }
                    }
                    .submitLabel(.done)
                
                Text("\(text.count)/\(charLimit)")
                    .font(.ui.headlineRegular)
                    .foregroundColor(.ui.cadetBlueCrayola)
                    .frame(width: geo.size.width * 0.95, height: geo.size.height * 0.95, alignment: .bottomTrailing)
            }
            .onTapGesture {
                Haptics.shared.play(.soft)
            }
        }
    }
}
