//
//  SavedCaptionHomeViewModel.swift
//  CapGen
//
//  Created by Kevin Vu on 3/9/23.
//

import Foundation

class SavedCaptionHomeViewModel: ObservableObject {
    @Published var isGridView: Bool = true
    @Published var isViewExpanded: Bool = false
    @Published var isSearching: Bool = false
}
