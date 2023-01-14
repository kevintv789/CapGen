//
//  LaunchView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/11/23.
//

import SwiftUI

extension View {
    func customShadow() -> some View {
        self.shadow(color: .ui.shadowGray, radius: 2, x: 2, y: 2)
    }
}

struct LaunchView: View {
    @State var currentNonce:String?
    @State var initialText: String = ""
    @State var finalText: String = "Greetings, user! I'm here to help you craft great captions for all your social media needs. 🫡"
    
    var body: some View {
        ZStack {
            Color.ui.cultured
                .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                LottieView(name: "robot_lottie", loopMode: .loop, isAnimating: true)
                    .frame(width: SCREEN_WIDTH, height: SCREEN_HEIGHT / 2)
                
                AnimatedTextView(initialText: $initialText, finalText: self.finalText, isRepeat: false, timeInterval: 10, typingSpeed: 0.01)
                    .font(.ui.headline)
                    .foregroundColor(.ui.richBlack)
                    .frame(width: SCREEN_WIDTH * 0.9, height: 100)
                    .multilineTextAlignment(.center)
                    .lineSpacing(10)
                
                Spacer()
                
                SSOLoginView()
                    .ignoresSafeArea(.all)
            }
        }
    }
}

struct LaunchView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchView()
    }
}

struct SSOLoginView: View {
    var body: some View {
        VStack {
            Spacer()
                .frame(height: 50)
            
            SignInDivider()
                .padding(.bottom, 15)
            
            HStack(spacing: 30) {
                SignInWithAppleView()
                FacebookSignInView()
                GoogleSignInView()
            }
            Spacer()
            
            
        }
    }
}

struct SignInWithAppleView: View {
    /**
     When you use @ObservedObject on a property, SwiftUI automatically listens for changes to the object, and when the object's properties change, the view will update automatically. This way, you don't have to manually update the view when the data changes.
     
     For example, you can use ObservableObject and @ObservedObject to create a shared data model that multiple views can access and update. When the data model changes, the views that use the model will automatically update.
     */
    @ObservedObject var signInWithApple = SignInWithApple()
    
    var body: some View {
        Button {
            signInWithApple.setDelegate()
            signInWithApple.signIn()
        } label: {
            Circle()
                .fill(Color.ui.richBlack)
                .customShadow()
                .overlay(
                    Image("apple-icon")
                        .resizable()
                        .frame(width: 25, height: 25)
                    
                )
                .frame(width: 55, height: 55)
        }
    }
}

struct FacebookSignInView: View {
    @ObservedObject var signInWithFB = FBAuthManager()
    
    var body: some View {
        Button {
            signInWithFB.login()
        } label: {
            Image("facebook-circle-icon")
                .resizable()
                .frame(width: 65, height: 65)
                .customShadow()
        }
    }
}

struct GoogleSignInView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        Button {
            // Need to reference google auth inside authManager to get the logged in status of googleAuthMan
            authManager.googleAuthMan.signIn()
        } label: {
            Circle()
                .strokeBorder(Color.ui.cadetBlueCrayola, lineWidth: 1)
                .customShadow()
                .overlay(
                    Image("google-icon")
                        .resizable()
                        .frame(width: 37, height: 37)
                    
                )
                .frame(width: 60, height: 60)
        }
    }
}

struct SignInDivider: View {
    var body: some View {
        HStack {
            Rectangle()
                .fill(Color.ui.richBlack)
                .frame(width: 100, height: 1)
                .padding(.trailing, 10)
            
            Text("Sign in with")
                .font(.ui.headline)
                .foregroundColor(.ui.richBlack)
            
            Rectangle()
                .fill(Color.ui.richBlack)
                .frame(width: 100, height: 1)
                .padding(.leading, 10)
        }
    }
}
