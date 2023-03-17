//
//  DeleteModalView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/24/23.
//

import SwiftUI

struct DeleteModalView: View {
    let title: String
    let subTitle: String
    let lottieFile: String

    @Binding var showView: Bool
    var onDelete: () -> Void

    var body: some View {
        ZStack {
            Color.ui.cultured.ignoresSafeArea(.all)

            VStack(spacing: 20) {
                Text(title)
                    .foregroundColor(.ui.richBlack)
                    .font(.ui.largeTitleSm)

                Text(subTitle)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .foregroundColor(.ui.richBlack)
                    .font(.ui.headlineLight)
                    .frame(width: SCREEN_WIDTH * 0.85, height: 70, alignment: .center)
                    .padding(.horizontal)
                    .padding(.top, -10)

                LottieView(name: lottieFile, loopMode: .loop, isAnimating: true)
                    .frame(width: 150, height: 150)

                Button {
                    showView = false
                    Haptics.shared.play(.soft)
                } label: {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.ui.darkerPurple)
                        .frame(width: SCREEN_WIDTH / 1.4, height: 55)
                        .overlay(
                            Text("Cancel")
                                .foregroundColor(.ui.cultured)
                                .font(.ui.title2)
                        )
                }

                Button {
                    onDelete()
                    Haptics.shared.play(.soft)
                } label: {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.ui.dangerRed, lineWidth: 2)
                        .frame(width: SCREEN_WIDTH / 1.4, height: 55)
                        .overlay(
                            Text("Yes! Delete")
                                .foregroundColor(.ui.dangerRed)
                                .font(.ui.title2)
                        )
                }

                Spacer()
            }
            .padding(.top, 35)
        }
    }
}

struct DeleteModalView_Previews: PreviewProvider {
    static var previews: some View {
        DeleteModalView(title: "Deleting Captions", subTitle: "You’re about to delete these captions. This action cannot be undone. Are you sure? 🫢", lottieFile: "crane_hand_lottie", showView: .constant(true), onDelete: {})
    }
}
