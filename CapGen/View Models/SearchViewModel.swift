//
//  SearchViewModel.swift
//  CapGen
//
//  Created by Kevin Vu on 3/16/23.
//

import Foundation

class SearchViewModel: ObservableObject {
    @Published var searchedText: String = ""
    @Published var searchedCaptions: [CaptionModel] = []
}
