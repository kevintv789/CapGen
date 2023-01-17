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
    let db = Firestore.firestore()
    
    init() {
        fetchKey()
    }
    
    func fetchKey() {
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
    
    func incrementCredit(for uid: String?) {
        guard let userId = uid else { return }
        
        let docRef = db.collection("Users").document("\(userId)")
        docRef.updateData([
            "credits": FieldValue.increment(Int64(1))
        ])
    }
    
    func decrementCredit(for uid: String?) {
        guard let userId = uid else { return }
        
        let docRef = db.collection("Users").document("\(userId)")
        docRef.updateData([
            "credits": FieldValue.increment(Int64(-1))
        ])
    }
    
}
