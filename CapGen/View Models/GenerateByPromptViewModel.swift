//
//  GenerateByPromptViewModel.swift
//  CapGen
//
//  Created by Kevin Vu on 2/24/23.
//

import Foundation

class GenerateByPromptViewModel: ObservableObject {
    @Published var promptInput: String = ""
    
    func resetInput() {
        self.promptInput.removeAll()
    }
}
