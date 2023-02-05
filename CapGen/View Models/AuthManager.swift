//
//  AuthManager.swift
//  CapGen
//
//  Created by Kevin Vu on 1/13/23.
//

import Foundation
import Firebase
import FirebaseAuth
import SwiftUI

class AuthManager: NSObject, ObservableObject {
    @Published var isSignedIn: Bool?
    @Published var googleAuthMan: GoogleAuthManager = GoogleAuthManager()
    @Published var fbAuthManager: FBAuthManager = FBAuthManager()
    @Published var appleAuthManager: SignInWithApple = SignInWithApple()
    @Published var userManager: UserManager = UserManager()
    @Published var appError: ErrorType?
    
    private let auth = Auth.auth()
    static let shared = AuthManager()
    var handle : AuthStateDidChangeListenerHandle?
    
    override private init() {
        isSignedIn = false
        super.init()
        handle = auth.addStateDidChangeListener(authStateChanged)
    }
    
    func login(credential: AuthCredential, completionBlock: @escaping (_ success: Bool) -> Void) {
        Auth.auth().signIn(with: credential, completion: { (result, error) in
            if error != nil {
                self.appError = ErrorType(error: .loginError)
                print("ERROR logging into Firebase", error!.localizedDescription)
                return
            }
            
            guard let userId = self.auth.currentUser?.uid else { return }

            completionBlock(error == nil)
            self.userManager.createUserDoc(auth: self.auth)
            self.userManager.getUser(with: userId)
            self.isSignedIn = true
        })
    }
    
    func setSignOut() {
        self.isSignedIn = false
        self.unbindAuth()
        self.userManager.unbindSnapshot()
    }
    
    func logout() {
        do {
            if (googleAuthMan.googleSignInState == .signedIn) {
                // We know Google SSO was used, sign out using Google
                // so that users can login into a different account
                googleAuthMan.signOut()
            }
            
            if (appleAuthManager.appleSignedInStatus == .signedIn) {
                appleAuthManager.signOut()
            }
            
            if (fbAuthManager.fbSignedInStatus == .signedIn) {
                fbAuthManager.signOut()
            }
            
            try Auth.auth().signOut()
            
            self.setSignOut()
            
        } catch let error as NSError {
            self.appError = ErrorType(error: .genericError)
            print("Failed to sign out", error)
        }
    }
    
    private func authStateChanged(with auth: Auth, user: User?) {
        if user != nil {
            // User is signed in
            let userId = user!.uid
            self.userManager.getUser(with: userId)
            
            self.isSignedIn = true
        } else {
            self.setSignOut()
        }
    }
    
    func unbindAuth() {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    deinit {
        unbindAuth()
    }
}
