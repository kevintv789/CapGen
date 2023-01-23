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
        "YouTube",
        "Reddit",
        "Pinterest",
        "LinkedIn"
    ]
}

struct ContentView: View {
    @EnvironmentObject var rewardedAd: GoogleRewardedAds
    @ObservedObject var authManager: AuthManager
    @EnvironmentObject var firestoreManager: FirestoreManager
    
    var body: some View {
        NavigationStack {
            if (authManager.isSignedIn ?? false) {
                HomeView(promptText: "", platformSelected: SocialMediaPlatforms.init().platforms[0])
            } else {
                LaunchView()
            }
        }
        .onAppear {
            firestoreManager.fetchKey()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(authManager: AuthManager.shared)
            .previewDevice("iPhone 14 Pro Max")
            .previewDisplayName("iPhone 14 Pro Max")
        
        ContentView(authManager: AuthManager.shared)
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE (3rd generation)")
    }
}
