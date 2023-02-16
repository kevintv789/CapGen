//
//  User.swift
//  CapGen
//
//  Created by Kevin Vu on 1/16/23.
//

import Firebase
import FirebaseFirestoreSwift
import Foundation

struct UserModel: Codable {
    var id: String
    var fullName: String
    var credits: Int
    var email: String
    var userPrefs: UserPreferences
    var dateCreated: Date
    var captionsGroup: [AIRequest] = []
}

struct UserPreferences: Codable {
    var showCongratsModal: Bool
    var showCreditDepletedModal: Bool
}
