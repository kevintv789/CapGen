//
//  CreditsDepletedModalView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/17/23.
//

import SwiftUI
import NavigationStack

struct CreditsDepletedModalView: View {
    @EnvironmentObject var firestoreMan: FirestoreManager
    @EnvironmentObject var rewardedAd: GoogleRewardedAds
    @EnvironmentObject var navStack: NavigationStackCompat
    
    @State var router: Router? = nil
    @Binding var isViewPresented: Bool
    
    @State var isAdDone: Bool? = false
    @State var isAdLoading: Bool = false
    
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
                
                DisplayAdBtnView(title: "Collect Credits", isAdDone: $isAdDone)
                
                Button {
                    Haptics.shared.play(.soft)
                    
                    // Update data field in firestore
                    firestoreMan.setShowCreditDepletedModal(for: userId, to: false)
                    
                    // Play ad
                    self.isAdLoading = true
                    self.rewardedAd.loadAd(adUnitId: firestoreMan.admobUnitId) { isLoadDone in
                        if (isLoadDone) {
                            self.isAdLoading = false
                            self.isAdDone = self.rewardedAd.showAd(rewardFunction: {
                                firestoreMan.incrementCredit(for: userId)
                            })
                        }
                    }
                    
                } label: {
                    Text("Just play ad next time")
                        .foregroundColor(.ui.cadetBlueCrayola)
                        .font(.ui.headline)
                        .padding(.bottom, 30)
                }
                .disabled(self.isAdLoading)
            }
            .padding(.top, 35)
        }
        .onAppear {
            logScreenAnalytics(for: "\(CreditsDepletedModalView.self)")
            
            self.router = Router(navStack: navStack)
            // Dismiss bottom sheet modal when ad is exited
            guard let isAdDone = self.isAdDone else { return }
            if (isAdDone) {
                self.isViewPresented = false
                self.router?.toLoadingView()
            }
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
