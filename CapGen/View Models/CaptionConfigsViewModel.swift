//
//  CaptionConfigsVm.swift
//  CapGen
//
//  Created by Kevin Vu on 1/30/23.
//

import Foundation

class CaptionConfigsViewModel: ObservableObject {
    @Published var promptText: String = ""
    @Published var platformSelected: String = socialMediaPlatforms[0].title

    func resetConfigs() {
        promptText = ""
        platformSelected = socialMediaPlatforms[0].title
    }
}
