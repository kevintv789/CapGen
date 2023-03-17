//
//  CircularConfigViews.swift
//  CapGen
//
//  Created by Kevin Vu on 3/17/23.
//

import SwiftUI

enum CircularViewSize {
    case large, regular
}

struct CircularTonesView: View {
    let tones: [ToneModel]
    @State var circularViewSize: CircularViewSize = .regular

    private func calculateSize() -> CGFloat {
        if circularViewSize == .regular {
            return 35.0
        }

        return 50.0
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.ui.cultured)
                .frame(width: calculateSize(), height: calculateSize())

            // If there are 2 tones for a caption group, then group them together in one circle
            if !tones.isEmpty {
                if tones.count > 1 {
                    Text(tones[0].icon)
                        .font(circularViewSize == .regular ? .ui.headlineSm : Font.ui.headline)
                        .offset(x: -5, y: -5)

                    Text(tones[1].icon)
                        .font(circularViewSize == .regular ? .ui.headlineSm : Font.ui.headline)
                        .offset(x: 5, y: 3)
                } else {
                    Text(tones[0].icon)
                        .font(.ui.title2)
                }
            }
        }
    }
}

struct CircularView: View {
    let image: String
    @State var imageWidth: CGFloat?
    @State var circularViewSize: CircularViewSize = .regular

    private func calculateSize() -> CGFloat {
        if circularViewSize == .regular {
            return 35.0
        }

        return 50.0
    }

    var body: some View {
        // Emojis
        ZStack {
            Circle()
                .fill(Color.ui.cultured)
                .frame(width: calculateSize(), height: calculateSize())

            Image(image)
                .resizable()
                .frame(width: calculateSize() - (imageWidth != nil ? imageWidth! : 15), height: calculateSize() - 15)
        }
    }
}
