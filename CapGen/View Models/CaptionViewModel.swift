//
//  CaptionViewModel.swift
//  CapGen
//
//  Created by Kevin Vu on 2/28/23.
//

import Foundation
import SwiftUI

// This struct helps identify which caption was edited
// so that we can easily replace it when saving
struct EditedCaption {
    var index: Int = 0
    var text: String = ""
}

class CaptionViewModel: ObservableObject {
    @Published var selectedCaption: CaptionModel = .init()
    @Published var isCaptionSelected: Bool = false // show bottom sheet if true
    @Published var editedCaption: EditedCaption = .init() // caption to edit

    func resetSelectedCaption() {
        selectedCaption = CaptionModel()
        isCaptionSelected = false
    }
    
    func resetEditedCaption() {
        editedCaption = .init()
    }
}
