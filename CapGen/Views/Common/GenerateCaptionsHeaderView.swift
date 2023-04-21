//
//  GenerateCaptionsHeaderView.swift
//  CapGen
//
//  Created by Kevin Vu on 4/14/23.
//

import SwiftUI

struct GenerateCaptionsHeaderView: View {
    @ScaledMetric var scaledSize: CGFloat = 1
    let title: String
    var isOptional: Bool? = false
    var isNextSubmit: Bool? = false
    let nextAction: (() -> Void)?

    var body: some View {
        // Header
        HStack {
            BackArrowView()

            Spacer()

            VStack(alignment: .center, spacing: 5) {
                Text(title)
                    .foregroundColor(.ui.richBlack.opacity(0.5))
                    .font(.ui.title4)
                    .fixedSize(horizontal: true, vertical: false)

                if isOptional ?? false {
                    Text("Optional")
                        .font(.ui.subheadlineLarge)
                        .foregroundColor(.ui.richBlack.opacity(0.5))
                }
            }
            .padding(.top, isOptional ?? false ? 15 : 0)
            .if(nextAction == nil) { View in
                // offset the width of the next button to center align the title
                View.padding(.trailing, 40)
            }

            Spacer()

            // next/submit button
            if let nextAction = nextAction {
                Button {
                    nextAction()
                } label: {
                    Image(isNextSubmit ?? false ? "play-button" : "next")
                        .resizable()
                        .frame(width: 40, height: 40)
                }
            }
        }
        .padding(.bottom, 20)
        .padding(.horizontal)
    }
}
