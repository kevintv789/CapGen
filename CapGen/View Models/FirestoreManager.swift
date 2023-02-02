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
    @Published var admobUnitId: String?
    @Published var appStoreModel: AppStoreModel?
    @Published var appError: ErrorType? = nil
    
    var snapshotListener: ListenerRegistration? = nil
    
    let db = Firestore.firestore()
    
    func fetchKey() {
        self.fetch(from: "Secrets", documentId: "OpenAI") { data in
            if let data = data {
                self.openAiKey = data["Key"] as? String ?? nil
            }
        }
        
        self.fetch(from: "Secrets", documentId: "Admob") { data in
            if let data = data {
                self.admobUnitId = data["ADMOB_REWARDED_AD_UNIT_ID"] as? String ?? nil
            }
        }
        
        self.fetch(from: "Secrets", documentId: "AppStore") { data in
            if let data = data {
                let appStoreId = data["storeId"] as? String ?? nil
                let website = data["website"] as? String ?? nil
                self.appStoreModel = AppStoreModel(storeId: appStoreId ?? "", website: website ?? "")
            }
        }
    }
    
    func incrementCredit(for uid: String?) {
        guard let userId = uid else {
            self.appError = ErrorType(error: .genericError)
            return
        }
        
        let docRef = db.collection("Users").document("\(userId)")
        docRef.updateData([
            "credits": FieldValue.increment(Int64(1))
        ])
    }
    
    func decrementCredit(for uid: String?) {
        guard let userId = uid else {
            self.appError = ErrorType(error: .genericError)
            return
        }
        
        let docRef = db.collection("Users").document("\(userId)")
        docRef.updateData([
            "credits": FieldValue.increment(Int64(-1))
        ])
    }
    
    func setShowCongratsModal(for uid: String?, to boolValue: Bool) {
        guard let userId = uid else {
            self.appError = ErrorType(error: .genericError)
            return
        }
        
        let docRef = db.collection("Users").document("\(userId)")
        docRef.updateData([
            "userPrefs.showCongratsModal": boolValue
        ])
    }
    
    func setShowCreditDepletedModal(for uid: String?, to boolValue: Bool) {
        guard let userId = uid else {
            self.appError = ErrorType(error: .genericError)
            return
        }
        
        let docRef = db.collection("Users").document("\(userId)")
        docRef.updateData([
            "userPrefs.showCreditDepletedModal": boolValue
        ])
    }
    
    @MainActor
    func saveCaptions(for uid: String?, with captions: AIRequest, captionsGroup: [AIRequest], completion: @escaping () -> Void) async {
        guard let userId = uid else {
            self.appError = ErrorType(error: .genericError)
            return
        }
        
        let docRef = db.collection("Users").document("\(userId)")
        
        if (!captionsGroup.isEmpty) {
            // Update array with new item
            let indexOfGroup = captionsGroup.firstIndex{ $0.id == captions.id }
            if (indexOfGroup != nil) {
                // Update a specific item in the array by removing it first
                do {
                    try await docRef.updateData(["captionsGroup": FieldValue.arrayRemove([captionsGroup[indexOfGroup!].dictionary])])
                } catch {
                    print("ERROR")
                }
                
            }
            
            // Change UUID
            let newCaption = AIRequest(id: UUID().uuidString, platform: captions.platform, prompt: captions.prompt, tones: captions.tones, includeEmojis: captions.includeEmojis, includeHashtags: captions.includeHashtags, captionLength: captions.captionLength, title: captions.title, dateCreated: captions.dateCreated, captions: captions.captions)
            
            // Add new entry
            do {
                try await docRef.updateData(["captionsGroup": FieldValue.arrayUnion([newCaption.dictionary])])
            } catch {
                print("ERROR")
            }
            
        } else {
            do {
                // Create new data field
                try await docRef.setData(["captionsGroup": [captions.dictionary]], merge: true)
            } catch {
                print("ERROR")
            }
        }
        
        completion()
    }
    
    /**
        This function deletes the specific caption group
     */
    func onCaptionsGroupDelete(for uid: String?, element: AIRequest, captionsGroup: [AIRequest]) {
        guard let userId = uid else {
            self.appError = ErrorType(error: .genericError)
            return
        }
        
        let docRef = db.collection("Users").document("\(userId)")
        
        if (!captionsGroup.isEmpty) {
            let indexOfGroup = captionsGroup.firstIndex{ $0.id == element.id }
            if (indexOfGroup != nil) {
                docRef.updateData(["captionsGroup": FieldValue.arrayRemove([captionsGroup[indexOfGroup!].dictionary])])
            }
            
        }
    }
    
    func getCaptionsCount(using captionsGroup: [AIRequest]) -> Int {
        var count = 0
        captionsGroup.forEach { group in
            count += group.captions.count
        }
        
        return count
    }
    
    private func fetch(from collection: String, documentId: String, completion: @escaping (_ data: [String: Any]?) -> Void) {
        let docRef = db.collection(collection).document(documentId)
        
        self.snapshotListener = docRef.addSnapshotListener { (documentSnapshot, error) in
            if error != nil {
                self.appError = ErrorType(error: .genericError)
                print("Can't retrieve \(collection) \(documentId)", error!.localizedDescription)
                completion(nil)
                return
            }
            
            if let document = documentSnapshot, document.exists {
                let data = document.data()
                if let data = data {
                    completion(data)
                }
            }
        }
    }
    
    func unbindListener() async {
        self.snapshotListener?.remove()
    }
}
