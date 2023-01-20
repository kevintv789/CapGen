//
//  FirestoreManager.swift
//  CapGen
//
//  Created by Kevin Vu on 1/6/23.
//

import Foundation
import Firebase

class FirestoreManager: ObservableObject {
    @Published var openAiKey: String?
    let db = Firestore.firestore()
    
    func fetchKey() {
        let docRef = db.collection("Secrets").document("OpenAI")
        
        docRef.getDocument { (document, error) in
            if error != nil {
                print("Can't retrieve key", error!.localizedDescription)
                return
            }
            
            if let document = document, document.exists {
                let data = document.data()
                if let data = data {
                    self.openAiKey = data["Key"] as? String ?? nil
                    print("Key retrieval success!")
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
    
    func setShowCongratsModal(for uid: String?, to boolValue: Bool) {
        guard let userId = uid else { return }
        
        let docRef = db.collection("Users").document("\(userId)")
        docRef.updateData([
            "userPrefs.showCongratsModal": boolValue
        ])
    }
    
    func setShowCreditDepletedModal(for uid: String?, to boolValue: Bool) {
        guard let userId = uid else { return }
        
        let docRef = db.collection("Users").document("\(userId)")
        docRef.updateData([
            "userPrefs.showCreditDepletedModal": boolValue
        ])
    }
    
    func saveCaptions(for uid: String?, with captions: AIRequest, completion: @escaping (_ isDone: Bool) -> Void) {
        guard let userId = uid else { return }
        
        let docRef = db.collection("Users").document("\(userId)")
        docRef.getDocument { (document, error) in
            if error != nil {
                print("Can't retrieve captions for user", userId, error!.localizedDescription)
                return
            }
            
            if let document = document, document.exists {
                let data = document.data()
                if let data = data {
                    
                    guard data["captionsGroup"] != nil else {
                        print("Creating new captions group...")
                        docRef.setData(["captionsGroup": captions.dictionary], merge: true)
                        completion(true)
                        return
                    }
                    
                    // Update array with new item
                    docRef.updateData(["captionsGroup": FieldValue.arrayUnion([captions.dictionary])])
                    completion(true)
                }
            }
        }
    }
    
}
