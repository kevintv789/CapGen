//
//  UserManager.swift
//  CapGen
//
//  Created by Kevin Vu on 1/16/23.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation
import GoogleSignIn

class UserManager: ObservableObject {
    @Published var user: UserModel?
    var collection = Firestore.firestore().collection("Users")
    var snapshotListener: ListenerRegistration?

    func createUserDoc(auth: Auth) {
        guard let uid = auth.currentUser?.uid else { return }
        checkIfUserExist(uid: uid) { doesExist in
            // Only create new user document if they don't already exist in the 'Users' collection
            if !doesExist {
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

    func checkIfUserExist(uid: String, completion: @escaping (_ exists: Bool) -> Void) {
        let docRef = collection.document("\(uid)")

        docRef.getDocument { document, error in
            if error != nil {
                print("Failed to check if user \(uid) exists", error!.localizedDescription)
                completion(false)
            } else if let document = document, document.exists {
                completion(true)
            } else {
                completion(false)
            }
        }
    }

    func getUser(with uid: String) {
        let docRef = collection.document("\(uid)")

        snapshotListener = docRef.addSnapshotListener { snapshot, error in
            if error != nil {
                print("ERROR in fetching user \(uid)", error!.localizedDescription)
                return
            }

            let fullName: String = snapshot?.get("fullName") as? String ?? "user"
            let credits: Int = snapshot?.get("credits") as? Int ?? 0
            let email: String = snapshot?.get("email") as? String ?? "N/A"
            let userPrefsDict = snapshot?.get("userPrefs") as? [String: Any]
            let dateCreatedTimestamp = snapshot?.get("dateCreated") as? Timestamp ?? nil
            let folders = self.convertFolderModel(for: snapshot?.get("folders") as? [[String: AnyObject]] ?? nil)

            guard let dateCreated = dateCreatedTimestamp?.dateValue() else { return }

            // uses the Firestore.Decoder to decode the dictionary into the UserPreferences struct and finally assign the userPref value to the UserModel.
            if let userPrefsDict = userPrefsDict {
                let decoder = Firestore.Decoder()
                let userPref = try? decoder.decode(UserPreferences.self, from: userPrefsDict)

                if userPref != nil {
                    self.user = UserModel(id: uid, fullName: fullName, credits: credits, email: email, userPrefs: userPref!, dateCreated: dateCreated, folders: folders)
                }
            }
        }
    }

    func deleteUser(completion: @escaping (_ error: ErrorType?) -> Void) {
        let user = Auth.auth().currentUser

        guard let user = user else {
            completion(ErrorType(error: .genericError))
            return
        }

        // Delete firestore data
        let docRef = collection.document("\(user.uid)")
        docRef.delete { error in
            if let error = error {
                completion(ErrorType(error: .genericError))
                print("Error in deleting user from firestore", error.localizedDescription)
            } else {
                if AuthManager.shared.googleAuthMan.googleSignInState == .signedIn {
                    AuthManager.shared.googleAuthMan.signOut()
                }

                if AuthManager.shared.fbAuthManager.fbSignedInStatus == .signedIn {
                    AuthManager.shared.fbAuthManager.signOut()
                }

                if AuthManager.shared.appleAuthManager.appleSignedInStatus == .signedIn {
                    AuthManager.shared.appleAuthManager.signOut()
                }

                user.delete { error in
                    if let error = error {
                        completion(ErrorType(error: .genericError))
                        print("Error in deleting user", error.localizedDescription)
                    }
                    // Account has been deleted
                    AuthManager.shared.setSignOut()
                    completion(nil)
                }
            }
        }
    }

    private func convertFolderModel(for folders: [[String: AnyObject]]?) -> [FolderModel] {
        guard let folders = folders else { return [] }

        var result: [FolderModel] = []

        folders.forEach { folder in
            let id = folder["id"] as! String
            let name = folder["name"] as! String
            let dateCreated = folder["dateCreated"] as! String
            let folderType = folder["folderType"] as! String
            let captions = Utils.convertGeneratedCaptions(for: folder["captions"] as? [[String: AnyObject]])
            let index = folder["index"] as! Int

            let mappedFolder = FolderModel(id: id, name: name, dateCreated: dateCreated, folderType: FolderType(rawValue: folderType)!, captions: captions, index: index)
            result.append(mappedFolder)
        }

        // returns a list of folders that is sorted by largest caption count first
        return result.sorted { f1, f2 in
            f1.captions.count > f2.captions.count
        }
    }

    private func createGoogleUser(uid: String, credit: Int, usersPref: UserPreferences, dateCreated: Date) {
        if AuthManager.shared.googleAuthMan.googleSignInState == .signedIn {
            guard let googleUser = GIDSignIn.sharedInstance.currentUser else { return }

            let fullName = googleUser.profile?.name ?? "user"
            let email = googleUser.profile?.email ?? "N/A"

            let userModel = UserModel(id: uid, fullName: fullName, credits: credit, email: email, userPrefs: usersPref, dateCreated: dateCreated)

            setUserDocumentRef(with: uid, userModel: userModel)
        }
    }

    private func createFbUser(uid: String, credit: Int, usersPref: UserPreferences, dateCreated: Date) {
        let fbManager = AuthManager.shared.fbAuthManager

        if fbManager.fbSignedInStatus == .signedIn {
            fbManager.getFBProfile { fbUser in
                guard let user = fbUser else { return }

                let name = user["name"] as? String ?? "user"
                let email = user["email"] as? String ?? "N/A"

                let userModel = UserModel(id: uid, fullName: name, credits: credit, email: email, userPrefs: usersPref, dateCreated: dateCreated)

                self.setUserDocumentRef(with: uid, userModel: userModel)
            }
        }
    }

    private func createAppleUser(uid: String, credit: Int, usersPref: UserPreferences, dateCreated: Date) {
        let appleAuthManager = AuthManager.shared.appleAuthManager

        if appleAuthManager.appleSignedInStatus == .signedIn {
            guard let fullName = appleAuthManager.fullName else { return }
            guard var email = appleAuthManager.email else { return }

            if email == "N/A" {
                email = Auth.auth().currentUser?.email ?? "N/A"
            }

            let userModel = UserModel(id: uid, fullName: fullName, credits: credit, email: email, userPrefs: usersPref, dateCreated: dateCreated)

            setUserDocumentRef(with: uid, userModel: userModel)
        }
    }

    private func setUserDocumentRef(with uid: String, userModel: UserModel) {
        do {
            try collection.document(uid).setData(from: userModel)
        } catch {
            print("ERROR when creating SSO user", error.localizedDescription)
        }
    }

    func unbindSnapshot() {
        snapshotListener?.remove()
    }
}
