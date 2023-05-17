//
//  PaymentView.swift
//  Demo
//
//  Created by Kevin Vu on 5/12/23.
//

import SwiftUI
import Heap
import NavigationStack

struct AlertItem: Identifiable {
    let id = UUID()
    let message: String
}

struct PaymentView: View {
    @ObservedObject var ad = AppodealProvider.shared
    @EnvironmentObject var firestoreMan: FirestoreManager
    @EnvironmentObject var navStack: NavigationStackCompat
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var paymentVm: PaymentViewModel
    
    @State var router: Router? = nil
    
    @Environment(\.dismiss) var dismiss
    
    // dependencies
    var title: String = "Power up your posts"
    var subtitle: String = "Unlock more with CapGen credits!"
    
    @State var currentCredits: Int = 0
    @State var isAnimating: Bool = true
    @State var is10CreditsSelected: Bool = false
    @State var is50CreditsSelected: Bool = false
    @State private var alertItem: AlertItem? = nil
    
    var body: some View {
        ZStack {
            Color.ui.cultured.ignoresSafeArea(.all)
            
            ScrollView(.vertical, showsIndicators: false) {
                ZStack(alignment: .top) {
                    HStack {
                        Spacer()
                        
                        // Credit counter
                        Text("Current credits:")
                            .font(.ui.headline)
                            .foregroundColor(.ui.richBlack.opacity(0.6))
                        
                        CreditCounterView(credits: $currentCredits)
                            .onReceive(authManager.userManager.$user) { user in
                                if let user = user {
                                    self.currentCredits = user.credits
                                }
                            }
                        
                        Spacer()
                    }
                    
                    // Close button
                    HStack {
                        Button {
                            Haptics.shared.play(.soft)
                            dismiss()
                        } label: {
                            Image("close")
                                .resizable()
                                .frame(width: 24, height: 24)
                        }
                        .padding(.leading, 30)
                        .padding(.top, 7)
                        
                        Spacer()
                    }
                }
                
                // title & subtitle
                VStack(spacing: 15) {
                    Text(title)
                        .font(.ui.title4Bold)
                        .foregroundColor(.ui.richBlack.opacity(0.6))
                    
                    Text(subtitle)
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
                        if !paymentVm.products.isEmpty {
                            VStack(spacing: 0) {
                                PaymentCard(imageName: "10_credits_robot", pricePoint: paymentVm.products[0].displayPrice, creditAmount: 10, subtitle: "Enough credits to curate a week's worth of daily posts.", isSelected: $is10CreditsSelected) {
                                    // on press 10 credits
                                    Haptics.shared.play(.soft)
                                    if is50CreditsSelected {
                                        is50CreditsSelected = false
                                    }
                                    
                                    is10CreditsSelected = true
                                    
                                    paymentVm.purchase(paymentVm.products[0]) { errorMessage in
                                        is10CreditsSelected = false
                                        
                                        if let error = errorMessage {
                                            alertItem = AlertItem(message: error)
                                        }
                                    }
                                }
                                
                                PaymentCard(imageName: "50_credits_robot", pricePoint: paymentVm.products[1].displayPrice, creditAmount: 50, subtitle: "Perfect for those ready to evolve their social media game!", isSelected: $is50CreditsSelected) {
                                    // on press 50 credits
                                    Haptics.shared.play(.soft)
                                    if is10CreditsSelected {
                                        is10CreditsSelected = false
                                    }
                                    
                                    is50CreditsSelected = true
                                    
                                    paymentVm.purchase(paymentVm.products[1]) { errorMessage in
                                        is50CreditsSelected = false
                                        
                                        if let error = errorMessage {
                                            alertItem = AlertItem(message: error)
                                        }
                                    }
                                }
                                
                            }
                            .padding(.top, 90)
                        }
                        
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
                    .frame(minHeight: SCREEN_HEIGHT > 700 ? SCREEN_HEIGHT * 0.75 : SCREEN_HEIGHT * 1.05, alignment: .top)
                    
                }
                .padding(.top, 150)
            }
        }
        // alerts the user of any errors
        .alert(item: $alertItem) { item in
            Alert(title: Text("Purchase Error"), message: Text(item.message), dismissButton: .default(Text("OK")))
        }
        .edgesIgnoringSafeArea(.bottom)
        .onAppear() {
            // Get products from storekit
            paymentVm.getProducts()
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
    var pricePoint: String
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
                        Text(pricePoint)
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
