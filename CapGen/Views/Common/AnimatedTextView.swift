//
//  AnimatedTextView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/12/23.
//

import SwiftUI

struct AnimatedTextView: View {
    @Binding var initialText: String
    var finalText: String
    var isRepeat: Bool
    var timeInterval: CGFloat
    var typingSpeed: CGFloat

    func typeWriter(at position: Int = 0) {
        if position == 0 {
            initialText = ""
        }

        if position < finalText.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + typingSpeed) {
                // get the character from finalText and append it to text
                self.initialText.append(finalText[position])
                // call this function again with the character at the next position
                typeWriter(at: position + 1)
            }
        }
    }

    var body: some View {
        Text(initialText)
            .onAppear {
                typeWriter()
                if isRepeat {
                    Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: isRepeat) { _ in
                        typeWriter()
                    }
                }
            }
    }
}
