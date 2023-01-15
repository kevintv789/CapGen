//
//  RewardedAdView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/14/23.
//

import SwiftUI

struct RewardedAdView: View {
    @EnvironmentObject var rewardedAd: GoogleRewardedAds
    @Binding var isViewPresented: Bool
    @State var isAdDone: Bool = false
    @Binding var showCongratsModal: Bool
    
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
                
                Button {
                    self.isAdDone = self.rewardedAd.showAd(rewardFunction: {
                        print("REWARDEDDDD")
                        // Give users their credit
                    })
                } label: {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.ui.orangeWeb)
                        .frame(width: SCREEN_WIDTH / 1.2, height: 55)
                        .overlay(
                            Text("Collect Credits")
                                .foregroundColor(.ui.cultured)
                                .font(.ui.title2)
                        )
                }
                
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
        .onAppear {
            // Dismiss bottom sheet modal when ad is exited
            if (isAdDone) {
                self.isViewPresented = false
                self.rewardedAd.loadAd() // load new ads
                
                withAnimation {
                    self.showCongratsModal = true
                }
               
            }
        }
    }
}

struct RewardedAdView_Previews: PreviewProvider {
    static var previews: some View {
        RewardedAdView(isViewPresented: .constant(true), showCongratsModal: .constant(false))
    }
}
