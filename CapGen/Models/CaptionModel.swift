//
//  CaptionModel.swift
//  CapGen
//
//  Created by Kevin Vu on 2/24/23.
//

import Foundation

struct CaptionModel: Identifiable, Codable, Hashable, Comparable {
    var id: String = UUID().uuidString
    var captionLength: String = ""
    var dateCreated: String = Utils.getCurrentDate()
    var captionDescription: String = ""
    var includeEmojis: Bool = false
    var includeHashtags: Bool = false
    var folderId: String = ""
    var prompt: String = ""
    var title: String = ""
    var tones: [ToneModel] = []
    var color: String = ""
    var index: Int = 0
    var completePrompt: String?

    static func < (lhs: CaptionModel, rhs: CaptionModel) -> Bool {
        let leftDate = Utils.convertStringToDate(date: lhs.dateCreated) ?? Date()
        let rightDate = Utils.convertStringToDate(date: rhs.dateCreated) ?? Date()

        return leftDate < rightDate
    }

    static func == (lhs: CaptionModel, rhs: CaptionModel) -> Bool {
        return lhs.id == rhs.id
    }

    var dictionary: [String: Any] {
        let data = (try? JSONEncoder().encode(self)) ?? Data()
        return (try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any]) ?? [:]
    }

    init() {}

    // Used within CaptionView mapCaptionToBeEdited()
    // for creating new captions inside a designated folder
    init(captionLength: String, captionDescription: String, includeEmojis: Bool, includeHashtags: Bool, prompt: String, title: String, tones: [ToneModel], color: String, completePrompt: String) {
        self.captionLength = captionLength
        self.captionDescription = captionDescription
        self.includeEmojis = includeEmojis
        self.includeHashtags = includeHashtags
        self.prompt = prompt
        self.title = title
        self.tones = tones
        self.color = color
        self.completePrompt = completePrompt
    }

    // This is used within convertGeneratedCaptions() for mapping User model 
    init(id: String, captionLength: String, dateCreated: String, captionDescription: String, includeEmojis: Bool, includeHashtags: Bool, folderId: String, prompt: String, title: String, tones: [ToneModel], color: String, index: Int, completePrompt: String?) {
        self.id = id
        self.captionLength = captionLength
        self.dateCreated = dateCreated
        self.captionDescription = captionDescription
        self.includeEmojis = includeEmojis
        self.includeHashtags = includeHashtags
        self.folderId = folderId
        self.prompt = prompt
        self.title = title
        self.tones = tones
        self.color = color
        self.index = index
        self.completePrompt = completePrompt
    }

    init(captionLength: String, captionDescription: String, includeEmojis: Bool, includeHashtags: Bool, folderId: String, prompt: String, title: String, tones: [ToneModel], color: String, index: Int) {
        self.captionLength = captionLength
        self.captionDescription = captionDescription
        self.includeEmojis = includeEmojis
        self.includeHashtags = includeHashtags
        self.folderId = folderId
        self.prompt = prompt
        self.title = title
        self.tones = tones
        self.color = color
        self.index = index
    }
}
