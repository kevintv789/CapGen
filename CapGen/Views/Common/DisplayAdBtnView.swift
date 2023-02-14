//
//  DisplayAdBtnView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/18/23.
//

import NavigationStack
import SwiftUI

enum ButtonLength {
    case short, full
}

struct DisplayAdBtnView: View {
    @EnvironmentObject var firestoreMan: FirestoreManager
    @EnvironmentObject var rewardedAd: GoogleRewardedAds
    @EnvironmentObject var navStack: NavigationStackCompat

    @State var router: Router? = nil

    @State var btnLength: ButtonLength = .full
    @State var isLoading: Bool = false
    let authManager = AuthManager.shared.userManager

    @State var title: String
    @Binding var isAdDone: Bool?

    func displayBtnOverlay() -> some View {
        if isLoading {
            return AnyView(
                LottieView(name: "btn_loader", loopMode: .loop, isAnimating: true)
                    .frame(width: 100, height: 100)
            )
        } else {
            return AnyView(
                Text(title)
                    .foregroundColor(.ui.cultured)
                    .font(.ui.title2)
            )
        }
    }

    var body: some View {
        Button {
            Haptics.shared.play(.soft)

            // load new ads
            self.isLoading = true
            self.rewardedAd.loadAd(adUnitId: firestoreMan.admobUnitId) { isLoadDone in
                if isLoadDone {
                    self.isLoading = false
                    self.isAdDone = self.rewardedAd.showAd(rewardFunction: {
                        firestoreMan.incrementCredit(for: authManager.user?.id as? String ?? nil)
                    })
                }
            }

        } label: {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.ui.orangeWeb)
                .frame(width: btnLength == .full ? SCREEN_WIDTH / 1.2 : SCREEN_WIDTH / 1.4, height: 55)
                .frame(maxWidth: .infinity, alignment: .center)
                .overlay(displayBtnOverlay())
        }

        .disabled(self.isLoading)
        .onAppear {
            self.router = Router(navStack: navStack)
        }
        .onReceive(self.rewardedAd.$appError) { value in
            if let error = value?.error {
                if error == .genericError {
                    self.router?.toGenericFallbackView()
                }
            }
        }
    }
}
