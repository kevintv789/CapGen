//
//  LottieController.swift
//  CapGen
//
//  Created by Kevin Vu on 1/11/23.
//

// TO USE THIS View: In SwiftUI View --
// LottieView(name: <NAME_OF_JSON_FILE>, loopMode: .loop or .playOnce)

import Foundation
import Lottie
import UIKit
import SwiftUI

struct LottieView: UIViewRepresentable {
    var name: String
    var loopMode: LottieLoopMode
    let animationView = LottieAnimationView()
    
    func makeUIView(context: UIViewRepresentableContext<LottieView>) -> UIView {
        let view = UIView(frame: .zero)
        
        // Creates an animationView using Lottie library, assigns animation to animationView
        // Set the content mode to scaleAspectFit  to maintain aspect ratio while fitting the view
        // sets the loopMode of animationView to the passed loopMode, it can be loop or playOnce
        // And plays the animation on animationView
        let animation = LottieAnimation.named(name)
        animationView.animation = animation
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = loopMode
        animationView.play()
        
        // add constraints so it takes the full width and height of the container.
        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<LottieView>) {
    }
}
