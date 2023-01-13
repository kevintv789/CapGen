//
//  SignInWithAppleDelegate.swift
//  CapGen
//
//  Created by Kevin Vu on 1/12/23.
//

import Foundation
import SwiftUI
import AuthenticationServices
import CryptoKit
import FirebaseAuth

/**
 For every sign-in request, generate a random string—a "nonce"—which you will use to make sure the ID token you get was granted specifically in response to your app's authentication request. This step is important to prevent replay attacks.
 */
func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: Array<Character> =
    Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length
    
    while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
            var random: UInt8 = 0
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if errorCode != errSecSuccess {
                fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
            }
            return random
        }
        
        randoms.forEach { random in
            if remainingLength == 0 {
                return
            }
            
            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
    }
    
    return result
}

//Hashing function using CryptoKit
func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    let hashString = hashedData.compactMap {
        return String(format: "%02x", $0)
    }.joined()
    
    return hashString
}

class SignInWithAppleDelegate: NSObject, ASAuthorizationControllerDelegate {
    var onComplete: (ASAuthorizationAppleIDCredential) -> Void
    var onCompletePassword: (ASPasswordCredential) -> Void
    var onError: (Error) -> Void
    private var controller: ASAuthorizationController?
    
    init(onComplete: @escaping (ASAuthorizationAppleIDCredential) -> Void, onCompletePassword: @escaping (ASPasswordCredential) -> Void, onError: @escaping (Error) -> Void) {
        self.onComplete = onComplete
        self.onCompletePassword = onCompletePassword
        self.onError = onError
    }
    
    func signIn() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = randomNonceString()
        
        controller = ASAuthorizationController(authorizationRequests: [request])
      
        controller?.delegate = self
        controller?.performRequests()
    }
    
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            onComplete(appleIDCredential)
        } else if authorization.credential is ASPasswordCredential {
            onCompletePassword(authorization.credential as! ASPasswordCredential)
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        onError(error)
    }
}

class SignInWithApple: ObservableObject {
    var delegate: SignInWithAppleDelegate
    
    init() {
        let signInWithAppleDelegate = SignInWithAppleDelegate { credential in
            print("ONCOMPLETE", credential)
            // Plug in firebase code here
        } onCompletePassword: { credential in
            print("ONPASSWORD", credential)
        } onError: { error in
            print(error)
        }
        
        delegate = signInWithAppleDelegate
    }
    
    func signIn() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = delegate
        controller.performRequests()
    }
}
