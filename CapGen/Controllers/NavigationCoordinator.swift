//
//  NavigationCoordinator.swift
//  CapGen
//
//  Created by Kevin Vu on 1/2/23.
//

import Foundation
import SwiftUI

class NavigationCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    
    func popToRoot() {
        path.removeLast(path.count)
    }
}
