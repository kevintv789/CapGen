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
            .font(.ui.graphikRegular)
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
    
    var isKeyboardFocused: FocusState<Bool>.Binding
    
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
                    .focused(isKeyboardFocused)
                    .onChange(of: text) { text in
                        if (text.count <= charLimit) {
                            lastText = text
                        } else {
                            self.text = lastText
                        }
                    }
                 
                Text("\(text.count)/\(charLimit)")
                    .font(.ui.graphikRegular)
                    .foregroundColor(.ui.cadetBlueCrayola)
                    .position(x: geo.size.width / 1.12, y: geo.size.height / 1.05)
                    
            }
        }
    }
}
