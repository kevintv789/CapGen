//
//  RewardedAdView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/14/23.
//

import SwiftUI

struct RewardedAdView: View {
    @ObservedObject var ad = AppodealProvider.shared
    @EnvironmentObject var firestoreMan: FirestoreManager
    @Binding var isViewPresented: Bool
    @Binding var showCongratsModal: Bool

    let authManager = AuthManager.shared.userManager

    @State var isAdDone: Bool = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.ui.cultured
                .ignoresSafeArea(.all)

            VStack(spacing: 20) {
                Text("Collect More Credits")
                    .foregroundColor(.ui.richBlack)
                    .font(.ui.largeTitleSm)

                Text("Watch ads, earn credits, create more captions 🎉")
                    .foregroundColor(.ui.richBlack)
                    .font(.ui.bodyLarge)
                    .lineSpacing(10)
                    .frame(width: SCREEN_WIDTH * 0.9, alignment: .center)
                    .multilineTextAlignment(.center)

                LottieView(name: "coin_pile_lottie", loopMode: .loop, isAnimating: true)
                    .position(x: SCREEN_WIDTH / 2, y: 30)
                    .frame(width: SCREEN_WIDTH, height: 250)
                    .padding(.bottom, -70)

                DisplayAdBtnView(title: "Collect Credits")

                Button {
                    isViewPresented = false
                } label: {
                    Text("Not now")
                        .foregroundColor(.ui.cadetBlueCrayola)
                        .font(.ui.headline)
                }
            }
            .padding(.top, 35)
        }
        .onChange(of: self.ad.isRewardedVideoFinished, perform: { isFinished in
            self.isAdDone = isFinished
        })
        .onChange(of: self.isAdDone, perform: { isDone in
            if isDone {
                self.isViewPresented = false

                withAnimation {
                    guard let showCongratsModal = authManager.user?.userPrefs.showCongratsModal else { return }
                    if showCongratsModal {
                        self.showCongratsModal = true
                    }
                }
            }
        })
    }
}

struct RewardedAdView_Previews: PreviewProvider {
    static var previews: some View {
        RewardedAdView(isViewPresented: .constant(true), showCongratsModal: .constant(false))
    }
}
