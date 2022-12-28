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
    
    func platformSelect(platform: String) {
        platformSelected = platform
    }
    
    var body: some View {
        ZStack {
            Color.ui.lighterLavBlue.ignoresSafeArea()
            VStack {
                VStack {
                    Text("Which social media platform is this for?")
                        .font(.ui.graphikSemibold)
                        .foregroundColor(Color.ui.richBlack)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(alignment: .top, spacing: 20) {
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
                }
                
                Spacer()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(platformSelected: SocialMediaPlatforms.init().platforms[0])
    }
}
