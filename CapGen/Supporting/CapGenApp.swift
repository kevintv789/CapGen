//
//  CapGenApp.swift
//  CapGen
//
//  Created by Kevin Vu on 12/27/22.
//

import SwiftUI
import FirebaseCore
import Firebase
import GoogleMobileAds

let SCREEN_WIDTH = UIScreen.main.bounds.width
let SCREEN_HEIGHT = UIScreen.main.bounds.height

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Initialize the Google Mobile Ads SDK.
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        
        return true
    }
}

@main
struct CapGenApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView(authManager: AuthManager.shared)
                .environmentObject(AuthManager.shared)
                .environmentObject(GoogleAuthManager())
                .environmentObject(GoogleRewardedAds())
                .environmentObject(FBAuthManager())
                .environmentObject(SignInWithApple())
                .environmentObject(FirestoreManager())
                .environmentObject(UserManager())
        }
    }
}
