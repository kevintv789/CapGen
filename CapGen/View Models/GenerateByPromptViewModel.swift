//
//  GenerateByPromptViewModel.swift
//  CapGen
//
//  Created by Kevin Vu on 2/24/23.
//

import Foundation

class GenerateByPromptViewModel: ObservableObject {
    @Published var promptInput: String = ""
    @Published var selectdTones: [ToneModel] = []
    @Published var includeEmojis: Bool = false
    @Published var includeHashtags: Bool = false
    @Published var captionLengthValue: String = captionLengths[0].value // Used to generate the actual prompt for AI
    @Published var captionLengthType: String = captionLengths[0].type // Used to determine the correct icon, i.e., 'veryShort, short, etc.'
    @Published var captionLengthId: Int = 0

    func resetInput() {
        promptInput.removeAll()
    }

    func resetAll() {
        promptInput.removeAll()
        selectdTones.removeAll()
        includeEmojis = false
        includeHashtags = false
        captionLengthValue.removeAll()
        captionLengthType.removeAll()
        captionLengthId = 0
    }
}
