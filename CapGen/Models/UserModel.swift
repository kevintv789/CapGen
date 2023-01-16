//
//  User.swift
//  CapGen
//
//  Created by Kevin Vu on 1/16/23.
//

import Foundation
import FirebaseFirestoreSwift
import Firebase

struct UserModel: Codable {
    var id: String
    var fullName: String
    var credits: Int
    var email: String
    var userPrefs: UserPreferences
    var dateCreated: Date
}

struct UserPreferences: Codable {
    var showCongratsModal: Bool
}