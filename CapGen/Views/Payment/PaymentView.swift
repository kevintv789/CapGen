//
//  PaymentView.swift
//  Demo
//
//  Created by Kevin Vu on 5/12/23.
//

import SwiftUI
import Heap
import NavigationStack

struct PaymentView: View {
    @ObservedObject var ad = AppodealProvider.shared
    @EnvironmentObject var firestoreMan: FirestoreManager
    @EnvironmentObject var navStack: NavigationStackCompat
    @EnvironmentObject var authManager: AuthManager

    @State var router: Router? = nil
    
    @Environment(\.dismiss) var dismiss
    
    @State var currentCredits: Int = 0
    @State var isAnimating: Bool = true
    @State var is10CreditsSelected: Bool = true
    @State var is50CreditsSelected: Bool = false
    
    var body: some View {
        ZStack {
            Color.ui.cultured.ignoresSafeArea(.all)
            
            ScrollView(.vertical, showsIndicators: false) {
                    HStack {
                        Text("Current credits:")
                            .font(.ui.headline)
                            .foregroundColor(.ui.richBlack.opacity(0.6))
                        
                        CreditCounterView(credits: $currentCredits)
                            .onReceive(authManager.userManager.$user) { user in
                                if let user = user {
                                    self.currentCredits = user.credits
                                }
                            }
                    }
                
                    // title & subtitle
                    VStack(spacing: 15) {
                        Text("Power Up Your Posts")
                            .font(.ui.title4Bold)
                            .foregroundColor(.ui.richBlack.opacity(0.6))
                        
                        Text("Unlock more with CapGen credits!")
                            .font(.ui.headlineRegular)
                            .foregroundColor(.ui.richBlack.opacity(0.6))
                    }
                    .padding(.top, 30)
                    
                    ZStack {
                        Rectangle()
                            .fill(Color.ui.lavenderBlue)
                            .cornerRadius(32, corners: [.topLeft, .topRight])
                        
                        // Piggy bank lottie file
                        LottieView(name: "piggy_bank_lottie", loopMode: .playOnce, isAnimating: isAnimating)
                            .frame(width: 250, height: 250)
                            .frame(maxHeight: .infinity, alignment: .top)
                            .offset(y: -150)
                            .onTapGesture {
                                self.isAnimating = false
                                self.isAnimating = true
                            }
                        
                        VStack {
                            // Payment cards
                            VStack {
                                PaymentCard(imageName: "10_credits_robot", pricePoint: 0.99, creditAmount: 10, subtitle: "Enough credits to curate a week's worth of daily posts.", isSelected: $is10CreditsSelected) {
                                    // on press 10 credits
                                    if is50CreditsSelected {
                                        is50CreditsSelected = false
                                    }
                                    
                                    is10CreditsSelected = true
                                }
                                
                                PaymentCard(imageName: "50_credits_robot", pricePoint: 3.99, creditAmount: 50, subtitle: "Perfect for those ready to evolve their social media game!", isSelected: $is50CreditsSelected) {
                                    // on press 50 credits
                                    if is10CreditsSelected {
                                        is10CreditsSelected = false
                                    }
                                    
                                    is50CreditsSelected = true
                                }
                                   
                            }
                            .padding(.top, 90)
                            
                            
                            
                            // Divider
                            Rectangle()
                                .fill(Color.ui.cultured)
                                .frame(width: SCREEN_WIDTH * 0.9, height: 1)
                                .padding(.bottom)
                            
                            // Play ad button
                            AdFullScreenView(
                                ad: self.ad,
                                keyPath: \.isRewardedReady
                            ) {
                                Heap.track("onClick DisplayAdBtnView - Show Ad in Payment View")
                                Haptics.shared.play(.soft)
                                self.ad.presentRewarded()
                            }
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
                            
                            // legal documents
                            LegalDocView()
                                .padding(.vertical, 30)
                            
                            Spacer()
                        }
                        .frame(minHeight: SCREEN_HEIGHT > 700 ? SCREEN_HEIGHT * 0.9 : SCREEN_HEIGHT * 1.2, alignment: .top)
                        
                    }
                    .padding(.top, 150)
            }
            .edgesIgnoringSafeArea(.bottom)
            .safeAreaInset(edge: .bottom) {
                // CTA Buttons here
                ZStack {
                    Color.ui.lavenderBlue.opacity(0.75).ignoresSafeArea(.all)
                    
                    VStack {
                        ContinueButton() {
                            // continue button clicked
                        }
                        
                        Text("Not now")
                            .foregroundColor(.ui.richBlack.opacity(0.5))
                            .font(.ui.title4Medium)
                            .padding(.vertical)
                            .padding(.bottom)
                            .onTapGesture {
                                // on dismiss press
                                dismiss()
                            }
                    }
                }
                .frame(width: SCREEN_WIDTH, height: 100)
            }
          
        }
    }
}

struct ContinueButton: View {
    let action: () -> Void
    
    var body: some View {
        Button   {
            action()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.ui.darkerPurple)
                    .frame(width: SCREEN_WIDTH * 0.8, height: 60)
                
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.ui.cultured, lineWidth: 3)
                    .frame(width: SCREEN_WIDTH * 0.8, height: 60)
                
                Text("Continue")
                    .font(.ui.title4)
                    .foregroundColor(.ui.cultured)
            }
        }
    }
}

struct LegalDocView: View {
    var body: some View {
        HStack(spacing: 40) {
            Text("[EULA](https://capgen.app/eula)")
                .underline()
                .font(.ui.bodyLarge)
            
            Text("[Terms](https://capgen.app/terms-conditions)")
                .underline()
                .font(.ui.bodyLarge)
            
            Text("[Privacy Policy](https://capgen.app/privacy-policy)")
                .underline()
                .font(.ui.bodyLarge)
        }
        
    }
}

struct AdButton: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.ui.cultured, lineWidth: 2)
            
            HStack {
                Text("🎁")
                    .font(.system(size: 40))
                
                // header
                VStack(alignment: .leading, spacing: 10) {
                    Text("Fancy a Free Credit?")
                        .foregroundColor(.ui.cultured)
                        .font(.ui.title4Medium)
                    
                    Text("Simply watch an ad and claim it!")
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.ui.cultured)
                        .font(.ui.bodyLarge)
                }
            }
        }
        .frame(width: SCREEN_WIDTH * 0.75, height: 90)
        
    }
}

struct AdFullScreenView<T>: View where T: ObservableObject {
    typealias Action = () -> Void
    @ObservedObject var ad: T
    var keyPath: ReferenceWritableKeyPath<T, Bool>
    var action: Action
    
    var body: some View {
        // if ad is ready to load, then display view
        if ad[keyPath: keyPath] {
            Button {
                action()
            } label: {
                AdButton()
            }
            .transition(.opacity)
        }
       
    }
}

struct PaymentCard: View {
    var imageName: String
    var pricePoint: Float
    var creditAmount: Int
    var subtitle: String
    @Binding var isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.ui.darkerPurple : Color.ui.cultured)
                    .frame(width: SCREEN_WIDTH * 0.9, height: 150)
                    .if(isSelected) { view in
                        return view
                            .shadow(color: Color.ui.richBlack.opacity(0.25), radius: 4, x: 2, y: 4)
                    }
                
                if isSelected {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.ui.cultured, lineWidth: 5)
                        .frame(width: SCREEN_WIDTH * 0.9, height: 150)
                }
                
                HStack {
                    // Robot image
                    Image(imageName)
                        .resizable()
                        .frame(width: 160, height: 170)
                        .padding(.trailing, -30)
                    
                    Spacer()
                    
                    // Copy
                    VStack(alignment: .leading, spacing: 10) {
                        Text("\(creditAmount) CapGen Credits")
                            .foregroundColor(isSelected ? .ui.cultured : .ui.richBlack.opacity(0.6))
                            .font(.ui.title4Bold)
                            .padding(.bottom, 5)
                            .if(SCREEN_HEIGHT < 700 && isSelected) { view in
                                return view.padding(.top, 10)
                            }
                        
                        Text(subtitle)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(isSelected ? .ui.cultured : .ui.richBlack.opacity(0.6))
                            .font(.ui.headlineMd)
                            .lineSpacing(5)
                            .padding(.trailing)
                        
                        // Price point
                        Text("$\(pricePoint, specifier: "%.2f")")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .font(.ui.title4Bold)
                            .foregroundColor(isSelected ? .ui.cultured : .ui.richBlack.opacity(0.6))
                            .padding(.trailing, 30)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                   
                    Spacer()
                }
            }
        }
       
    }
}

struct CreditCounterView: View {
    @Binding var credits: Int
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Text("\(credits > 999 ? "999+" : "\(credits)")")
                .font(.ui.headline)
                .foregroundColor(.ui.orangeWeb)
                .padding(.leading, 15)
                
            
            Image("coin-icon")
                .resizable()
                .frame(width: 40, height: 35)
                .padding(.bottom, 3)
            
        }
        .overlay (
            RoundedRectangle(cornerRadius: 100)
                .stroke(Color.ui.orangeWeb, lineWidth: 2)
        )
    }
}
