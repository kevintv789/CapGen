//
//  FolderViewModel.swift
//  CapGen
//
//  Created by Kevin Vu on 2/23/23.
//

import Foundation

// Temp storage for all captions currently saved in a folder
struct DestinationFolder {
    var id: String // folder id
    var caption: CaptionModel
}

class FolderViewModel: ObservableObject {
    @Published var currentFolder: FolderModel = .init()
    @Published var isDeleting: Bool = false
    @Published var editedFolder: FolderModel = .init()
    @Published var captionFolderStorage: [DestinationFolder] = []
    @Published var updatedFolder: FolderModel? = nil
    @Published var captionToBeDeleted: CaptionModel? = nil
    @Published var folders: [FolderModel] = []
    
    // Singleton instance of FolderViewModel
    static let shared = FolderViewModel()
    
    func resetFolder() {
        currentFolder = FolderModel()
        editedFolder = FolderModel()
    }
    
    func resetFolderStorage() {
        captionFolderStorage.removeAll()
    }

    func resetCaptionToBeDeleted() {
        captionToBeDeleted = nil
    }
}
