//
//  FolderViewModel.swift
//  CapGen
//
//  Created by Kevin Vu on 2/23/23.
//

import Foundation

class FolderViewModel: ObservableObject {
    @Published var currentFolder: FolderModel = .init()
    @Published var isDeleting: Bool = false
    @Published var editedFolder: FolderModel = .init()

    func resetFolder() {
        currentFolder = FolderModel()
        editedFolder = FolderModel()
    }
}
