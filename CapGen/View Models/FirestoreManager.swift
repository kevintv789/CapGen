//
//  FirestoreManager.swift
//  CapGen
//
//  Created by Kevin Vu on 1/6/23.
//

import Firebase
import FirebaseFirestoreSwift
import Foundation
import SwiftUI

class FirestoreManager: ObservableObject {
    @Published var openAiKey: String?
    @Published var appodealAppId: String?
    @Published var appStoreModel: AppStoreModel?
    @Published var appError: ErrorType? = nil
    @Published var googleApiKey: String?

    var snapshotListener: ListenerRegistration?

    let db = Firestore.firestore()
    
    var folderViewModel: FolderViewModel
    
    init(folderViewModel: FolderViewModel) {
        self.folderViewModel = folderViewModel
    }

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

        fetch(from: "Secrets", documentId: "GOOGLE_CLOUD") { data in
            if let data = data {
                self.googleApiKey = data["Key"] as? String ?? nil
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

    func decrementCredit(for uid: String?, value: Int64) {
        guard let userId = uid else {
            appError = ErrorType(error: .genericError)
            return
        }

        let docRef = db.collection("Users").document("\(userId)")
        docRef.updateData([
            "credits": FieldValue.increment(value),
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

    func getCaptionsCount() -> Int {
        var count = 0

        if let user = AuthManager.shared.userManager.user {
            let totalCaptions = user.folders.map { $0.captions }

            totalCaptions.forEach { captions in
                count += captions.count
            }
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
      This function updates an existing folder in the user's folders array by modifying the folder object directly, without relying on its index. It ensures that the folder is updated in memory and in Firebase.

      - Parameters:
        - uid: The user ID for which the folder needs to be updated.
        - newFolder: The new `FolderModel` object containing the updated information for the folder.
        - currentFolders: An `inout` array of the user's current folders. The function will modify this array directly to update the folder.
        - onComplete: A closure that gets called after the function has completed its task. The closure will be passed an optional `FolderModel` object. If the update is successful, it will be the updated folder; otherwise, it will be `nil`.

      - Important:
        The `currentFolders` parameter is marked as `inout`. This means that the function can modify the original array passed to it, and any changes made inside the function will be reflected outside the function as well. When passing an array to an `inout` parameter, you need to use the `&` symbol to pass a reference to the array. For example, when calling this function: `updateFolder(for: userId, newFolder: updatedFolder, currentFolders: &currFolders)`
    */
    func updateFolder(for uid: String?, newFolder: FolderModel, currentFolders: inout [FolderModel], onComplete: @escaping (_ updatedFolder: FolderModel?) -> Void) {
        guard let userId = uid else {
            appError = ErrorType(error: .genericError)
            onComplete(nil)
            return
        }
        
        if !currentFolders.isEmpty {
            let docRef = db.collection("Users").document("\(userId)")

            // Update the folder in memory
            currentFolders = currentFolders.map { folder -> FolderModel in
                if folder.id == newFolder.id {
                    return FolderModel(id: folder.id, name: newFolder.name, dateCreated: folder.dateCreated, folderType: newFolder.folderType, captions: folder.captions, index: newFolder.index)
                } else {
                    return folder
                }
            }

            // Update the folder in Firestore
            docRef.updateData([
                "folders": currentFolders.map { $0.dictionary }
            ]) { error in
                if let error = error {
                    print("Error updating folder: \(error)")
                    onComplete(nil)
                } else {
                    self.folderViewModel.editedFolder = newFolder
                    onComplete(newFolder)
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
    
    // This function saves captions to specified folders
    func saveCaptionsToFolders(for uid: String?, destinationFolders: [DestinationFolder], onComplete: @escaping () -> Void) {
        // Ensure the user ID is not nil, otherwise return an error and call onComplete()
        guard let userId = uid else {
            appError = ErrorType(error: .genericError)
            onComplete()
            return
        }

        // Get the user document reference from the Firestore database
        let userDocRef: DocumentReference = db.collection("Users").document("\(userId)")
        // Retrieve the current folders from the user model
        var currentFolders = AuthManager.shared.userManager.user?.folders ?? []

        // Check if there are any destination folders to save captions to
        if !destinationFolders.isEmpty {
            // Iterate through each destination folder
            destinationFolders.forEach { folder in
                // Generate a new caption ID
                let newCaptionId: String = UUID().uuidString
                // Create a copy of the caption to be saved and assign the new ID
                var captionToSave = folder.caption as CaptionModel
                captionToSave.id = newCaptionId
                // Add the folderId to the caption
                captionToSave.folderId = folder.id

                // Check if the caption length is empty and set it to the default value if needed
                if captionToSave.captionLength.isEmpty {
                    captionToSave.captionLength = captionLengths.first!.type
                }

                // Find the index of the folder in the currentFolders array
                if let folderIndex = currentFolders.firstIndex(where: { $0.id == folder.id }) {
                    // Add the new caption to the existing folder
                    currentFolders[folderIndex].captions.append(captionToSave)

                    // Convert the updated folders to dictionaries
                    let updatedFoldersDictionaries = currentFolders.map { $0.dictionary }

                    // Update the folders in the user document with the updated folders
                    userDocRef.updateData(["folders": updatedFoldersDictionaries]) { error in
                        if let error = error {
                            // Print an error message if the update failed
                            print("Error updating folders: \(error)")
                        } else {
                            // Print a success message if the update succeeded
                            print("Folders successfully updated")
                            self.folderViewModel.folders = currentFolders
                        }
                    }
                }
            }
        }

        // Call onComplete() after the operation is done
        onComplete()
    }
    
    /**
     Updates a single caption within a specific folder.
     
     - Parameter uid: The user's unique identifier (ID).
     - Parameter currentCaption: The updated `CaptionModel` object that needs to be updated within the folder.
     - Parameter onComplete: A closure that gets called when the update operation is complete. It receives an optional `FolderModel` object, which contains the updated folder.
     
     The function will:
     1. Retrieve the current folders from the `User` document.
     2. Find the designated folder containing the caption to be updated.
     3. Update the caption within that folder.
     4. Update the `User` document with the new folder and caption information.
     5. Call the `onComplete` closure with the updated folder.
     */
    func updateSingleCaptionInFolder(for uid: String?, currentCaption: CaptionModel, onComplete: @escaping (_ updatedFolder: FolderModel?) -> Void) {
        guard let userId = uid else {
            appError = ErrorType(error: .genericError)
            onComplete(nil)
            return
        }

        // Get current folders from the user document
        var currentFolders = AuthManager.shared.userManager.user?.folders ?? []

        let docRef: DocumentReference = db.collection("Users").document("\(userId)")

        if !currentFolders.isEmpty {
            // Find folder to be updated from Firebase
            if let designatedFolderIndex = currentFolders.firstIndex(where: { $0.id == currentCaption.folderId }) {
                // Access the designated folder directly
                var designatedFolder = currentFolders[designatedFolderIndex]

                // Find the index of the caption to be updated
                if let captionIndex = designatedFolder.captions.firstIndex(where: { $0.id == currentCaption.id }) {
                    // Update the caption directly within the folder
                    designatedFolder.captions[captionIndex] = currentCaption
                }

                // Update the folder in the currentFolders array
                currentFolders[designatedFolderIndex] = designatedFolder

                // Update the User document with the new folder and caption information
                let folderData = currentFolders.map { $0.dictionary }
                docRef.updateData(["folders": folderData]) { error in
                    if let error = error {
                        print("Error updating caption: \(error)")
                        onComplete(nil)
                    } else {
                        onComplete(designatedFolder)
                    }
                }
            }
        }
    }

    /**
     This function facilitates the action of deleting a single caption from a folder
     1. Get current folders
     2. Remove the selected caption from the folder
     3. Delete all folders from firebase
     4. Write the updated folder back
     */
    func deleteSingleCaption(for uid: String?, captionToBeRemoved: CaptionModel, onComplete: @escaping () -> Void) {
        guard let userId = uid else {
            appError = ErrorType(error: .genericError)
            onComplete()
            return
        }

        let docRef: DocumentReference = db.collection("Users").document("\(userId)")

        // Get current folders from the user document
        let currentFolders = AuthManager.shared.userManager.user?.folders ?? []

        let updatedFolders = currentFolders.map { folder in
            // find folder to be updated
            var mutableFolder = folder

            if folder.id == captionToBeRemoved.folderId {
                if let indexOfCaption = folder.captions.firstIndex(where: { $0.id == captionToBeRemoved.id }) {
                    mutableFolder.captions.remove(at: indexOfCaption)
                }
            }

            return mutableFolder
        }

        // Create a dispatch group to keep everything synchronous
        // FB must delete all folders and then add new folders before the view gets updated
        // otherwise we run into duplicate keys issues
        let dispatchGroup = DispatchGroup()

        dispatchGroup.enter()

        deleteAllFolders(for: docRef) {
            self.addNewFolders(for: docRef, updatedFolders: updatedFolders) {
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            onComplete()
        }
    }

    func saveCustomTags(for uid: String?, customImageTags: [TagsModel]) {
        guard let userId = uid else {
            appError = ErrorType(error: .genericError)
            return
        }
        
        let docRef: DocumentReference = db.collection("Users").document("\(userId)")
        
        // Get current folders from the user document
        var currentTags = AuthManager.shared.userManager.user?.customImageTags ?? []
        
        if !customImageTags.isEmpty {
            // Append new tags to the currentTags array, ensuring no duplicates
            for newTag in customImageTags {
                if !currentTags.contains(where: { $0.title == newTag.title }) {
                    currentTags.append(newTag)
                }
            }
        }
        
        // Set the updated currentTags array for the user's document
        docRef.setData(["customImageTags": currentTags.map { $0.dictionary }], merge: true)
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

    func unbindListener() async {
        snapshotListener?.remove()
    }
}
