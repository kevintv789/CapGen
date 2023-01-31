//
//  FacebookLoginManager.swift
//  CapGen
//
//  Created by Kevin Vu on 1/13/23.
//

import Foundation
import FacebookLogin
import FacebookCore
import UIKit
import FirebaseAuth
import FBSDKCoreKit

enum FBSignedInStatus {
    case signedOut, signedIn
}

class FBAuthManager: ObservableObject {
    @Published var fbSignedInStatus: FBSignedInStatus = .signedOut
    let loginManager = LoginManager()
    
    func login() {
        let permissions: [String] = ["public_profile", "email"]
        
        loginManager.logIn(permissions: permissions, from: nil) {  (result, error)  in
            if (error != nil) {
                print("Failed to login using Facebook", error ?? "nil")
                return
            }
            
            guard let response = result else {
                print("Failed to display result when using Facebook login")
                return
            }
            
            if (response.isCancelled) {
                print("User cancelled Facebook Authentication")
                return
            }
            
            if (response.token != nil) {
                self.authenticateWithFirebase(accessToken: response.token!)
            }
        }
    }
    
    func authenticateWithFirebase(accessToken: AccessToken) {
        if let accessToken = AccessToken.current {
            AuthManager.shared.login(credential: FacebookAuthProvider.credential(withAccessToken: accessToken.tokenString)) { success in
                if (success && AccessToken.isCurrentAccessTokenActive) {
                    self.fbSignedInStatus = .signedIn
                    print("Facebook login successful!")
                }
            }
        }
    }
    
    func getFBProfile(completion: @escaping (_ fbUser: [String: Any]?) -> Void) {
        GraphRequest(graphPath: "me", parameters: ["fields":"name, email"]).start { (connection, result, error) in
            if error != nil {
                print("ERROR retrieving FB profile", error!.localizedDescription)
                return
            }
            
            guard let userDict = result as? [String:Any] else { return }
            
            completion(userDict)
        }
    }
    
    func signOut() {
        if AccessToken.isCurrentAccessTokenActive {
            self.loginManager.logOut()
            self.fbSignedInStatus = .signedOut
        }
    }
}
