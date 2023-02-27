//
//  BlankCaptionsView.swift
//  CapGen
//
//  Created by Kevin Vu on 2/24/23.
//

import SwiftUI

struct BlankCaptionsView: View {
    @ScaledMetric var scaledSize: CGFloat = 1
    let title: String

    var body: some View {
        VStack(spacing: 0) {
            Image("sad_empty_robot")
                .resizable()
                .aspectRatio(contentMode: .fit)

            Text(title)
                .multilineTextAlignment(.center)
                .font(.ui.headline)
                .foregroundColor(.ui.cultured)
                .padding(.horizontal)
                .lineSpacing(8)
        }
    }
}
