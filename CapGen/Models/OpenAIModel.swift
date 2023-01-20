//
//  OpenAIModel.swift
//  CapGen
//
//  Created by Kevin Vu on 1/2/23.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import Firebase

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

struct GeneratedCaptions: Codable, Identifiable {
    var id: String = UUID().uuidString
    var description: String
}

struct AIRequest: Codable, Identifiable {
    var id: String = UUID().uuidString
    var platform: String = ""
    var prompt: String = ""
    var tone: String = ""
    var includeEmojis: Bool = false
    var includeHashtags: Bool = false
    var captionLength: String = ""
    var title: String = ""
    var dateCreated: String?
    var captions: [GeneratedCaptions] = []
    
    var dictionary: [String: Any] {
        let data = (try? JSONEncoder().encode(self)) ?? Data()
        return (try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any]) ?? [:]
    }
    
    init() { }
    
    init(platform: String, prompt: String, tone: String, includeEmojis: Bool, includeHashtags: Bool, captionLength: String) {
        self.platform = platform
        self.prompt = prompt
        self.tone = tone
        self.includeEmojis = includeEmojis
        self.includeHashtags = includeHashtags
        self.captionLength = captionLength
        self.dateCreated = getCurrentDate()
    }
    
    func getCurrentDate() -> String? {
        let date = Date()
        let df = DateFormatter()
        
        // LONG STYLE
        df.dateStyle = DateFormatter.Style.long
        df.timeStyle = DateFormatter.Style.long
        return df.string(from: date) // December 10, 2021 at 5:00:41 PM PST
    }
}
