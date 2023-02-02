//
//  CaptionEditViewModel.swift
//  CapGen
//
//  Created by Kevin Vu on 1/29/23.
//
// SwiftUI resets all the properties of a view marked with @State every time the view is removed from a view hierarchy. For the NavigationStackView this is a problem because when I come back to a previous view (with a pop operation) I want all my view controls to be as I left them before (for example I want my TextFields to contain the text I previously typed in). In order to workaround this problem you have to use @ObservableObject when you need to make some state persist between push/pop operations.

import Foundation

class CaptionEditViewModel: ObservableObject {
    @Published var editableText: String = ""
    @Published var selectedIndex: Int = 0
    @Published var captionsGroupParsed: [String] = []
    @Published var captionGroupTitle: String = ""
    @Published var textSizes: [CGSize] = []
    
    func resetCaptionView() {
        DispatchQueue.main.async {
            self.editableText = ""
            self.selectedIndex = 0
            self.captionGroupTitle = ""
            self.captionsGroupParsed = []
        }
    }
}
