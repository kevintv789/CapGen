//
//  Bool.swift
//  CapGen
//
//  Created by Kevin Vu on 2/26/23.
//

import Foundation
import SwiftUI

prefix func ! (value: Binding<Bool>) -> Binding<Bool> {
    Binding<Bool>(
        get: { !value.wrappedValue },
        set: { value.wrappedValue = !$0 }
    )
}
