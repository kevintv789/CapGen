//
//  GoogleAdsManager.swift
//  CapGen
//
//  Created by Kevin Vu on 1/14/23.
//

import Foundation
import GoogleMobileAds
import SwiftUI
import UIKit

final class GoogleRewardedAds: ObservableObject {
    @Published var rewardedAd: GADRewardedAd?
    @Published var appError: ErrorType?

    init() {
        loadAd(adUnitId: nil) { _ in }
    }

    func loadAd(adUnitId: String?, completion: @escaping (Bool) -> Void) {
        guard let adUnitId = adUnitId else { return }

        let request = GADRequest()
        // add extras here to the request, for example, for not presonalized Ads
        GADRewardedAd.load(withAdUnitID: adUnitId, request: request, completionHandler: { rewardedAd, error in
            if error != nil {
                // loading the rewarded Ad failed :(
                self.appError = ErrorType(error: .genericError)
                print("Failed to load rewarded ad", error!.localizedDescription)
                completion(false)
                return
            }
            self.rewardedAd = rewardedAd
            completion(true)
        })
    }

    func showAd(rewardFunction: @escaping () -> Void) -> Bool {
        guard let rewardedAd = rewardedAd else {
            appError = ErrorType(error: .genericError)
            print("Reward ad is nil")
            return false
        }

        guard let root = UIApplication.shared.keyWindowPresentedController else {
            appError = ErrorType(error: .genericError)
            return false
        }

        rewardedAd.present(fromRootViewController: root, userDidEarnRewardHandler: rewardFunction)
        return true
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
