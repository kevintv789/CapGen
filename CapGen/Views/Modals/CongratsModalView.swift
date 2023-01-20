//
//  CongratsModalView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/15/23.
//

import SwiftUI

struct CongratsModalView: View {
    @EnvironmentObject var firestoreMan: FirestoreManager
    @EnvironmentObject var rewardedAd: GoogleRewardedAds
    @Binding var showView: Bool
    
    let userManager = AuthManager.shared.userManager
    
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
                    .frame(width: SCREEN_WIDTH / 2, height: 200)
                    .padding(-60)
                
                DisplayAdBtnView(btnLength: .short, title: "Collect More", isAdDone: .constant(nil))
                
                Button {
                    withAnimation {
                        showView = false
                        firestoreMan.setShowCongratsModal(for: userManager.user?.id as? String ?? nil, to: false)
                    }
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

struct CongratsModalView_Previews: PreviewProvider {
    static var previews: some View {
        CongratsModalView(showView: .constant(true))
    }
}