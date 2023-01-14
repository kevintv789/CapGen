//
//  ProfileView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/13/23.
//

import SwiftUI
import FirebaseAuth

extension Text {
    func customProfileHeadline() -> some View {
        return self
            .foregroundColor(.ui.richBlack)
            .font(.ui.headline)
            .offset(y: -15)
            .lineSpacing(8)
    }
}

struct ProfileView: View {
    @State var backBtnClicked: Bool = false
    @Binding var isPresented: Bool
    
    var dividerText: String = {
        if (SCREEN_WIDTH > 400) {
            return "Thanks for using CapGen, your support means a lot to us! 🫀"
        } else {
            return "Thanks for using CapGen, we appreciate you! 🫀"
        }
    }()
    
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.ui.cultured
                .ignoresSafeArea(.all)
            
            VStack(alignment: .leading) {
                BackArrowView {
                    self.isPresented = false
                }
                .padding(.leading, 8)
                
                ScrollView(.vertical, showsIndicators: false) {
                    LottieView(name: "robot_plain_lottie", loopMode: .loop, isAnimating: true)
                        .frame(width: SCREEN_WIDTH, height: 130, alignment: .center)
                    
                    GreetingsTextView()
                    
                    CreditAndCaptionsAnimatedView()
                    
                    Divider()
                    
                    Text(dividerText)
                        .foregroundColor(.ui.cadetBlueCrayola)
                        .font(.ui.headlineSm)
                        .frame(width: SCREEN_WIDTH, alignment: .center)
                    
                    ZStack(alignment: .topLeading) {
                        Color.ui.lighterLavBlue
                            .ignoresSafeArea(.all)
                            .opacity(0.4)
                        
                        VStack {
                            ContentSectionView()
                            ConnectSectionView()
                            AccountManagementSectionView(isPresented: $isPresented)
                            
                            VStack(spacing: 7) {
                                Text("Thank you for using")
                                    .foregroundColor(.ui.cadetBlueCrayola)
                                Text("CapGen")
                                    .foregroundColor(.ui.cadetBlueCrayola)
                                    .font(.ui.headline)
                                Text("Version: 1.0.0")
                                    .foregroundColor(.ui.cadetBlueCrayola)
                            }
                            .frame(height: 150)
                            
                        }
                    }
                }
                .ignoresSafeArea(.all)
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(isPresented: .constant(true))
            .environmentObject(GoogleAuthManager())
        
        ProfileView(isPresented: .constant(true))
            .environmentObject(GoogleAuthManager())
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE (3rd generation)")
        
    }
}

struct GreetingsTextView: View {
    @State var initialText: String = ""
    @State var finalText: String = {
        let hour: Int = Calendar.current.component(.hour, from: Date())
        var resultStr: String = ""
        var secondaryStr: String = ""
        
        // 6PM - 4AM = Good evening
        if (18...23).contains(hour) || (0...3).contains(hour) {
            resultStr += "Good evening,"
            secondaryStr = "tonight"
        } else if (5...11).contains(hour) {
            // 5AM - 11AM = Good morning
            resultStr += "Good morning,"
            secondaryStr = "today"
        } else {
            resultStr += "Good afternoon,"
            secondaryStr = "today"
        }
        
        resultStr += " user!\nHow may I be of service \(secondaryStr)? 💡"
        
        return resultStr
    }()
    
    var body: some View {
        AnimatedTextView(initialText: $initialText, finalText: self.finalText, isRepeat: false, timeInterval: 10, typingSpeed: 0.02)
            .font(.ui.headline)
            .foregroundColor(.ui.richBlack)
            .frame(width: SCREEN_WIDTH, height: 50, alignment: .center)
            .multilineTextAlignment(.center)
            .lineSpacing(10)
    }
}

struct CreditAndCaptionsAnimatedView: View {
    @State var animateCoin: Bool = false
    @State var animateSpeechBubble: Bool = false
    
    var body: some View {
        HStack(spacing: 50) {
            Button {
                if (!animateCoin) {
                    animateCoin = true
                }
            } label: {
                VStack {
                    LottieView(name: "gold_coin_lottie", loopMode: .playOnce, isAnimating: animateCoin)
                        .frame(width: 100, height: 100)
                    
                    Text("1\ncredit left")
                        .customProfileHeadline()
                    
                }
                
            }
            
            Button {
                if (!animateSpeechBubble) {
                    animateSpeechBubble = true
                }
            } label: {
                VStack {
                    LottieView(name: "speech_bubble", loopMode: .playOnce, isAnimating: animateSpeechBubble)
                        .frame(width: 90, height: 100)
                    
                    Text("10\ncaptions created")
                        .customProfileHeadline()
                }
            }
        }
        .frame(width: SCREEN_WIDTH, alignment: .center)
        .onChange(of: animateCoin) { _ in
            // resets animated value back to false
            if (animateCoin) {
                Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { _ in
                    animateCoin = false
                }
            }
        }
        .onChange(of: animateSpeechBubble) { _ in
            if (animateSpeechBubble) {
                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                    animateSpeechBubble = false
                }
            }
        }
    }
}

struct OptionButtonView: View {
    var title: String
    var subTitle: String?
    var dangerField: Bool?
    var action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            Rectangle()
                .fill(Color.ui.cultured)
                .overlay(
                    VStack(alignment: .leading, spacing: 10) {
                        Text(title)
                            .foregroundColor(dangerField ?? false ? .ui.dangerRed : .ui.richBlack)
                            .font(.ui.headlineMd)
                            .frame(width: SCREEN_WIDTH, alignment: .leading)
                            .padding(.leading, 25)
                        
                        if (subTitle != nil) {
                            Text(subTitle!)
                                .foregroundColor(dangerField ?? false ? .ui.dangerRed : .ui.richBlack)
                                .font(.ui.bodyLight)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(width: SCREEN_WIDTH/1.4, alignment: .leading)
                                .multilineTextAlignment(.leading)
                                .lineSpacing(5)
                                .padding(.leading, 25)
                        }
                        
                    }
                )
        }
        .frame(height: 100)
    }
}

struct ContentSectionView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Content")
                .font(.ui.headline)
                .foregroundColor(.ui.cadetBlueCrayola)
                .padding()
                .offset(y: 10)
            
            OptionButtonView(title: "📝 Saved captions", subTitle: "Easily view, export, copy and edit your generated captions.") {
                print("Saved captions")
            }
            
            ZStack {
                Color.ui.cultured
                
                Divider()
                    .frame(width: SCREEN_WIDTH / 1.1)
            }
            
            OptionButtonView(title: "🎁 Get more credits", subTitle: "Unlock endless 🔥 captions with CapGen - Watch ads, earn 💰, create more 🌟") {
                print("Saved captions")
            }
            
        }
    }
}

struct ConnectSectionView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Connect")
                .font(.ui.headline)
                .foregroundColor(.ui.cadetBlueCrayola)
                .padding()
                .offset(y: 10)
            
            OptionButtonView(title: "🚀 Share CapGen", subTitle: "Spice up your socials with CapGen. Share with friends via 📱, 🐦 and more!") {
                print("Saved captions")
            }
            
            ZStack {
                Color.ui.cultured
                
                Divider()
                    .frame(width: SCREEN_WIDTH / 1.1)
            }
            
            OptionButtonView(title: "💌 Send us a message", subTitle: "We’re here to help! Need assistance or have feedback? Let us know, we'd love to hear from you.") {
                print("Saved captions")
            }
            
        }
    }
}

struct AccountManagementSectionView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Account Management")
                .font(.ui.headline)
                .foregroundColor(.ui.cadetBlueCrayola)
                .padding()
                .offset(y: 10)
            
            OptionButtonView(title: "🔐 Logout") {
                withAnimation {
                    AuthManager.shared.logout()
                    isPresented = false
                }
            }
            
            ZStack {
                Color.ui.cultured
                
                Divider()
                    .frame(width: SCREEN_WIDTH / 1.1)
            }
            
            OptionButtonView(title: "🔨 Delete profile", subTitle: "Deleting your profile will permanently remove all credits and captions. This action is irreversible, please proceed with caution.", dangerField: true) {
                print("Saved captions")
            }
        }
    }
}
