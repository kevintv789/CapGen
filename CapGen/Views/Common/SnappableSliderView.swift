//
//  SnappableSliderView.swift
//  CapGen
//
//  Created by Kevin Vu on 12/31/22.
//

import Foundation
import SwiftUI
import UIKit

struct SnappableSliderView: UIViewRepresentable {
    @Binding var values: [Int]
    @Binding var selectedValue: Int
    var callback: (Float) -> Void

    var thumbColor: UIColor = .init(Color.ui.darkerPurple)
    var minTrackColor: UIColor = .init(Color.ui.darkerPurple)
    var maxTrackColor: UIColor = .init(Color.ui.lighterLavBlue)

    // Create a class Coordinator to bind SwiftUI and UIKit together
    // so that a SwiftUI View can access data from this UIKit component
    class Coordinator: NSObject {
        var value: Binding<[Int]>
        var lastIndex: Int?
        var callback: (Float) -> Void

        init(value: Binding<[Int]>, callback: @escaping (_ newValue: Float) -> Void) {
            self.value = value
            self.callback = callback
        }

        @objc func valueChanged(_ sender: UISlider) {
            let newIndex = Int(sender.value + 0.5) // round up to next index
            sender.setValue(Float(newIndex), animated: false) // snap to increments
            let didChange = lastIndex == nil || newIndex != lastIndex!
            if didChange {
                lastIndex = newIndex
                let actualValue = value[newIndex].wrappedValue
                value.wrappedValue[newIndex] = actualValue
                callback(Float(actualValue))
            }
        }

        @objc func handleTap(_ sender: UIGestureRecognizer) {
            let location = sender.location(in: nil)
            if let slider = sender.view as? UISlider {
                // round up to the nearest index from a maximum value
                let newIndex = Int(Float(location.x / UIScreen.main.bounds.width) * slider.maximumValue + 0.5)

                slider.setValue(Float(newIndex), animated: false)

                let didChange = lastIndex == nil || newIndex != lastIndex!
                if didChange {
                    lastIndex = newIndex
                    let actualValue = value[newIndex].wrappedValue
                    value.wrappedValue[newIndex] = actualValue
                    callback(Float(actualValue))
                }
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

        let longPress = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        longPress.minimumPressDuration = 0
        slider.addGestureRecognizer(longPress)

        return slider
    }

    func updateUIView(_ uiView: UISlider, context _: Context) {
        uiView.value = Float(selectedValue)
    }
}
