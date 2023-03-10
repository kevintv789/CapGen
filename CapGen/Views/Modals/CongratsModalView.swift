//
//  CongratsModalView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/15/23.
//

import NavigationStack
import SwiftUI

struct CongratsModalView: View {
    @EnvironmentObject var firestoreMan: FirestoreManager
    @Binding var showView: Bool

    let userManager = AuthManager.shared.userManager

    @ScaledMetric var scaledSize: CGFloat = 1

    var body: some View {
        ZStack(alignment: .top) {
            Color.ui.cultured
                .ignoresSafeArea(.all)

            VStack(spacing: 20) {
                Text("Congrats! 🎉")
                    .font(.ui.largeTitleSm)
                    .foregroundColor(.ui.richBlack)
                    .padding(.top, 10)

                Text("You’ve collected ")
                    .foregroundColor(.ui.richBlack)
                    .font(.ui.title3)
                    +
                    Text("1 ")
                    .foregroundColor(.ui.richBlack)
                    .font(.ui.title2)
                    +
                    Text("credit! 🤩")
                    .foregroundColor(.ui.richBlack)
                    .font(.ui.title3)

                LottieView(name: "coin_wallet_purple_lottie", loopMode: .loop, isAnimating: true)
                    .frame(width: SCREEN_WIDTH / 2 * scaledSize, height: 200 * scaledSize)
                    .padding(-60)

                DisplayAdBtnView(btnLength: .short, title: "Collect More")

                Button {
                    withAnimation {
                        showView = false
                        firestoreMan.setShowCongratsModal(for: userManager.user?.id as? String ?? nil, to: false)
                    }

                    Haptics.shared.play(.soft)
                } label: {
                    Text("Don’t show again")
                        .foregroundColor(.ui.cadetBlueCrayola)
                        .font(.ui.headline)
                }
            }
            .padding()
        }
    }
}
