//
//  PhotoSelectionViewModel.swift
//  CapGen
//
//  Created by Kevin Vu on 4/14/23.
//

import Foundation
import SwiftUI
import PhotosUI

class PhotoSelectionViewModel: ObservableObject {
    @Published var photosPickerData: Data? = nil
    
    func resetPhotoSelection() {
        self.photosPickerData = nil
    }
    
    func assignPhotoPickerItem(image: PhotosPickerItem) async {
        if let data = try? await image.loadTransferable(type: Data.self) {
            self.photosPickerData = data
        }
    }
}
