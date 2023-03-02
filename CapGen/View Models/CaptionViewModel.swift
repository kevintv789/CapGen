//
//  CaptionViewModel.swift
//  CapGen
//
//  Created by Kevin Vu on 2/28/23.
//

import Foundation
import SwiftUI

struct SelectedCaption {
    var description: String = ""
    var color: Color = .clear
}

class CaptionViewModel: ObservableObject {
    @Published var selectedCaption: SelectedCaption = .init(description: captionsParsedArrayMock[0], color: .ui.darkSalmon)
    @Published var isCaptionSelected: Bool = true // show bottom sheet if true

    func resetSelectedCaption() {
        selectedCaption = .init()
        isCaptionSelected = false
    }

    func initSelectCaption(description: String, color: Color) {
        selectedCaption = .init(description: description, color: color)
    }
}
