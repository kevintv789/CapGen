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
    func updateFolder(for uid: String?, newFolder: FolderModel, currentFolders: [FolderModel], onComplete: @escaping (_ updatedFolder: FolderModel?) -> Void) {
        guard let userId = uid else {
            appError = ErrorType(error: .genericError)
            onComplete(nil)
            return
        }

        if !currentFolders.isEmpty {
            let newFolderId: String = UUID().uuidString
            let docRef = db.collection("Users").document("\(userId)")

            // Update array with new item
            if let indexOfFolder = currentFolders.firstIndex(where: { $0.id == newFolder.id }) {
                // Create a new folder with a different ID and date created
                // The ID needs to be different to avoid intermittent issues with ForEach reading from the same ID

                var updatedCaptions: [CaptionModel] = []
                newFolder.captions.forEach { caption in
                    let updatedCaption = CaptionModel(id: caption.id, captionLength: caption.captionLength, dateCreated: caption.dateCreated, captionDescription: caption.captionDescription, includeEmojis: caption.includeEmojis, includeHashtags: caption.includeHashtags, folderId: newFolderId, prompt: caption.prompt, title: caption.title, tones: caption.tones, color: caption.color, index: caption.index)

                    updatedCaptions.append(updatedCaption)
                }

                let updatedFolder = FolderModel(id: newFolderId, name: newFolder.name, dateCreated: currentFolders[indexOfFolder].dateCreated, folderType: newFolder.folderType, captions: updatedCaptions, index: newFolder.index)

                // Remove at current folder
                var mutableFolders = currentFolders
                mutableFolders.remove(at: indexOfFolder)

                // Add in updated folder
                mutableFolders.append(updatedFolder)

                // Remove all current folders
                deleteAllFolders(for: docRef) {
                    // Adding updated folder onto the existing data field
                    self.addNewFolders(for: docRef, updatedFolders: mutableFolders) {
                        onComplete(updatedFolder)
                    }
                }
            }
        }
    }

    /**
     This function deletes a folder by
     - Removing entire folders array from the DB
     - Remove the particular folder from the original array in memory
     - Write back to DB with the mutated array with the removed folder
     */
    func onFolderDelete(for uid: String?, curFolder: FolderModel, currentFolders: [FolderModel], onComplete: @escaping () -> Void) {
        guard let userId = uid else {
            appError = ErrorType(error: .genericError)
            onComplete()
            return
        }

        let docRef: DocumentReference = db.collection("Users").document("\(userId)")

        if !currentFolders.isEmpty {
            // Find the folder to be deleted
            if let indexOfFolder = currentFolders.firstIndex(where: { $0.id == curFolder.id }) {
                // Remove current folder
                var mutableCurrentFolders = currentFolders
                mutableCurrentFolders.remove(at: indexOfFolder)

                // delete entire folders array
                deleteAllFolders(for: docRef) {
                    // Write back to Firebase the modified folders array with the specific folder removed
                    self.addNewFolders(for: docRef, updatedFolders: mutableCurrentFolders) {
                        onComplete()
                    }
                }
            }
        }
    }

    /**
     This function saves the captions to the folders within the CaptionOptimizationBottomSheetView
     1. Retrieve the current folders
     2. Find the folder to be updated
     3. Remove all folders that were selected from the current folders list
     4. Update all removed folders in memory with updated caption
     5. Delete all folder from DB and add in the new updated array list
     */
    func saveCaptionsToFolders(for uid: String?, destinationFolders: [DestinationFolder], onComplete: @escaping () -> Void) {
        guard let userId = uid else {
            appError = ErrorType(error: .genericError)
            onComplete()
            return
        }

        let docRef: DocumentReference = db.collection("Users").document("\(userId)")

        // Get current folders from the user document
        var currentFolders = AuthManager.shared.userManager.user?.folders ?? []

        // destinationFolders -- are the folders that will have new captions saved to it
        if !destinationFolders.isEmpty {
            // do a loop on each folder to retrieve necessities
            destinationFolders.forEach { folder in

                // sets a new folder ID to associate updated folders and captions with
                let newFolderId: String = UUID().uuidString

                // retrieve the caption to be saved to be updated within the updated folder
                var captionToSave = folder.caption as CaptionModel
                captionToSave.folderId = newFolderId
                captionToSave.id = UUID().uuidString // generate a new ID for all new captions being saved

                // Delete original folder from the current folders
                if let indexOfOriginalFolder = currentFolders.firstIndex(where: { $0.id == folder.id }) {
                    let designatedFolder = currentFolders.remove(at: indexOfOriginalFolder)

                    var updatedCaptions: [CaptionModel] = []

                    // Update all current captions to the new folder Id and caption ID
                    designatedFolder.captions.forEach { caption in
                        let updatedCaption = CaptionModel(id: UUID().uuidString, captionLength: caption.captionLength, dateCreated: caption.dateCreated, captionDescription: caption.captionDescription, includeEmojis: caption.includeEmojis, includeHashtags: caption.includeHashtags, folderId: newFolderId, prompt: caption.prompt, title: caption.title, tones: caption.tones, color: caption.color, index: caption.index)

                        updatedCaptions.append(updatedCaption)
                    }

                    // append the caption that needs to be saved
                    updatedCaptions.append(captionToSave)

                    // create a new folder object with the updated caption and ID
                    let updatedFolder = FolderModel(id: newFolderId, name: designatedFolder.name, dateCreated: designatedFolder.dateCreated, folderType: designatedFolder.folderType, captions: updatedCaptions, index: designatedFolder.index)

                    // append new updated folder
                    currentFolders.append(updatedFolder)
                }
            }
        }

        // Create a dispatch group to keep everything synchronous
        // FB must delete all folders and then add new folders before the view gets updated
        // otherwise we run into duplicate keys issues
        let dispatchGroup = DispatchGroup()

        dispatchGroup.enter()

        deleteAllFolders(for: docRef) {
            self.addNewFolders(for: docRef, updatedFolders: currentFolders) {
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            onComplete()
        }
    }

    /**
     This function updates a caption within a specific folder. This will most likely be ran from within the CaptionListView or FolderView.
     */
    @MainActor
    func updateSingleCaptionInFolder(for uid: String?, currentCaption: CaptionModel, onComplete: @escaping (_ updatedFolder: FolderModel?) -> Void) async {
        guard let userId = uid else {
            appError = ErrorType(error: .genericError)
            onComplete(nil)
            return
        }

        // Get current folders from the user document
        var currentFolders = AuthManager.shared.userManager.user?.folders ?? []

        var updatedFolder: FolderModel = .init()

        let docRef: DocumentReference = db.collection("Users").document("\(userId)")

        if !currentFolders.isEmpty {
            let newFolderId: String = UUID().uuidString

            // Find folder to be updated from Firebase
            if let designatedFolderIndex = currentFolders.firstIndex(where: { $0.id == currentCaption.folderId }) {
                // Remove old folder, but keep a reference to it
                let designatedFolder = currentFolders.remove(at: designatedFolderIndex)

                var updatedCaptions: [CaptionModel] = []

                // Update all current captions to the new folder Id
                designatedFolder.captions.forEach { caption in
                    var updatedCaption = CaptionModel(id: caption.id, captionLength: caption.captionLength, dateCreated: caption.dateCreated, captionDescription: caption.captionDescription, includeEmojis: caption.includeEmojis, includeHashtags: caption.includeHashtags, folderId: newFolderId, prompt: caption.prompt, title: caption.title, tones: caption.tones, color: caption.color, index: caption.index)

                    // Since we are updating a particular caption
                    // we must find the updated caption, replace it from this list
                    // so the list can be updated with the new description
                    if updatedCaption.id == currentCaption.id {
                        updatedCaption.captionDescription = currentCaption.captionDescription
                    }

                    updatedCaptions.append(updatedCaption)
                }

                // create a new folder object with the updated caption and ID
                updatedFolder = FolderModel(id: newFolderId, name: designatedFolder.name, dateCreated: designatedFolder.dateCreated, folderType: designatedFolder.folderType, captions: updatedCaptions, index: designatedFolder.index)

                // append new updated folder
                currentFolders.append(updatedFolder)

                await deleteAllFoldersAsync(for: docRef)
                await addNewFoldersAsync(for: docRef, updatedFolders: currentFolders)

                onComplete(updatedFolder)
            }
        }
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

    private func deleteAllFolders(for docRef: DocumentReference, onComplete: @escaping () -> Void) {
        // delete entire folders array
        docRef.updateData(["folders": FieldValue.delete()])
        onComplete()
    }

    private func addNewFolders(for docRef: DocumentReference, updatedFolders: [FolderModel], onComplete: @escaping () -> Void) {
        // Write back to Firebase the modified folders array with the specific folder removed
        docRef.setData(["folders": updatedFolders.map { $0.dictionary }], merge: true)
        onComplete()
    }

    private func deleteAllFoldersAsync(for docRef: DocumentReference) async {
        // delete entire folders array
        do {
            try await docRef.updateData(["folders": FieldValue.delete()])
        } catch {
            print("ERROR cannot delete all folders", error)
            appError = ErrorType(error: .genericError)
            return
        }
    }

    private func addNewFoldersAsync(for docRef: DocumentReference, updatedFolders: [FolderModel]) async {
        // Write back to Firebase the modified folders array with the specific folder removed
        do {
            try await docRef.setData(["folders": updatedFolders.map { $0.dictionary }], merge: true)
        } catch {
            print("ERROR cannot add folders", error)
            appError = ErrorType(error: .genericError)
            return
        }
    }

    func unbindListener() async {
        snapshotListener?.remove()
    }
}
