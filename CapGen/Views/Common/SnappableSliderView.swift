//
//  SnappableSliderView.swift
//  CapGen
//
//  Created by Kevin Vu on 12/31/22.
//

import Foundation
import UIKit
import SwiftUI

struct SnappableSliderView: UIViewRepresentable {
    
    @Binding var values: [Int]
    var callback: (Float) -> Void
   
    var thumbColor: UIColor = UIColor(Color.ui.middleYellowRed)
    var minTrackColor: UIColor = UIColor(Color.ui.cadetBlueCrayola)
    var maxTrackColor: UIColor = UIColor(Color.ui.cadetBlueCrayola)
    
    // Create a class Coordinator to bind SwiftUI and UIKit together
    // so that a SwiftUI View can access data from this UIKit component
    class Coordinator: NSObject {
        var value: Binding<[Int]>
        var lastIndex: Int? = nil
        var callback: (Float) -> Void
        
        init(value: Binding<[Int]>, callback: @escaping (_ newValue: Float) -> Void) {
            self.value = value
            self.callback = callback
        }
        
        @objc func valueChanged(_ sender: UISlider) {
            let newIndex = Int(sender.value + 0.5) // round up to next index
            sender.setValue(Float(newIndex), animated: false) // snap to increments
            let didChange = self.lastIndex == nil || newIndex != self.lastIndex!
            if didChange {
                self.lastIndex = newIndex
                let actualValue = self.value[newIndex].wrappedValue
                self.value.wrappedValue[newIndex] = actualValue
                self.callback(Float(actualValue))
            }
        }
    }
    
    // Initialize coordinator
    func makeCoordinator() -> SnappableSliderView.Coordinator {
        Coordinator(value: $values, callback: callback)
    }
    
    // Render the view on screen
    func makeUIView(context: Context) -> UISlider {
        let slider = UISlider(frame: .zero)
        slider.thumbTintColor = thumbColor
        slider.minimumTrackTintColor = minTrackColor
        slider.maximumTrackTintColor = maxTrackColor
        
        let steps = values.count - 1
        slider.minimumValue = Float(0)
        slider.maximumValue = Float(Int(steps))
        
        slider.addTarget(
            context.coordinator,
            action: #selector(Coordinator.valueChanged(_:)),
            for: .valueChanged
        )
        
        return slider
    }
    
    func updateUIView(_ uiView: UISlider, context: Context) {
//        uiView.value = Float(values[0])
    }
}
