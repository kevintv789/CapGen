//
//  EditCaptionView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/25/23.
//

import SwiftUI

struct EditCaptionView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    // Requirements
    let bgColor: Color
    let captionTitle: String
    let platform: String
    let caption: String
    @State var editableCaption: String = ""
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            bgColor.ignoresSafeArea(.all)
            
            VStack(alignment: .leading) {
                // Header
                HStack {
                    BackArrowView { self.presentationMode.wrappedValue.dismiss() }
                        .padding(.leading, 8)
                    
                    Spacer()
                    
                    Image(platform)
                        .resizable()
                        .frame(width: 20, height: 20)
                    
                    Text(platform)
                        .foregroundColor(.ui.richBlack)
                        .font(.ui.headline)
                        .scaledToFit()
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    CustomMenuPopup(menuTheme: .dark, orientation: .horizontal)
                        .padding(.horizontal)
                }
                .padding(.bottom, 20)
                
                // Body
                VStack(alignment: .leading, spacing: 15) {
                    Text(captionTitle)
                        .foregroundColor(.ui.richBlack)
                        .font(.ui.title)
                        .scaledToFit()
                        .minimumScaleFactor(0.5)
                        .frame(width: SCREEN_WIDTH * 0.8, alignment: .leading)
                        .lineLimit(2)
                    
                    PlatformLimitsView()
                    
                    CaptionTextEditorView(editableCaption: $editableCaption)
                }
                .padding(.horizontal, 15)
                
                // Floating button
                CaptionCopyBtnView(platform: platform)
                
            }
            .padding()
            
        }
        .onAppear() {
            self.editableCaption = self.caption
        }
    }
}

struct EditCaptionView_Previews: PreviewProvider {
    static var previews: some View {
        EditCaptionView(bgColor: Color.ui.middleYellowRed, captionTitle: "Rescued Love Unleashed", platform: "Instagram", caption: "🐶💕 Life is so much better with a furry friend to share it with! My rescue pup brings me so much joy and love every day. 🤗")
        
        EditCaptionView(bgColor: Color.ui.middleYellowRed, captionTitle: "Rescued Love Unleashed", platform: "LinkedIn", caption: "🐶💕 Life is so much better with a furry friend to share it with! My rescue pup brings me so much joy and love every day. 🤗")
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE (3rd generation)")
    }
}

struct PlatformLimitsView: View {
    
    var body: some View {
        HStack {
            Text("100")
                .foregroundColor(.ui.richBlack)
                .font(.ui.headlineMediumSm)
            +
            Text("/2200 text")
                .foregroundColor(.ui.richBlack)
                .font(.ui.headlineLightSm)
            
            VerticalDivider()
            
            Text("0")
                .foregroundColor(.ui.richBlack)
                .font(.ui.headlineMediumSm)
            +
            Text("/30 hashtags")
                .foregroundColor(.ui.richBlack)
                .font(.ui.headlineLightSm)
        }
    }
}

struct CaptionTextEditorView: View {
    @Binding var editableCaption: String
    var body: some View {
        TextEditor(text: $editableCaption)
            .font(.ui.graphikRegular)
            .foregroundColor(Color.ui.richBlack)
            .lineSpacing(6)
            .scrollContentBackground(.hidden)
            .frame(height: SCREEN_HEIGHT * 0.6)
    }
}

struct CaptionCopyBtnView: View {
    @State var isClicked: Bool = false
    let platform: String
    
    var body: some View {
        Button {
            self.isClicked.toggle()
        } label: {
            HStack {
                if (isClicked) {
                    Image(platform)
                        .resizable()
                        .frame(width: 25, height: 25)
                } else {
                    Image(systemName: "doc.on.doc.fill")
                        .foregroundColor(.ui.cultured)
                }
                
                Text("\(isClicked ? "Open \(platform)" : "Copy")")
                    .foregroundColor(.ui.cultured)
                    .font(.ui.headline)
                
                if (isClicked) {
                    Image(systemName: "arrow.right")
                        .resizable()
                        .frame(width: 15, height: 15)
                        .foregroundColor(.ui.cultured)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 100)
                    .fill(Color.ui.richBlack)
                    .frame(height: 60)
                    .shadow(color: Color.ui.richBlack.opacity(0.4), radius: 4, x: 2, y: 4)
            )
        }
    }
}

struct VerticalDivider: View {
    let height: CGFloat = 20
    
    var body: some View {
        Rectangle()
            .fill(Color.ui.richBlack)
            .opacity(0.3)
            .frame(width: 1, height: height)
    }
}
