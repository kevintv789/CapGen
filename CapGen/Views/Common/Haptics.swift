//
//  Haptics.swift
//  CapGen
//
//  Created by Kevin Vu on 2/1/23.
//

import Foundation
import UIKit

class Haptics {
    static let shared = Haptics()
    
    private init() {}
    
    func play(_ feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: feedbackStyle).impactOccurred()
    }
    
    func notify(_ feedbackType: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(feedbackType)
    }
}
