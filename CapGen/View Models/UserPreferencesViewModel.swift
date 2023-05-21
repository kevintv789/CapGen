//
//  UserPreferencesViewModel.swift
//  CapGen
//
//  Created by Kevin Vu on 5/9/23.
//

import Foundation

class UserPreferencesViewModel: ObservableObject {
    @Published var persistImage: Bool = true
    
    func resetPreferencesToDefault() {
        self.persistImage = true
    }
}
