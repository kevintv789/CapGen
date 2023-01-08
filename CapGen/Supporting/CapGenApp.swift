//
//  CapGenApp.swift
//  CapGen
//
//  Created by Kevin Vu on 12/27/22.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}

@main
struct CapGenApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var firestoreManager = FirestoreManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView(platformSelected: SocialMediaPlatforms.init().platforms[0])
        }
    }
}
