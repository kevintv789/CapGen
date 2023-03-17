//
//  CreditsDepletedModalView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/17/23.
//

import NavigationStack
import SwiftUI

struct CreditsDepletedModalView: View {
    @ObservedObject var ad = AppodealProvider.shared
    @EnvironmentObject var firestoreMan: FirestoreManager
    @EnvironmentObject var navStack: NavigationStackCompat

    @State var router: Router? = nil
    @Binding var isViewPresented: Bool

    @State var isAdInitialized: Bool = false

    @State var isAdDone: Bool = false

    let userId: String? = AuthManager.shared.userManager.user?.id as? String ?? nil

    var body: some View {
        ZStack(alignment: .top) {
            Color.ui.cultured
                .ignoresSafeArea(.all)

            VStack(spacing: 20) {
                Text("Credits depleted")
                    .foregroundColor(.ui.richBlack)
                    .font(.ui.largeTitleSm)

                Text("We've got you covered! Just watch an ad and we'll take care of the rest 😉")
                    .foregroundColor(.ui.richBlack)
                    .font(.ui.bodyLarge)
                    .lineSpacing(10)
                    .frame(width: SCREEN_WIDTH * 0.9, height: 50, alignment: .center)
                    .multilineTextAlignment(.center)

                LottieView(name: "coin_pile_lottie", loopMode: .loop, isAnimating: true)
                    .position(x: SCREEN_WIDTH / 2, y: 30)
                    .frame(width: SCREEN_WIDTH, height: 230)
                    .padding(.bottom, -70)

                DisplayAdBtnView(title: "Collect Credits")
            }
            .padding(.top, 35)
        }
        .onChange(of: self.ad.isRewardedVideoFinished, perform: { isFinished in
            self.isAdDone = isFinished
        })
        .onChange(of: self.isAdDone, perform: { isDone in
            if isDone {
                // Navigate to generate captions views
                self.navStack.push(EnterPromptView())
                
                self.isViewPresented = false
            }
        })
        .onReceive(self.ad.$isRewardedReady, perform: { isInitialized in
            self.isAdInitialized = isInitialized
        })
        .onAppear {
            self.router = Router(navStack: navStack)
        }
        .onReceive(self.ad.$appError) { value in
            if let error = value?.error {
                if error == .genericError {
                    self.router?.toGenericFallbackView()
                }
            }
        }
    }
}
