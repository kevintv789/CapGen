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
        self.promptInput.removeAll()
    }
    
    func resetAll() {
        self.promptInput.removeAll()
        self.selectdTones.removeAll()
        self.includeEmojis = false
        self.includeHashtags = false
        self.captionLengthValue.removeAll()
        self.captionLengthType.removeAll()
        self.captionLengthId = 0
    }
}
