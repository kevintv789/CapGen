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
    
    private let auth = Auth.auth()
    static let shared = AuthManager()
    var handle : AuthStateDidChangeListenerHandle?
    
    override private init() {
        isSignedIn = false
        super.init()
        handle = auth.addStateDidChangeListener(authStateChanged)
    }
    
    func login(credential: AuthCredential, completionBlock: @escaping (_ success: Bool) -> Void) {
        Auth.auth().signIn(with: credential, completion: { (user, error) in
            completionBlock(error == nil)
            self.isSignedIn = true
        })
    }
    
    func logout() {
        if (googleAuthMan.googleSignInState == .signedIn) {
            // We know Google SSO was used, sign out using Google
            // so that users can login into a different account
            googleAuthMan.signOut()
        }
        
        try? Auth.auth().signOut()
        self.isSignedIn = false
    }
    
    private func authStateChanged(with auth: Auth, user: User?) {
        if user != nil {
            // User is signed in
            self.isSignedIn = true
        } else {
            self.isSignedIn = false
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
