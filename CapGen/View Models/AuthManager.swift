//
//  AuthManager.swift
//  CapGen
//
//  Created by Kevin Vu on 1/13/23.
//

import Firebase
import FirebaseAuth
import Foundation
import SwiftUI

class AuthManager: NSObject, ObservableObject {
    @Published var isSignedIn: Bool?
    @Published var googleAuthMan: GoogleAuthManager = .init()
    @Published var fbAuthManager: FBAuthManager = .init()
    @Published var appleAuthManager: SignInWithApple = .init()
    @Published var userManager: UserManager = .init()
    @Published var appError: ErrorType?

    private let auth = Auth.auth()
    static let shared = AuthManager()
    var handle: AuthStateDidChangeListenerHandle?

    /*
     * Initializes the AuthManager
     */
    override private init() {
        // Set the initial state of the user
        isSignedIn = false
        super.init()
        handle = auth.addStateDidChangeListener(authStateChanged)
    }

    /*
     * Logs the user in using Firebase
     */
    func login(credential: AuthCredential, completionBlock: @escaping (_ success: Bool) -> Void) {
        // Sign in with Firebase
        Auth.auth().signIn(with: credential, completion: { _, error in
            // Check for errors
            if error != nil {
                self.appError = ErrorType(error: .loginError)
                print("ERROR logging into Firebase", error!.localizedDescription)
                return
            }

            // User is signed in
            guard let userId = self.auth.currentUser?.uid else { return }

            // Call the completion block
            completionBlock(error == nil)

            // Create the user document
            self.userManager.createUserDoc(auth: self.auth)

            // Bind the user document
            self.userManager.getUser(with: userId)

            // Set the signed in state
            self.isSignedIn = true
        })
    }

    /*
     * Logs the user out
     */
    func setSignOut() {
        isSignedIn = false
        unbindAuth()
        userManager.unbindSnapshot()
    }

    func logout() {
        do {
            if googleAuthMan.googleSignInState == .signedIn {
                // We know Google SSO was used, sign out using Google
                // so that users can login into a different account
                googleAuthMan.signOut()
            }

            if appleAuthManager.appleSignedInStatus == .signedIn {
                appleAuthManager.signOut()
            }

            if fbAuthManager.fbSignedInStatus == .signedIn {
                fbAuthManager.signOut()
            }

            try Auth.auth().signOut()

            setSignOut()

        } catch let error as NSError {
            self.appError = ErrorType(error: .genericError)
            print("Failed to sign out", error)
        }
    }

    private func authStateChanged(with _: Auth, user: User?) {
        if user != nil {
            // User is signed in
            let userId = user!.uid
            userManager.getUser(with: userId)

            isSignedIn = true
        } else {
            setSignOut()
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
