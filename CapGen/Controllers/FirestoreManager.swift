//
//  FirestoreManager.swift
//  CapGen
//
//  Created by Kevin Vu on 1/6/23.
//

import Foundation
import Firebase

class FirestoreManager: ObservableObject {
    @Published var openAiKey: String = ""
    
    init() {
        fetchKey()
    }
    
    func fetchKey() {
        let db = Firestore.firestore()
        let docRef = db.collection("Secrets").document("OpenAI")
        
        docRef.getDocument { (document, error) in
            guard error == nil else {
                print("Can't retrieve key", error ?? "")
                return
            }
            
            if let document = document, document.exists {
                let data = document.data()
                if let data = data {
                    self.openAiKey = data["Key"] as? String ?? ""
                }
            }
            
        }
    }
}
