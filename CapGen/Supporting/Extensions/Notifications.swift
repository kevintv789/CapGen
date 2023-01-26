//
//  Notifications.swift
//  CapGen
//
//  Created by Kevin Vu on 1/25/23.
//

import Foundation
import UIKit
import Combine

extension Notification {
    var keyboardHeight: CGFloat {
        return (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
    }
}

extension Publishers {
    // 1. Declare a keyboard height publisher in the Publishers namespace. The publisher has two types – CGFloat and Never – which means that it emits values of type CGFloat and can never fail with an error.
    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
        // 2. Wrap the willShow and willHide notifications into publishers. Whenever the notification center broadcasts a willShow or willHide notification, the corresponding publisher will also emit the notification as its value. We also use the map operator since we are only interested in keyboard height.
        let willShow = NotificationCenter.default.publisher(for: UIApplication.keyboardWillShowNotification)
            .map { $0.keyboardHeight }
        
        let willHide = NotificationCenter.default.publisher(for: UIApplication.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }
        
        // 3. Combine multiple publishers into one by merging their emitted values.
        return MergeMany(willShow, willHide)
            .eraseToAnyPublisher()
    }
}
