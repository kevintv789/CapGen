//
//  BlankCaptionsView.swift
//  CapGen
//
//  Created by Kevin Vu on 2/24/23.
//

import SwiftUI

enum ImageSize {
    case small, regular
}

struct BlankCaptionsView: View {
    @ScaledMetric var scaledSize: CGFloat = 1
    let title: String
    var imageSize: ImageSize = .small

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Image("sad_empty_robot")
                .resizable()
                .if(imageSize == .regular) { image in
                    image.aspectRatio(contentMode: .fit)
                }
                .if(imageSize == .small) { image in
                    image
                        .frame(width: 200, height: 200)
                        .padding(.bottom, -20)
                        .padding(.top, -30)
                }

            Text(title)
                .multilineTextAlignment(.center)
                .font(imageSize == .regular ? .ui.headline : .ui.headlineMd)
                .foregroundColor(.ui.cultured)
                .padding(.horizontal)
                .lineSpacing(8)
        }
    }
}
