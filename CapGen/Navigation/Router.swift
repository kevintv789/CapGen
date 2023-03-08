//
//  Router.swift
//  CapGen
//
//  Created by Kevin Vu on 1/29/23.
//

import Foundation
import NavigationStack
import SwiftUI

let HOME_SCREEN = "homeScreen"

class Router {
    private let navStack: NavigationStackCompat

    init(navStack: NavigationStackCompat, isLoggedIn: Bool) {
        self.navStack = navStack

        if isLoggedIn {
            // Do this check so that HomeView doesn't get instantiated twice with the same ID
            if !doesHaveId(with: HOME_SCREEN) {
                toHomeView()
            } else {
                self.navStack.pop(to: .view(withId: HOME_SCREEN))
            }
        } else {
            toLaunchView()
        }
    }

    init(navStack: NavigationStackCompat) {
        self.navStack = navStack
    }

    func doesHaveId(with id: String) -> Bool {
        return navStack.containsView(withId: id)
    }

    func toHomeView() {
        navStack.push(HomeView(), withId: HOME_SCREEN)
    }

    func toLaunchView() {
        navStack.push(LaunchView())
    }

    func toLoadingView() {
        navStack.push(LoadingView())
    }

    func toEditCaptionView(platform: String) {
        navStack.push(EditCaptionView(platform: platform))
    }

    func toCapacityFallbackView() {
        navStack.push(FallbackView(lottieFileName: "capacity_error_robot", title: "We’re over capacity", message: "We apologize, we're currently at over capacity. Our team is working hard to generate captions for everyone. Please try again later.", onClick: { self.navStack.pop(to: .view(withId: HOME_SCREEN)) }))
    }

    func toGenericFallbackView() {
        navStack.push(FallbackView(lottieFileName: "general_error_robot", title: "Uh oh!", message: "Something went wrong, but it's not your fault! Our team is fixing it, please try again later.", onClick: { self.navStack.pop(to: .view(withId: HOME_SCREEN)) }))
    }

    func toLoginFallbackView() {
        navStack.push(FallbackView(lottieFileName: "general_error_robot", title: "Oops!", message: "Something went wrong while logging in. Don't worry, we're on it. Please try again later.", onClick: { self.navStack.pop(to: .previous) }))
    }
}
