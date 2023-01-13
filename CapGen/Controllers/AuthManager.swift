//
//  AuthManager.swift
//  CapGen
//
//  Created by Kevin Vu on 1/13/23.
//

import Foundation
import Firebase
import FirebaseAuth

class AuthManager {
    
    func login(credential: AuthCredential, completionBlock: @escaping (_ success: Bool) -> Void) {
        Auth.auth().signIn(with: credential, completion: { (user, error) in
            completionBlock(error == nil)
        })
    }
}
