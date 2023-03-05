//
//  FirestoreManager.swift
//  CapGen
//
//  Created by Kevin Vu on 1/6/23.
//

import Firebase
import FirebaseFirestoreSwift
import Foundation

class FirestoreManager: ObservableObject {
    @Published var openAiKey: String?
    @Published var appodealAppId: String?
    @Published var appStoreModel: AppStoreModel?
    @Published var appError: ErrorType? = nil

    var snapshotListener: ListenerRegistration?

    let db = Firestore.firestore()

    func fetchKey() {
        fetch(from: "Secrets", documentId: "OpenAI") { data in
            if let data = data {
                self.openAiKey = data["Key"] as? String ?? nil
            }
        }

        fetch(from: "Secrets", documentId: "AppStore") { data in
            if let data = data {
                let appStoreId = data["storeId"] as? String ?? nil
                let website = data["website"] as? String ?? nil
                self.appStoreModel = AppStoreModel(storeId: appStoreId ?? "", website: website ?? "")
            }
        }
    }

    func incrementCredit(for uid: String?) {
        guard let userId = uid else {
            appError = ErrorType(error: .genericError)
            return
        }

        let docRef = db.collection("Users").document("\(userId)")
        docRef.updateData([
            "credits": FieldValue.increment(Int64(1)),
        ])
    }

    func decrementCredit(for uid: String?) {
        guard let userId = uid else {
            appError = ErrorType(error: .genericError)
            return
        }

        let docRef = db.collection("Users").document("\(userId)")
        docRef.updateData([
            "credits": FieldValue.increment(Int64(-1)),
        ])
    }

    func setShowCongratsModal(for uid: String?, to boolValue: Bool) {
        guard let userId = uid else {
            appError = ErrorType(error: .genericError)
            return
        }

        let docRef = db.collection("Users").document("\(userId)")
        docRef.updateData([
            "userPrefs.showCongratsModal": boolValue,
        ])
    }

    func setShowCreditDepletedModal(for uid: String?, to boolValue: Bool) {
        guard let userId = uid else {
            appError = ErrorType(error: .genericError)
            return
        }

        let docRef = db.collection("Users").document("\(userId)")
        docRef.updateData([
            "userPrefs.showCreditDepletedModal": boolValue,
        ])
    }

    @MainActor
    func saveCaptions(for uid: String?, with captions: AIRequest, captionsGroup: [AIRequest], completion: @escaping () -> Void) async {
        guard let userId = uid else {
            appError = ErrorType(error: .genericError)
            return
        }

        let docRef = db.collection("Users").document("\(userId)")

        if !captionsGroup.isEmpty {
            // Update array with new item
            let indexOfGroup = captionsGroup.firstIndex { $0.id == captions.id }
            if indexOfGroup != nil {
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
    func onCaptionsGroupDelete(for uid: String?, element: AIRequest, captionsGroup: [AIRequest], onComplete: () -> Void) {
        guard let userId = uid else {
            appError = ErrorType(error: .genericError)
            return
        }

        let docRef = db.collection("Users").document("\(userId)")

        if !captionsGroup.isEmpty {
            let indexOfGroup = captionsGroup.firstIndex { $0.id == element.id }
            if indexOfGroup != nil {
                docRef.updateData(["captionsGroup": FieldValue.arrayRemove([captionsGroup[indexOfGroup!].dictionary])])
            }
        }
        
        onComplete()
    }

    func getCaptionsCount(using captionsGroup: [AIRequest]) -> Int {
        var count = 0
        captionsGroup.forEach { group in
            count += group.captions.count
        }

        return count
    }

    /**
     This function creates a new folder by checking if a folders data field array already exists
     - If exist, add onto the array with a union call
     - If does not exist, then create a folders data field array
     */
    func saveFolder(for uid: String?, folder: FolderModel, onComplete: @escaping () -> Void) {
        guard let userId = uid else {
            appError = ErrorType(error: .genericError)
            onComplete()
            return
        }

        let docRef = db.collection("Users").document("\(userId)")

        docRef.getDocument { doc, error in
            if error != nil {
                self.appError = ErrorType(error: .genericError)
                print("Error within saveFolder()")
                return
            }

            if let doc = doc, doc.exists {
                let data = doc.data()
                // Determine if folders array already exists
                if let foldersUncoded = data?["folders"] as? [[String: AnyObject]] {
                    if !foldersUncoded.isEmpty {
                        // folders array already exist, add onto array
                        docRef.updateData(["folders": FieldValue.arrayUnion([folder.dictionary])])
                        onComplete()
                        return
                    }
                }

                // Create new data field since it does not exist
                docRef.setData(["folders": [folder.dictionary]], merge: true)
                onComplete()
                return
            }
        }
    }

    /**
     This function update an existing folder by
     - Retrieving it from the current array
     - Removing that item
     - Adding in a new item with a different ID and same date created
     */
    @MainActor
    func updateFolder(for uid: String?, newFolder: FolderModel, currentFolders: [FolderModel], onComplete: @escaping (_ updatedFolder: FolderModel?) -> Void) async {
        guard let userId = uid else {
            appError = ErrorType(error: .genericError)
            onComplete(nil)
            return
        }

        if !currentFolders.isEmpty {
            let docRef = db.collection("Users").document("\(userId)")

            // Update array with new item
            let indexOfFolder = currentFolders.firstIndex { $0.id == newFolder.id }

            if indexOfFolder != nil {
                // Create a new folder with a different ID and date created
                // The ID needs to be different to avoid intermittent issues with ForEach reading from the same ID
                let updatedFolder = FolderModel(id: UUID().uuidString, name: newFolder.name, dateCreated: currentFolders[indexOfFolder!].dateCreated, folderType: newFolder.folderType, captions: newFolder.captions)

                // Remove current folder
                do {
                    try await docRef.updateData(["folders": FieldValue.arrayRemove([currentFolders[indexOfFolder!].dictionary])])
                } catch {
                    print("Error on deleting folders - updateFolder()")
                    appError = ErrorType(error: .genericError)
                    onComplete(nil)
                    return
                }

                // Adding updated folder onto the existing data field
                do {
                    try await docRef.updateData(["folders": FieldValue.arrayUnion([updatedFolder.dictionary])])
                    onComplete(updatedFolder)
                } catch {
                    print("Error on adding folders")
                    appError = ErrorType(error: .genericError)
                    onComplete(nil)
                    return
                }
            }
        }
    }

    /**
     This function deletes a folder by
     - Retrieving it from the current array
     - Removing that item
     */
    func onFolderDelete(for uid: String?, curFolder: FolderModel, currentFolders: [FolderModel], onComplete: @escaping () -> Void) async {
        guard let userId = uid else {
            appError = ErrorType(error: .genericError)
            onComplete()
            return
        }

        let docRef = db.collection("Users").document("\(userId)")

        if !currentFolders.isEmpty {
            // Find the folder to be deleted
            let indexOfFolder = currentFolders.firstIndex { $0.id == curFolder.id }

            // Remove current folder
            do {
                try await docRef.updateData(["folders": FieldValue.arrayRemove([currentFolders[indexOfFolder!].dictionary])])
            } catch {
                print("Error on deleting folders - onFolderDelete()")
                appError = ErrorType(error: .genericError)
                return
            }
        }
        onComplete()
    }

    private func fetch(from collection: String, documentId: String, completion: @escaping (_ data: [String: Any]?) -> Void) {
        let docRef = db.collection(collection).document(documentId)

        snapshotListener = docRef.addSnapshotListener { documentSnapshot, error in
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
        snapshotListener?.remove()
    }
}
