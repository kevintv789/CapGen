//
//  FirestoreManager.swift
//  CapGen
//
//  Created by Kevin Vu on 1/6/23.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

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
    
    func saveCaptions(for uid: String?, with captions: AIRequest, captionsGroup: [AIRequest], completion: @escaping () -> Void) {
        guard let userId = uid else { return }
        
        let docRef = db.collection("Users").document("\(userId)")
        
        if (!captionsGroup.isEmpty) {
            // Update array with new item
            let indexOfGroup = captionsGroup.firstIndex{ $0.id == captions.id }
            if (indexOfGroup != nil) {
                // Update a specific item in the array by removing it first
                docRef.updateData(["captionsGroup": FieldValue.arrayRemove([captionsGroup[indexOfGroup!].dictionary])])
            }
            
            docRef.updateData(["captionsGroup": FieldValue.arrayUnion([captions.dictionary])])
        } else {
            // Create new data field
            docRef.setData(["captionsGroup": [captions.dictionary]], merge: true)
        }
        
        completion()
    }
    
    /**
        This function deletes the specific caption group
     */
    func onCaptionsGroupDelete(for uid: String?, element: AIRequest, captionsGroup: [AIRequest]) {
        guard let userId = uid else { return }
        
        let docRef = db.collection("Users").document("\(userId)")
        
        if (!captionsGroup.isEmpty) {
            let indexOfGroup = captionsGroup.firstIndex{ $0.id == element.id }
            if (indexOfGroup != nil) {
                docRef.updateData(["captionsGroup": FieldValue.arrayRemove([captionsGroup[indexOfGroup!].dictionary])])
            }
            
        }
    }
}
