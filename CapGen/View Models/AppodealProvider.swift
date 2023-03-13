//
//  AppodealProvider.swift
//  CapGen
//
//  Created by Kevin Vu on 3/2/23.
//

import Appodeal
import Combine
import Foundation
import SwiftUI

class AppodealProvider: NSObject, ObservableObject {
    @Published var firestoreMan: FirestoreManager = .init()
    @Published var appError: ErrorType?
    @Published var isAdInitialised = false
    @Published var isRewardedReady = false
    @Published var isRewardedVideoFinished = false

    let appId: String = Bundle.main.infoDictionary?["APPODEAL_APP_ID"] as! String
    let testMode: Bool = Bundle.main.infoDictionary?["ENV"] as! String == "dev"

    // MARK: Types and definitions

    private typealias SynchroniseConsentCompletion = () -> Void

    /// Constants
    private enum AppodealConstants {
        static let adTypes: AppodealAdType = [.rewardedVideo]
        static let logLevel: APDLogLevel = .debug
        static let placement: String = "default"
    }

    static let shared: AppodealProvider = .init()

    // MARK: Public methods

    func initializeSDK() {
        // Custom settings
        Appodeal.setLogLevel(AppodealConstants.logLevel)

        // Test Mode
        Appodeal.setTestingEnabled(testMode)

        // User Data
        Appodeal.setUserId("216987")

        // Set delegates
        Appodeal.setRewardedVideoDelegate(self)

        // Initialize SDK
        Appodeal.initialize(withApiKey: appId, types: AppodealConstants.adTypes)
    }

    func presentRewarded() {
        defer { isRewardedReady = false }
        isRewardedVideoFinished = false

        // Check availability of rewarded video
        guard
            Appodeal.canShow(.rewardedVideo, forPlacement: AppodealConstants.placement),
            let viewController = UIApplication.shared.keyWindowPresentedController
        else {
            DispatchQueue.main.async {
                print("Unable to show rewarded ad")
                self.appError = ErrorType(error: .genericError)
            }

            return
        }

        Appodeal.showAd(.rewardedVideo, forPlacement: AppodealConstants.placement, rootViewController: viewController)
    }
}

extension AppodealProvider: AppodealRewardedVideoDelegate {
    func rewardedVideoDidLoadAdIsPrecache(_: Bool) {
        isRewardedReady = true
    }

    func rewardedVideoDidFailToLoadAd() {
        isRewardedVideoFinished = false
        isRewardedReady = false
        appError = ErrorType(error: .genericError)
    }

    // Method called if rewarded mediation was successful, but ready ad network can't show ad or
    // ad presentation was too frequent according to your placement settings
    //
    // - Parameter error: Error object that indicates error reason
    func rewardedVideoDidFailToPresentWithError(_ error: Error) {
        isRewardedVideoFinished = false
        print("Appodeal failed to show ad", error)
        appError = ErrorType(error: .genericError)
    }

    // Method called after rewarded video start displaying
    func rewardedVideoDidPresent() {
        isRewardedVideoFinished = false
    }

    //  Method called after fully watch of video
    //
    // - Warning: After call this method rewarded video can stay on screen and show postbanner
    // - Parameters:
    //   - rewardAmount: Amount of app curency tuned via Appodeal Dashboard
    //   - rewardName: Name of app currency tuned via Appodeal Dashboard
    func rewardedVideoDidFinish(_: Float, name _: String?) {
        firestoreMan.incrementCredit(for: AuthManager.shared.userManager.user?.id as? String ?? nil)
        isRewardedVideoFinished = true
    }
}

extension AppodealProvider: AppodealInitializationDelegate {
    func appodealSDKDidInitialize() {
        // here you can do any additional actions
        isAdInitialised = true
    }
}

// just an extension to make our life easier to receive the root view controller
extension UIApplication {
    var customKeyWindow: UIWindow? {
        return UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .first(where: { $0 is UIWindowScene })
            .flatMap { $0 as? UIWindowScene }?.windows
            .first(where: \.isKeyWindow)
    }

    var keyWindowPresentedController: UIViewController? {
        var viewController = customKeyWindow?.rootViewController

        if let presentedController = viewController as? UITabBarController {
            viewController = presentedController.selectedViewController
        }

        while let presentedController = viewController?.presentedViewController {
            if let presentedController = presentedController as? UITabBarController {
                viewController = presentedController.selectedViewController
            } else {
                viewController = presentedController
            }
        }
        return viewController
    }
}
