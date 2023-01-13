//
//  LaunchView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/11/23.
//

import SwiftUI

struct LaunchView: View {
    @State var currentNonce:String?
    @State var initialText: String = ""
    @State var finalText: String = {
        if (SCREEN_HEIGHT < 700) {
            return "Greetings, content creator! I'm here to help you craft great captions for all your social media needs. 🫡"
        } else {
            return "Greetings, content creator! I'm here to help you craft great captions for all your social media needs. 🫡"
        }
    }()
    
    var body: some View {
        ZStack {
            Color.ui.cultured
                .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                LottieView(name: "robot_lottie", loopMode: .loop)
                    .frame(width: SCREEN_WIDTH, height: SCREEN_HEIGHT / 2)
                
                AnimatedTextView(initialText: $initialText, finalText: self.finalText, isRepeat: false, timeInterval: 10, typingSpeed: 0.01)
                    .font(.ui.headline)
                    .foregroundColor(.ui.richBlack)
                    .frame(width: SCREEN_WIDTH * 0.9)
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
        ZStack {
            HStack {
                SignInWithAppleView()
            }
            
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
            signInWithApple.signIn()
        } label: {
            Text("HELLO")
        }
    }
}

struct SSOButton: View {
    var title: String
    var iconName: String
    var action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.ui.cultured, lineWidth: 2)
                .frame(height: 50)
                .overlay(
                    HStack {
                        Spacer()
                        
                        Image(iconName)
                            .resizable()
                            .frame(width: 20, height: 20, alignment: .center)
                        
                        Spacer()
                        
                        Text(title)
                            .foregroundColor(.ui.cultured)
                            .frame(width: SCREEN_WIDTH / 1.7, alignment: .leading)
                            .font(.ui.headline)
                        
                        Spacer()
                    }
                    
                )
        }
    }
}
