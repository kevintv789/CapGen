//
//  ContentView.swift
//  CapGen
//
//  Created by Kevin Vu on 12/27/22.
//

import SwiftUI
import Firebase
import FirebaseAuth

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
    @State var isLoggedIn: Bool = false
    
    var body: some View {
        NavigationStack {
            if (isLoggedIn) {
                HomeView(platformSelected: SocialMediaPlatforms.init().platforms[0])
            } else {
                LaunchView()
            }
        }
        .onAppear {
            Auth.auth().addStateDidChangeListener { (auth, user) in
                withAnimation {
                    if user != nil {
                        // User is signed in
                        self.isLoggedIn = true
                    } else {
                        self.isLoggedIn = false // CHANGE VALUE BACK TO FALSE
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDevice("iPhone 14 Pro Max")
            .previewDisplayName("iPhone 14 Pro Max")
        
        ContentView()
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE (3rd generation)")
    }
}
