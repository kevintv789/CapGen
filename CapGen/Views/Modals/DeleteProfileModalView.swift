//
//  DeleteProfileModalView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/27/23.
//

import SwiftUI

struct DeleteProfileModalView: View {
    @Binding var showView: Bool
    var onDelete: () -> Void
    
    var body: some View {
        ZStack {
            Color.ui.cultured.ignoresSafeArea(.all)
            
            VStack(spacing: 20) {
                Text("Are you sure? 🥺")
                    .font(.ui.largeTitleSm)
                    .foregroundColor(.ui.richBlack)
                    .padding(.top, 10)
                
                Text("We appreciate you spending time with us. We'll be sad to see you go. To permanently delete your profile, click the red button below.")
                    .foregroundColor(.ui.richBlack)
                    .font(.ui.title3)
                    .frame(height: 120, alignment: .center)
                    .multilineTextAlignment(.center)
                    .lineSpacing(10)
                
                if (AuthManager.shared.appleAuthManager.appleSignedInStatus == .signedIn) {
                    Text("To officially revoke your Apple ID from CapGen, please go to ")
                        .foregroundColor(.ui.richBlack)
                        .font(.ui.title3)
                        .frame(height: 60, alignment: .center)
                        .multilineTextAlignment(.center)
                        .lineSpacing(10)
                        .padding(.bottom, -20)
                    
                    Text("Settings > Apple ID > Password & Security > Apps Using Apple ID.")
                        .foregroundColor(.ui.richBlack)
                        .font(.ui.title4Medium)
                        .frame(height: 60, alignment: .center)
                        .multilineTextAlignment(.center)
                        .lineSpacing(10)
                }
                
                LottieView(name: "sad_emoji_lottie", loopMode: .loop, isAnimating: true)
                    .frame(width: 120, height: 120)
                
                Button {
                    Haptics.shared.play(.soft)
                    showView = false
                } label: {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.ui.darkerPurple)
                        .frame(width: SCREEN_WIDTH/1.4, height: 55)
                        .overlay(
                            Text("Keep Profile")
                                .foregroundColor(.ui.cultured)
                                .font(.ui.title2)
                        )
                }
                
                Button {
                    Haptics.shared.play(.soft)
                    onDelete()
                    showView = false
                } label: {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.ui.dangerRed, lineWidth: 2)
                        .frame(width: SCREEN_WIDTH/1.4, height: 55)
                        .overlay(
                            Text("Delete Profile")
                                .foregroundColor(.ui.dangerRed)
                                .font(.ui.title2)
                        )
                }
                
                Spacer()
            }
            .padding()
           
        }
        .onAppear() {
            logScreenAnalytics(for: "\(DeleteProfileModalView.self)")
        }
    }
}

struct DeleteProfileModalView_Previews: PreviewProvider {
    static var previews: some View {
        DeleteProfileModalView(showView: .constant(true), onDelete: {})
        
        DeleteProfileModalView(showView: .constant(true), onDelete: {})
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE (3rd generation)")
    }
}
