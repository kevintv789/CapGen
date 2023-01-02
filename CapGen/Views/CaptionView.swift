//
//  CaptionView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/2/23.
//

import SwiftUI

struct CaptionView: View {
    private var openAiRequest = OpenAIConnector()
    
    var body: some View {
        ZStack(alignment: .leading) {
            Color.ui.lighterLavBlue.ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading) {
                    Text("Your results")
                        .font(.ui.graphikSemiboldLarge)
                        .foregroundColor(.ui.richBlack)
                    
                    Spacer()
                    
                    ForEach(1...5, id: \.self) {_ in
                        CaptionCard()
                            .padding(10)
                    }
                  
                }
                .padding()
            }
            
        }
//        .onAppear() {
//            openAiRequest.processPrompt(prompt: "Please generate 5 captions for a photo of my dog playing in the park. She's a rescue and brings so much joy to my life. Please come up with a caption that celebrates the love and happiness that pets bring into our lives. This should have a minimum of 21 words and a max of 40 words, the word count should be excluding emojis. Use emojis. This is for an YouTube caption only.")
//        }
    }
}

struct CaptionView_Previews: PreviewProvider {
    static var previews: some View {
        CaptionView()
    }
}

struct CaptionCard: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.black, lineWidth: 3)
                .frame(height: 150)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.ui.lightOldPaper)
                )
        }
    }
}
