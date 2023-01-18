//
//  RefillView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/17/23.
//

import SwiftUI

struct RefillModalView: View {
    @EnvironmentObject var firestoreMan: FirestoreManager
    @EnvironmentObject var rewardedAd: GoogleRewardedAds
    @Binding var isViewPresented: Bool
    @Binding var showCongratsModal: Bool
    
    let authManager = AuthManager.shared.userManager
    
    @State var isAdDone: Bool = false
    
    var body: some View {
        ZStack {
            Color.ui.cultured.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Text("Need a refill?")
                    .font(.ui.largeTitleSm)
                    .foregroundColor(.ui.richBlack)
                    .padding(.bottom, 15)
                
                Text("No problem! 👌 Just watch a quick ad to keep the captions flowing.")
                    .foregroundColor(.ui.richBlack)
                    .font(.ui.title3)
                    .frame(height: 80, alignment: .center)
                    .multilineTextAlignment(.center)
                    .lineSpacing(10)
                
                LottieView(name: "piggy_bank_lottie", loopMode: .loop, isAnimating: true)
                    .frame(width: 200, height: 200)
                    .padding(-20)
                
                Button {
                    self.isAdDone = self.rewardedAd.showAd(rewardFunction: {
                        firestoreMan.incrementCredit(for: authManager.user?.id as? String ?? nil)
                    })
                } label: {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.ui.orangeWeb)
                        .frame(width: SCREEN_WIDTH / 1.4, height: 55)
                        .overlay(
                            Text("Collect Credits")
                                .foregroundColor(.ui.cultured)
                                .font(.ui.title2)
                        )
                }
                .padding(.top, 15)
            }
            .padding(30)
        }
        .onAppear {
            // Dismiss bottom sheet modal when ad is exited
            if (isAdDone) {
                self.isViewPresented = false
                self.rewardedAd.loadAd() // load new ads
                
                withAnimation {
                    guard let showCongratsModal = authManager.user?.userPrefs.showCongratsModal else { return }
                    
                    print("SHOW MDOAL", showCongratsModal)
                    if (showCongratsModal) {
                        self.showCongratsModal = true
                    }
                }
                
            }
        }
    }
}
