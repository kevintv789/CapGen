//
//  OpenAIModel.swift
//  CapGen
//
//  Created by Kevin Vu on 1/2/23.
//

import Foundation

struct OpenAIResponseModel: Codable {
    var id: String
    var object: String
    var created: Int
    var model: String
    var choices: [Choice]
}

struct Choice: Codable {
    var text: String
    var index: Int
    var logprobs: String?
    var finish_reason: String
}
