//
//  GoogleAuthManager.swift
//  CapGen
//
//  Created by Kevin Vu on 1/13/23.
//

import Foundation
import Firebase
import GoogleSignIn

enum GoogleSignInState {
    case signedIn
    case signedOut
}

class GoogleAuthManager: ObservableObject {
    // Initialize to auth state
    @Published var googleSignInState: GoogleSignInState = .signedOut
    
    func signOut() {
        if GIDSignIn.sharedInstance.currentUser != nil {
            GIDSignIn.sharedInstance.signOut()
            self.googleSignInState = .signedOut
        }
    }
    
    func signIn() {
        // Check if there’s a previous Sign-In. If yes, then restore it. Otherwise, move on to defining the sign-in process.
        if GIDSignIn.sharedInstance.hasPreviousSignIn() {
            GIDSignIn.sharedInstance.restorePreviousSignIn { [unowned self] user, error in
                authenticateUser(for: user, with: error)
            }
        } else {
            // Get the clientID from Firebase App. It fetches the clientID from the GoogleService-Info.plist
            guard let clientId = FirebaseApp.app()?.options.clientID else { return }
            let configuration = GIDConfiguration(clientID: clientId)
            GIDSignIn.sharedInstance.configuration = configuration
            
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            guard let rootViewController = windowScene.windows.first?.rootViewController else { return }
            
            GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [unowned self] result, error in
                authenticateUser(for: result?.user, with: error)
            }
        }
    }
    
    private func authenticateUser(for user: GIDGoogleUser?, with error: Error?) {
        if let error = error {
            print("Error in authenticating Google user", error.localizedDescription)
            return
        }
        
        guard let `user` = user else { return }
        
        // Get the idToken and accessToken from the user instance.
        guard let accessToken = user.accessToken.tokenString as? String else { return }
        guard let idToken = user.idToken?.tokenString as? String else { return }
        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        
        AuthManager.shared.login(credential: credential) { (success) in
            if (success && GIDSignIn.sharedInstance.currentUser != nil) {
                self.googleSignInState = .signedIn
                print("Google login was a success!")
            }
        }
    }
}
