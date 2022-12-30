//
//  ContentView.swift
//  CapGen
//
//  Created by Kevin Vu on 12/27/22.
//

import SwiftUI

struct SocialMediaPlatforms {
    let platforms: [String] =
    [
        "Instagram",
        "Twitter",
        "TikTok",
        "Facebook",
        "YouTube"
    ]
}

struct ContentView: View {
    let socialMediaPlatforms = SocialMediaPlatforms()
    @State var platformSelected: String
    @FocusState private var isKeyboardFocused: Bool
    @State var promptText: String = ""
    @State var isSheetPresented: Bool = true
    @State var toneSelected: String
    
    func platformSelect(platform: String) {
        platformSelected = platform
    }
    
    var body: some View {
        ZStack {
            Color.ui.lighterLavBlue.ignoresSafeArea()
            
            GeometryReader { geo in
                VStack(alignment: .leading) {
                    Text("Which social media platform is this for?")
                        .padding(.leading, 16)
                        .padding(.top, 6)
                        .font(.ui.graphikSemibold)
                        .foregroundColor(Color.ui.richBlack)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(alignment: .top, spacing: 16) {
                            ForEach(socialMediaPlatforms.platforms, id: \.self) { platform in
                                Button {
                                    platformSelect(platform: platform)
                                } label: {
                                    Pill(title: platform, isToggled: platform == platformSelected)
                                }
                            }
                        }
                        .padding()
                    }
                    .frame(height: 75)
                    
                    // Create a Text Area view that is the main place for typing input
                    TextAreaView(text: $promptText, isKeyboardFocused: $isKeyboardFocused)
                        .frame(width: geo.size.width / 1.1, height: geo.size.height / 2.2)
                        .position(x: geo.size.width / 2, y: geo.size.height / 4.5)
                    
              
                    BottomAreaView(toneSelected: $toneSelected)
                        .frame(maxHeight: geo.size.height)
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .onTapGesture {
            isKeyboardFocused = false
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(platformSelected: SocialMediaPlatforms.init().platforms[0],
                    toneSelected: tones[0].title)
    }
}
