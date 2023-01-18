//
//  GoogleAdsManager.swift
//  CapGen
//
//  Created by Kevin Vu on 1/14/23.
//

import Foundation
import GoogleMobileAds
import UIKit
import SwiftUI

final class GoogleRewardedAds: ObservableObject {
    private let adUnitId: String = Bundle.main.infoDictionary?["ADMOB_REWARDED_AD_UNIT_ID"] as! String
    @Published var rewardedAd: GADRewardedAd?
    
    init() {
        loadAd() { _ in }
    }
    
    func loadAd(completion: @escaping (Bool) -> Void) {
        let request = GADRequest()
        // add extras here to the request, for example, for not presonalized Ads
        GADRewardedAd.load(withAdUnitID: adUnitId, request: request, completionHandler: {rewardedAd, error in
            if error != nil {
                // loading the rewarded Ad failed :(
                print("Failed to load rewarded ad", error!.localizedDescription)
                completion(false)
                return
            }
            self.rewardedAd = rewardedAd
            completion(true)
        })
    }
    
    func showAd(rewardFunction: @escaping () -> Void) -> Bool {
        guard let rewardedAd = self.rewardedAd else {
            print("Reward ad is nil")
            return false
        }
        
        guard let root = UIApplication.shared.keyWindowPresentedController else {
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
            .flatMap({ $0 as? UIWindowScene })?.windows
            .first(where: \.isKeyWindow)
    }
    
    var keyWindowPresentedController: UIViewController? {
        var viewController = self.customKeyWindow?.rootViewController
        
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
