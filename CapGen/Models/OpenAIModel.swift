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

struct AIRequest: Codable, Identifiable, Comparable {
    var id: String = UUID().uuidString
    var platform: String = ""
    var prompt: String = ""
    var tones: [ToneModel] = []
    var includeEmojis: Bool = false
    var includeHashtags: Bool = false
    var captionLength: String = ""
    var title: String = ""
    var dateCreated: String = getCurrentDate()
    var captions: [GeneratedCaptions] = []
    
    static func < (lhs: AIRequest, rhs: AIRequest) -> Bool {
        let leftDate = convertStringToDate(date: lhs.dateCreated) ?? Date()
        let rightDate = convertStringToDate(date: rhs.dateCreated) ?? Date()
        
        return leftDate < rightDate
    }
    
    static func == (lhs: AIRequest, rhs: AIRequest) -> Bool {
        let leftDate = convertStringToDate(date: lhs.dateCreated) ?? Date()
        let rightDate = convertStringToDate(date: rhs.dateCreated) ?? Date()
        
        return leftDate == rightDate
    }
    
    var dictionary: [String: Any] {
        let data = (try? JSONEncoder().encode(self)) ?? Data()
        return (try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any]) ?? [:]
    }
    
    init() { }
    
    init(id: String, platform: String, prompt: String, tones: [ToneModel], includeEmojis: Bool, includeHashtags: Bool, captionLength: String, title: String, dateCreated: String, captions: [GeneratedCaptions]) {
        self.id = id
        self.platform = platform
        self.prompt = prompt
        self.tones = tones
        self.includeEmojis = includeEmojis
        self.includeHashtags = includeHashtags
        self.captionLength = captionLength
        self.dateCreated = dateCreated
        self.title = title
        self.captions = captions
    }
    
    init(platform: String, prompt: String, tones: [ToneModel], includeEmojis: Bool, includeHashtags: Bool, captionLength: String) {
        self.platform = platform
        self.prompt = prompt
        self.tones = tones
        self.includeEmojis = includeEmojis
        self.includeHashtags = includeHashtags
        self.captionLength = captionLength
    }
    
    static func getCurrentDate() -> String {
        let date = Date()
        let df = DateFormatter()
        df.dateFormat = "MMM d, h:mm a"
        df.timeZone = TimeZone.current
        return df.string(from: date)
    }
    
    static func convertStringToDate(date: String?) -> Date? {
        guard let date = date else { return nil }
        let df = DateFormatter()
        df.dateFormat = "MMM d, h:mm a"
        return df.date(from: date)
    }
}
