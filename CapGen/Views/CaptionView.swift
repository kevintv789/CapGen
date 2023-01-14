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
    @State var captionSelected: String = ""
    @State var cardColorFill: [Color] = [.ui.middleYellowRed, .ui.darkSalmon, .ui.frenchBlueSky, .ui.lightCyan, .ui.middleBluePurple]
    
    let promptText: String
    
    @State var initialText: String = ""
    let finalText: String = "Tap a card to copy 😏"
    @State private var isTextCopied: Bool = false
    
    var body: some View {
        ZStack(alignment: .leading) {
            Color.ui.lighterLavBlue.ignoresSafeArea()
            
            VStack(alignment: .leading) {
                BackArrowView {
                    backBtnClicked.toggle()
                }
                .padding(.leading, 8)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text("Your results")
                                .font(.ui.graphikSemiboldLarge)
                                .foregroundColor(.ui.richBlack)
                            
                            Spacer()
                            
                            if (!isTextCopied) {
                                RoundedRectangle(cornerRadius: 100)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4], dashPhase: 0))
                                    .foregroundColor(Color.ui.richBlack)
                                    .overlay(
                                        AnimatedTextView(initialText: $initialText, finalText: self.finalText, isRepeat: true, timeInterval: 5, typingSpeed: 0.05)
                                            .font(.ui.graphikMedium)
                                            .foregroundColor(.ui.richBlack)
                                            .frame(width: 1000, alignment: .center)
                                    )
                                    .frame(width: 220)
                            }
                        }
                        
                        Spacer()
                            .frame(height: 20)
                        
                        
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
                captionsParsed = stringArray.filter({ ele in
                    return ele != "" && ele != "\n" && ele != "\n\n"
                })
            }
        }
    }
}

struct CaptionView_Previews: PreviewProvider {
    static var previews: some View {
        CaptionView(captionStr: .constant(" \n\n1. 🐶My rescue pup brings so much joy and love into my life! 💕 Playing in the park is one of our favorite things to do together. 🤗\n2. 🐶Rescue dogs are the best! 💗 My pup and I are having a blast playing in the park and celebrating all the love and happiness that pets bring into our lives. 🤗\n3. 🐶I'm so thankful for my rescue pup! 💗 Playing in the park together is our favorite way to celebrate the joy and love that pets bring into our lives. 🤗\n4. 🐶My rescue pup is always making me smile! 💕 Playing in the park is one of our favorite things to do together and reminds me of all the love and happiness that pets bring into our lives. 🤗\n5. 🐶Rescue pups are the best! 💗 Having a blast playing in the park with my pup and celebrating all the love and happiness that pets bring into our lives. 🤗"), promptText: "")
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
