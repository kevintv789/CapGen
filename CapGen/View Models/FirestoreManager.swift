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
    @Published var captionsGroup: [AIRequest] = []
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
    
    func saveCaptions(for uid: String?, with captions: AIRequest, completion: @escaping () -> Void) {
        guard let userId = uid else { return }
        
        let docRef = db.collection("Users").document("\(userId)")
        
        self.hasCaptions(for: userId) { captionsGroup in
            if (captionsGroup != nil) {
                // Update array with new item
                docRef.updateData(["captionsGroup": FieldValue.arrayUnion([captions.dictionary])])
            } else {
                // Create new data field
                docRef.setData(["captionsGroup": [captions.dictionary]], merge: true)
            }
            
            completion()
        }
    }
    
    func hasCaptions(for uid: String?, completion: @escaping (_ captionsGroup: [[ String: AnyObject ]]?) -> Void) {
        guard let userId = uid else { return }
        let docRef = db.collection("Users").document("\(userId)")
        
        docRef.getDocument { (document, error) in
            if error != nil {
                print("Can't search captions for user", userId, error!.localizedDescription)
                return
            }
            
            if let document = document, document.exists {
                let data = document.data()
                if let data = data {
                    guard data["captionsGroup"] != nil else {
                        // No captions exist
                        completion(nil)
                        return
                    }
                    
                    completion(data["captionsGroup"] as? [[ String: AnyObject ]])
                    return
                }
            }
        }
    }
    
    func getAllCaptions(for uid: String?, completion: @escaping (_ isDone: Bool) -> Void) {
        guard let userId = uid else { return }
        
        self.hasCaptions(for: userId) { captionsGroup in
            if (captionsGroup == nil) {
                print("No captions to retrieve")
                completion(true)
                return
            }
            
            captionsGroup?.forEach({ element in
                let captionLength = element["captionLength"] as! String
                let captionsDict = element["captions"] as? [[ String: AnyObject ]]
                let dateCreated = element["dateCreated"] as! String
                let id = element["id"] as! String
                let includeEmojis = element["includeEmojis"] as! Bool
                let includeHashtags = element["includeHashtags"] as! Bool
                let platform = element["platform"] as! String
                let prompt = element["prompt"] as! String
                let title = element["title"] as! String
                let tone = element["tone"] as! String
                
                var captions: [GeneratedCaptions] = []
                captionsDict?.forEach { ele in
                    let captionsId = ele["id"] as! String
                    let description = ele["description"] as! String
                    
                    let parsedCaptions = GeneratedCaptions(id: captionsId, description: description)
                    captions.append(parsedCaptions)
                }
                
                let parsedCaptionsGroup = AIRequest(id: id, platform: platform, prompt: prompt, tone: tone, includeEmojis: includeEmojis, includeHashtags: includeHashtags, captionLength: captionLength, title: title, dateCreated: dateCreated, captions: captions)
                
                self.captionsGroup.append(parsedCaptionsGroup)
            })
            
            // Sort date by most recent
            self.captionsGroup.sort(by: { $0.dateCreated > $1.dateCreated })
            
            completion(true)
            
        }
    }
    
}
