//
//  CaptionView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/2/23.
//

import SwiftUI

struct CaptionView: View {
    @State var backBtnClicked: Bool = false
    @Binding var captionStr: String?
    @State var captionsParsed: [String] = []
    @State var captionsTitle: String = ""
    @State var captionSelected: String = ""
    @State var cardColorFill: [Color] = [.ui.middleYellowRed, .ui.darkSalmon, .ui.frenchBlueSky, .ui.lightCyan, .ui.middleBluePurple]
    
    let promptText: String
    
    @State var initialText: String = ""
    let finalText: String = "Tap a card to copy 😏"
    @State private var isTextCopied: Bool = false
    @State var saveError: Bool = false
    
    func saveCaptions() {
        // Don't do anything if there's an error
        guard !self.saveError else { return }
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            Color.ui.cultured.ignoresSafeArea()
            Color.ui.lighterLavBlue.ignoresSafeArea().opacity(0.5)
            
            
            VStack(alignment: .leading) {
                BackArrowView {
                    backBtnClicked = true
                }
                .padding(.leading, 8)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 5) {
                        
                        EditableTitleView(title: $captionsTitle, isError: $saveError)
                            .padding(.bottom, 15)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            if (!isTextCopied) {
                                RoundedRectangle(cornerRadius: 100)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4], dashPhase: 0))
                                    .foregroundColor(Color.ui.richBlack)
                                    .overlay(
                                        AnimatedTextView(initialText: $initialText, finalText: self.finalText, isRepeat: true, timeInterval: 5, typingSpeed: 0.05)
                                            .font(.ui.graphikMedium)
                                            .foregroundColor(.ui.richBlack)
                                            .frame(width: SCREEN_WIDTH, alignment: .center)
                                    )
                                    .frame(width: 220, height: 40)
                            }
                            Spacer()
                            
                            
                            ForEach(Array(captionsParsed.enumerated()), id: \.element) { index, caption in
                                Button {
                                    withAnimation {
                                        self.captionSelected = caption
                                        self.isTextCopied = true
                                        UIPasteboard.general.string = String(caption)
                                    }
                                } label: {
                                    CaptionCard(caption: caption, isCaptionSelected: caption == captionSelected, colorFilled: $cardColorFill[index])
                                        .padding(10)
                                    
                                }
                            }
                            
                            
                        }
                        
                        Spacer()
                        
                        SubmitButtonGroupView(onSaveClick: {
                            saveCaptions()
                        }, onResetClick: {
                            
                        })
                            .padding(.top, 15)
                        
                    }
                    .padding()
                }
            }
            
            
        }
        .navigationDestination(isPresented: $backBtnClicked) {
            HomeView(platformSelected: SocialMediaPlatforms.init().platforms[0], promptText: promptText)
                .navigationBarBackButtonHidden(true)
        }
        .onAppear() {
            if var originalString = captionStr {
                if originalString[0] == " " {
                    originalString = String(captionStr!.dropFirst())
                }
                
                let uniqueStr = UUID().uuidString
                
                let regex = try! NSRegularExpression(pattern: "(?m)^\\n\\d\\.|\\n\\d\\.", options: [])
                let modifiedString = regex.stringByReplacingMatches(in: originalString, options: [], range: NSRange(location: 0, length: originalString.utf16.count), withTemplate: uniqueStr)
                let stringArray = modifiedString.components(separatedBy: uniqueStr)
                var parsedArray = stringArray.filter({ ele in
                    return ele != "" && ele != "\n" && ele != "\n\n"
                })
                
                self.captionsTitle = parsedArray.removeLast()
                self.captionsParsed = parsedArray
            }
        }
    }
}

struct CaptionView_Previews: PreviewProvider {
    static var previews: some View {
        CaptionView(captionStr: .constant("\n\n1. Look at those two crazy pups playing on a rainbow road! 🌈 \n2. My two doggos are having the time of their lives on the rainbow road - I wish I could join them! 🐶\n3. Nothing cuter than seeing two doggies playing in a rainbow 🌈 \n4. My two furry friends enjoying the beautiful rainbow road 🤗 \n5. The best part of my day? Watching my two pups have a blast on the rainbow road 🤩 \n6. 🌈"), promptText: "")
        
        CaptionView(captionStr: .constant("\n\n1. Look at those two crazy pups playing on a rainbow road! 🌈 \n2. My two doggos are having the time of their lives on the rainbow road - I wish I could join them! 🐶\n3. Nothing cuter than seeing two doggies playing in a rainbow 🌈 \n4. My two furry friends enjoying the beautiful rainbow road 🤗 \n5. The best part of my day? Watching my two pups have a blast on the rainbow road 🤩 \n6. Two Pups, One Rainbow Roadddddd! 🌈"), promptText: "")
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE (3rd generation)")
    }
}

struct EditableTitleView: View {
    @Binding var title: String
    @Binding var isError: Bool
    
    @State var isEditing: Bool = false
    
    var body: some View {
        HStack {
            if (!isEditing && !isError) {
                Text("\(title)")
                    .font(.ui.title)
                    .foregroundColor(.ui.richBlack)
                    .scaledToFit()
                    .minimumScaleFactor(0.5)
                    .frame(width: SCREEN_WIDTH * 0.8, alignment: .leading)
                    .lineLimit(1)
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1))
                    .foregroundColor(isError ? Color.red : Color.ui.shadowGray)
                    .overlay(
                        TextField("", text: $title)
                            .font(.ui.title)
                            .foregroundColor(.ui.shadowGray)
                            .minimumScaleFactor(0.5)
                            .frame(width: SCREEN_WIDTH * 0.8, alignment: .leading)
                            .lineLimit(1)
                            .onChange(of: title, perform: { title in
                                if (title.isEmpty || title == " ") {
                                    isError = true
                                } else {
                                    isError = false
                                }
                            })
                    )
                    .frame(height: 45)
            }
            
            Spacer()
            
            Button {
                isEditing.toggle()
            } label: {
                Image(systemName: "pencil")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.ui.richBlack)
            }
            
        }
        
    }
}

struct CaptionCard: View {
    var caption: String
    var isCaptionSelected: Bool
    @State private var phase = 0.0
    @Binding var colorFilled: Color
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.black, lineWidth: isCaptionSelected ? 2 : 0)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(colorFilled)
                )
                .shadow(radius: isCaptionSelected ? 0 : 3)
            
            VStack(alignment: .trailing, spacing: 0) {
                Text(caption.dropFirst())
                    .padding(EdgeInsets.init(top: 15, leading: 10, bottom: 15, trailing: 10))
                    .font(.ui.graphikRegular)
                    .lineSpacing(4)
                    .foregroundColor(.ui.richBlack)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if (isCaptionSelected) {
                    Text("Copied!")
                        .foregroundColor(Color.ui.richBlack)
                        .font(.ui.graphikMediumMed)
                        .padding(EdgeInsets.init(top: 10, leading: 10, bottom: 10, trailing: 10))
                        .frame(height: 30)
                        .overlay(
                            RoundedRectangle(cornerRadius: 100)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4], dashPhase: phase))
                                .foregroundColor(Color.ui.richBlack)
                                .onAppear {
                                    withAnimation(.linear.repeatForever(autoreverses: false).speed(0.1)) {
                                        phase += 20
                                    }
                                }
                            
                        )
                        .padding(EdgeInsets.init(top: 10, leading: 10, bottom: 10, trailing: 12))
                }
            }
        }
    }
}

struct SubmitButtonGroupView: View {
    var onSaveClick: () -> Void
    var onResetClick: () -> Void
    
    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Button {
                self.onSaveClick()
            } label: {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.ui.frenchBlueSky)
                    .frame(width: SCREEN_WIDTH * 0.85, height: 55)
                    .overlay(
                        Text("Save")
                            .foregroundColor(.ui.cultured)
                            .font(.ui.title2)
                    )
                
            }
            
            Button {
                self.onResetClick()
            } label: {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.ui.frenchBlueSky)
                    .opacity(0.5)
                    .frame(width: SCREEN_WIDTH * 0.85, height: 55)
                    .overlay(
                        Text("Reset")
                            .foregroundColor(Color.blue)
                            .font(.ui.title2)
                    )
                
            }
        }
    }
}
