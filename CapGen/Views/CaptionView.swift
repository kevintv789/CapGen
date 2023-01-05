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
    
    var body: some View {
        ZStack(alignment: .leading) {
            Color.ui.lighterLavBlue.ignoresSafeArea()
            
            VStack(alignment: .leading) {
                Button {
                    backBtnClicked.toggle()
                } label: {
                    Image("back_arrow")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .padding(-30)
                        .padding(.leading, 15)
                }
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading) {
                        Text("Your results")
                            .font(.ui.graphikSemiboldLarge)
                            .foregroundColor(.ui.richBlack)
                        
                        Spacer()
                        
                        ForEach(captionsParsed, id: \.self) {caption in
                            CaptionCard(caption: caption)
                                .padding(10)
                        }
                        
                    }
                    .padding()
                }
            }
            
            
        }
        .navigationDestination(isPresented: $backBtnClicked) {
            ContentView(platformSelected: SocialMediaPlatforms.init().platforms[0],
                        toneSelected: tones[0].title)
            .navigationBarBackButtonHidden(true)
        }
        .onAppear() {
            captionsParsed = captionStr?
                .components(separatedBy: "\n")
                .filter { element in
                    return !element.isEmpty
                } ?? []
            
        }
    }
}

//struct CaptionView_Previews: PreviewProvider {
//    static var previews: some View {
//        CaptionView(captionStr: "\n\n1. 🐶My rescue pup brings so much joy and love into my life! 💕 Playing in the park is one of our favorite things to do together. 🤗\n2. 🐶Rescue dogs are the best! 💗 My pup and I are having a blast playing in the park and celebrating all the love and happiness that pets bring into our lives. 🤗\n3. 🐶I'm so thankful for my rescue pup! 💗 Playing in the park together is our favorite way to celebrate the joy and love that pets bring into our lives. 🤗\n4. 🐶My rescue pup is always making me smile! 💕 Playing in the park is one of our favorite things to do together and reminds me of all the love and happiness that pets bring into our lives. 🤗\n5. 🐶Rescue pups are the best! 💗 Having a blast playing in the park with my pup and celebrating all the love and happiness that pets bring into our lives. 🤗")
//    }
//}

struct CaptionCard: View {
    var caption: String
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.black, lineWidth: 3)
                .frame(height: 150)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.ui.lightOldPaper)
                )
                .overlay(
                    VStack(alignment: .leading) {
                        Text(caption.dropFirst(3))
                            .padding(10)
                            .padding(.top, 5)
                            .font(.ui.graphikRegular)
                            .lineSpacing(4)
                            .foregroundColor(.ui.richBlack)
                        
                        Spacer()
                    }
                    
                )
        }
    }
}
