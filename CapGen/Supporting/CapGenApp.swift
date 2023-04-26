//
//  CapGenApp.swift
//  CapGen
//
//  Created by Kevin Vu on 12/27/22.
//

import FBSDKCoreKit
import Firebase
import FirebaseCore
import GoogleMobileAds
import Heap
import NavigationStack
import SwiftUI

let SCREEN_WIDTH = UIScreen.main.bounds.width
let SCREEN_HEIGHT = UIScreen.main.bounds.height

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool
    {
        FirebaseApp.configure()

        // Initialize the Google Mobile Ads SDK.
        GADMobileAds.sharedInstance().start(completionHandler: nil)

        // Initialize Facebook SDK
        FBSDKCoreKit.ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )

        let heapAppId: String = Bundle.main.infoDictionary?["HEAP_APP_ID"] as! String
        // Initialize Heap for analytics
        Heap.initialize(heapAppId)

        AppodealProvider.shared.initializeSDK()

        return true
    }
}

@main
struct CapGenApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView(navigationStack: NavigationStackCompat())
                .environmentObject(AuthManager.shared)
                .environmentObject(GoogleAuthManager())
                .environmentObject(FBAuthManager())
                .environmentObject(SignInWithApple())
                .environmentObject(FirestoreManager())
                .environmentObject(UserManager())
                .environmentObject(OpenAIConnector())
                .environmentObject(NavigationStackCompat())
                .environmentObject(FolderViewModel())
                .environmentObject(GenerateByPromptViewModel())
                .environmentObject(CaptionViewModel())
                .environmentObject(AppodealProvider.shared)
                .environmentObject(SavedCaptionHomeViewModel())
                .environmentObject(SearchViewModel())
                .environmentObject(PhotoSelectionViewModel())
                .environmentObject(CameraViewModel())
                .environmentObject(TaglistViewModel())
        }
    }
}
