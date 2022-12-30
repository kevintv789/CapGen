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
    
    func platformSelect(platform: String) {
        platformSelected = platform
    }
    
    var body: some View {
        ZStack {
            Color.ui.lighterLavBlue.ignoresSafeArea()
            
            GeometryReader { geo in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack {
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
                                .frame(width: geo.size.width / 1.15, height: geo.size.height / 1.6)
                                .position(x: geo.size.width / 2, y: geo.size.height / 3.1)
                        }
                    }
                }
                .frame(height: geo.size.height)
            }
            
        }
        .onTapGesture {
            isKeyboardFocused = false
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(platformSelected: SocialMediaPlatforms.init().platforms[0])
    }
}
