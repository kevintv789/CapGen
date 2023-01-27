//
//  UserManager.swift
//  CapGen
//
//  Created by Kevin Vu on 1/16/23.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn

class UserManager: ObservableObject {
    @Published var user: UserModel?
    var collection = Firestore.firestore().collection("Users")
    
    func createUserDoc(auth: Auth) {
        guard let uid = auth.currentUser?.uid else { return }
        checkIfUserExist(uid: uid) { doesExist in
            // Only create new user document if they don't already exist in the 'Users' collection
            if (!doesExist) {
                let usersPref = UserPreferences(showCongratsModal: true, showCreditDepletedModal: true)
                let dateCreated = Date.now
                let credit = 1
                
                // Create from Apple SSO
                self.createAppleUser(uid: uid, credit: credit, usersPref: usersPref, dateCreated: dateCreated)
                
                // Create from FB SSO
                self.createFbUser(uid: uid, credit: credit, usersPref: usersPref, dateCreated: dateCreated)
                
                // Create from a Google SSO sign in in
                self.createGoogleUser(uid: uid, credit: credit, usersPref: usersPref, dateCreated: dateCreated)
            }
        }
    }
    
    func checkIfUserExist(uid: String, completion: @escaping (_ exists: Bool) -> ()) {
        let docRef = self.collection.document("\(uid)")
        
        docRef.getDocument { document, error in
            if error != nil {
                print("Failed to check if user \(uid) exists", error!.localizedDescription)
                completion(false)
            }
            else if let document = document, document.exists {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    func getUser(with uid: String) {
        let docRef = self.collection.document("\(uid)")
        
        docRef.addSnapshotListener { snapshot, error in
            if (error != nil) {
                print("ERROR in fetching user \(uid)", error!.localizedDescription)
                return
            }
            
            let fullName: String = snapshot?.get("fullName") as? String ?? "user"
            let credits: Int = snapshot?.get("credits") as? Int ?? 0
            let email: String = snapshot?.get("email") as? String ?? "N/A"
            let userPrefsDict = snapshot?.get("userPrefs") as? [String: Any]
            let dateCreatedTimestamp = snapshot?.get("dateCreated") as? Timestamp ?? nil
            let captionsGroup = self.convertCaptionGroup(for: snapshot?.get("captionsGroup") as? [[ String: AnyObject ]] ?? nil)
            
            guard let dateCreated = dateCreatedTimestamp?.dateValue() else { return }
            
            // uses the Firestore.Decoder to decode the dictionary into the UserPreferences struct and finally assign the userPref value to the UserModel.
            if let userPrefsDict = userPrefsDict {
                let decoder = Firestore.Decoder()
                let userPref = try? decoder.decode(UserPreferences.self, from: userPrefsDict)
                
                if userPref != nil {
                    self.user = UserModel(id: uid, fullName: fullName, credits: credits, email: email, userPrefs: userPref!, dateCreated: dateCreated, captionsGroup: captionsGroup)
                }
            }
        }
    }
    
    /**
     This function converts the group of captions within Firebase to a readable/Swift format so data can be read and retrieved
     */
    private func convertCaptionGroup(for captionsGroup: [[ String: AnyObject ]]?) -> [AIRequest] {
        guard let captionsGroup = captionsGroup else { return [] }
        
        var result: [AIRequest] = []
        
        captionsGroup.forEach({ element in
            let captionLength = element["captionLength"] as! String
            let captionsDict = element["captions"] as? [[ String: AnyObject ]]
            let dateCreated = element["dateCreated"] as! String
            let id = element["id"] as! String
            let includeEmojis = element["includeEmojis"] as! Bool
            let includeHashtags = element["includeHashtags"] as! Bool
            let platform = element["platform"] as! String
            let prompt = element["prompt"] as! String
            let title = element["title"] as! String
            let tonesDict = element["tones"] as? [[ String: AnyObject ]] ?? []
            
            var captions: [GeneratedCaptions] = []
            captionsDict?.forEach { ele in
                let captionsId = ele["id"] as! String
                let description = ele["description"] as! String
                
                let parsedCaptions = GeneratedCaptions(id: captionsId, description: description)
                captions.append(parsedCaptions)
            }
            
            var tones: [ToneModel] = []
            tonesDict.forEach { ele in
                let tone = ToneModel(id: ele["id"] as! Int, title: ele["title"] as! String, description: ele["description"] as! String, icon: ele["icon"] as! String)
                tones.append(tone)
            }
            
            let parsedCaptionsGroup = AIRequest(id: id, platform: platform, prompt: prompt, tones: tones, includeEmojis: includeEmojis, includeHashtags: includeHashtags, captionLength: captionLength, title: title, dateCreated: dateCreated, captions: captions)
            
            result.append(parsedCaptionsGroup)
        })
        
        let df = DateFormatter()
        df.dateFormat = "MMM d, h:mm a"
        result.sort(by: { df.date(from: $0.dateCreated)!.compare(df.date(from: $1.dateCreated)!) == .orderedDescending})
        
        return result
    }
    
    private func createGoogleUser(uid: String, credit: Int, usersPref: UserPreferences, dateCreated: Date) {
        if (AuthManager.shared.googleAuthMan.googleSignInState == .signedIn) {
            guard let googleUser = GIDSignIn.sharedInstance.currentUser else { return }
            
            let fullName = googleUser.profile?.name ?? "user"
            let email = googleUser.profile?.email ?? "N/A"
            
            let userModel = UserModel(id: uid, fullName: fullName, credits: credit, email: email, userPrefs: usersPref, dateCreated: dateCreated)
            
            self.setUserDocumentRef(with: uid, userModel: userModel)
            
        }
    }
    
    private func createFbUser(uid: String, credit: Int, usersPref: UserPreferences, dateCreated: Date) {
        let fbManager = AuthManager.shared.fbAuthManager
        
        if (fbManager.fbSignedInStatus == .signedIn) {
            fbManager.getFBProfile { fbUser in
                guard let user = fbUser else { return }
                
                let name  = user["name"] as? String ?? "user"
                let email = user["email"] as? String ?? "N/A"
                
                let userModel = UserModel(id: uid, fullName: name, credits: credit, email: email, userPrefs: usersPref, dateCreated: dateCreated)
                
                self.setUserDocumentRef(with: uid, userModel: userModel)
            }
        }
    }
    
    private func createAppleUser(uid: String, credit: Int, usersPref: UserPreferences, dateCreated: Date) {
        let appleAuthManager = AuthManager.shared.appleAuthManager
        
        if (appleAuthManager.appleSignedInStatus == .signedIn) {
            guard let fullName = appleAuthManager.fullName else { return }
            guard let email = appleAuthManager.email else { return }
            
            let userModel = UserModel(id: uid, fullName: fullName, credits: credit, email: email, userPrefs: usersPref, dateCreated: dateCreated)
            
            self.setUserDocumentRef(with: uid, userModel: userModel)
        }
    }
    
    private func setUserDocumentRef(with uid: String, userModel: UserModel) {
        do {
            try self.collection.document(uid).setData(from: userModel)
        } catch {
            print("ERROR when creating Google SSO user", error.localizedDescription)
        }
    }
}
