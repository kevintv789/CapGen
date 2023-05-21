//
//  OpenAIModel.swift
//  CapGen
//
//  Created by Kevin Vu on 1/2/23.
//

import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import Foundation

struct OpenAIResponseModel: Identifiable, Codable {
    var id: String
    var object: String?
    var created: Int?
    var model: String?
    var usage: Usage?
    var choices: [Choice]?
}

struct Choice: Codable {
    var message: GPTMessagesType
    var index: Int
    var finish_reason: String?
}

struct GPTMessagesType: Codable {
    var role: String
    var content: String

    var dictionary: [String: Any] {
        let data = (try? JSONEncoder().encode(self)) ?? Data()
        return (try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any]) ?? [:]
    }
}

struct Usage: Codable {
    var prompt_tokens: Int
    var completion_tokens: Int
    var total_tokens: Int
}

struct GeneratedCaptions: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var description: String
}
