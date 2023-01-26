//
//  EditCaptionView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/25/23.
//

import SwiftUI
import Combine

struct EditCaptionView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    // Requirements
    let bgColor: Color
    let captionTitle: String
    let platform: String
    let caption: String
    @State var editableCaption: String = ""
    
    // Platform limits and standards
    @State var textCount: Int = 0
    @State var hashtagCount: Int = 0
    @State var textLimit: Int = 0
    @State var hashtagLimit: Int = 0
    
    // Extra settings
    @State var keyboardHeight: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            bgColor.ignoresSafeArea(.all)
            
            GeometryReader { geo in
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
                        
                        PlatformLimitsView(textCount: $textCount, hashtagCount: $hashtagCount, textLimit: textLimit, hashtagLimit: hashtagLimit)
                        
                        CaptionTextEditorView(editableCaption: $editableCaption, keyboardHeight: $keyboardHeight)
                            .padding(.horizontal, -2)
                    }
                    .padding(.horizontal, 15)
                }
                .padding()
            }
            .ignoresSafeArea(.keyboard, edges: .all)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                CaptionCopyBtnView(platform: platform)

                Spacer()
                Button("Done") {
                    hideKeyboard()
                }
            }
        }
        .onAppear() {
            self.editableCaption = self.caption
            
            let socialMediaFiltered = socialMediaPlatforms.first(where: { $0.title == self.platform })
            self.textLimit = socialMediaFiltered?.characterLimit ?? 0
            self.hashtagLimit = socialMediaFiltered?.hashtagLimit ?? 0
        }
        .onChange(of: editableCaption) { value in
            // Count number of chars in the text
            self.textCount = value.count
        }
        .onReceive(Publishers.keyboardHeight) { keyboardHeight in
            withAnimation(.spring()) {
                self.keyboardHeight = keyboardHeight
            }
        }
    }
}

struct EditCaptionView_Previews: PreviewProvider {
    static var previews: some View {
        EditCaptionView(bgColor: Color.ui.middleYellowRed, captionTitle: "Rescued Love Unleashed", platform: "Instagram", caption: "Life is so much better with a furry friend to share it with! My rescue pup brings me so much joy and love every day. 🤗")
        
        EditCaptionView(bgColor: Color.ui.middleYellowRed, captionTitle: "Rescued Love Unleashed", platform: "LinkedIn", caption: "🐶💕 Life is so much better with a furry friend to share it with! My rescue pup brings me so much joy and love every day. 🤗")
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE (3rd generation)")
    }
}

struct PlatformLimitsView: View {
    @Binding var textCount: Int
    @Binding var hashtagCount: Int
    let textLimit: Int
    let hashtagLimit: Int
    
    var body: some View {
        HStack {
            Text("\(textCount)")
                .foregroundColor(.ui.richBlack)
                .font(.ui.headlineMediumSm)
            +
            Text("\(textLimit > 0 ? "/\(textLimit)" : "") text")
                .foregroundColor(.ui.richBlack)
                .font(.ui.headlineLightSm)
            
            VerticalDivider()
            
            Text("\(hashtagCount)")
                .foregroundColor(.ui.richBlack)
                .font(.ui.headlineMediumSm)
            +
            
            Text("\(hashtagLimit > 0 ? "/\(hashtagLimit)" : "") hashtags")
                .foregroundColor(.ui.richBlack)
                .font(.ui.headlineLightSm)
        }
    }
}

struct CaptionTextEditorView: View {
    @Binding var editableCaption: String
    @Binding var keyboardHeight: CGFloat
    
    var body: some View {
        TextEditor(text: $editableCaption)
            .removePredictiveSuggestions()
            .font(.ui.graphikRegular)
            .foregroundColor(Color.ui.richBlack)
            .lineSpacing(6)
            .scrollContentBackground(.hidden)
            .frame(height: SCREEN_HEIGHT * 0.6 - (keyboardHeight > 0 ? abs(-keyboardHeight + 120) : 0))
            .gesture(DragGesture().onChanged({ _ in
                hideKeyboard()
            }))
            
    }
}

struct CaptionCopyBtnView: View {
    @State var isClicked: Bool = false
    let platform: String
    
    var body: some View {
        Button {
            withAnimation {
                self.isClicked.toggle()
            }
        } label: {
            HStack {
                if (isClicked) {
                    Image(platform)
                        .resizable()
                        .frame(width: 25, height: 25)
                } else {
                    Image(systemName: "doc.on.doc.fill")
                        .foregroundColor(Color.primary)
                }
                
                Text("\(isClicked ? "Open \(platform)" : "Copy")")
                    .foregroundColor(Color.primary)
                    .font(.ui.headline)
                
                if (isClicked) {
                    Image(systemName: "arrow.right")
                        .resizable()
                        .frame(width: 15, height: 15)
                        .foregroundColor(Color.primary)
                }
            }
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
