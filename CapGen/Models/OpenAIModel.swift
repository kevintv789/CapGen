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

struct OpenAIResponseHandler {
    func decodeJson(jsonString: String) -> OpenAIResponseModel? {
        let json = jsonString.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        do {
            let product = try decoder.decode(OpenAIResponseModel.self, from: json)
            return product
        } catch {
            print("Error decoding OpenAI API Response \(error)")
        }
        
        return nil
    }
}
