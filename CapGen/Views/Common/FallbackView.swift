//
//  FallbackView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/28/23.
//

import SwiftUI

struct FallbackView: View {
    let lottieFileName: String
    let title: String
    let message: String
    let onClick: () -> Void

    var body: some View {
        ZStack {
            Color.ui.cultured.ignoresSafeArea(.all)

            VStack {
                LottieView(name: lottieFileName, loopMode: .loop, isAnimating: true)
                    .frame(width: SCREEN_WIDTH, height: SCREEN_HEIGHT / 2)

                Text(title)
                    .font(.ui.title)
                    .foregroundColor(.ui.richBlack)

                Text(message)
                    .font(.ui.headlineRegular)
                    .multilineTextAlignment(.center)
                    .lineSpacing(10)
                    .padding()
                    .foregroundColor(.ui.richBlack)

                Button {
                    onClick()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.ui.darkerPurple)
                            .frame(width: SCREEN_WIDTH / 1.2, height: 57)

                        Text("Go Back")
                            .font(.ui.headline)
                            .foregroundColor(.ui.cultured)
                    }
                }
                .padding(.top, 10)

                Spacer()
            }
        }
    }
}

struct FallbackView_Previews: PreviewProvider {
    static var previews: some View {
        FallbackView(lottieFileName: "general_error_robot", title: "Uh oh!", message: "Something went wrong, but it's not your fault! Our team is fixing it, please try again later.", onClick: {})

        FallbackView(lottieFileName: "general_error_robot", title: "Uh oh!", message: "Something went wrong, but it's not your fault! Our team is fixing it, please try again later.", onClick: {})
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE (3rd generation)")
    }
}
