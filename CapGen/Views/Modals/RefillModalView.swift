//
//  RefillView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/17/23.
//

import SwiftUI

struct RefillModalView: View {
    @ObservedObject var ad = AppodealProvider.shared
    @EnvironmentObject var firestoreMan: FirestoreManager
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

                DisplayAdBtnView(btnLength: .short, title: "Collect Credits")
            }
            .padding(30)
        }
        .onChange(of: self.ad.isRewardedVideoFinished, perform: { isFinished in
            self.isAdDone = isFinished
        })
        .onChange(of: self.isAdDone) { isDone in
            if isDone {
                self.isViewPresented = false
                
                withAnimation {
                    guard let showCongratsModal = authManager.user?.userPrefs.showCongratsModal else { return }
                    
                    if showCongratsModal {
                        self.showCongratsModal = true
                    }
                }
            }
        }
    }
}
