//
//  CaptionViewModel.swift
//  CapGen
//
//  Created by Kevin Vu on 2/28/23.
//

import Foundation
import SwiftUI

class CaptionViewModel: ObservableObject {
    @Published var selectedCaption: CaptionModel = CaptionModel()
    @Published var isCaptionSelected: Bool = false // show bottom sheet if true

    func resetSelectedCaption() {
        selectedCaption = CaptionModel()
        isCaptionSelected = false
    }
}
