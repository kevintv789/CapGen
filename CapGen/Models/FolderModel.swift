//
//  FolderModel.swift
//  CapGen
//
//  Created by Kevin Vu on 2/22/23.
//

import Foundation

enum FolderType: String, Codable {
    case General, Instagram, Twitter, Facebook, Snapchat, LinkedIn, Pinterest, TikTok, Reddit, YouTube
}

struct FolderModel: Identifiable, Codable, Comparable, Hashable {
    var id: String = UUID().uuidString
    var name: String = ""
    var dateCreated: String = Utils.getCurrentDate()
    var folderType: FolderType = .General
    var captions: [CaptionModel] = []
    var index: Int = 0

    static func < (lhs: FolderModel, rhs: FolderModel) -> Bool {
        let leftDate = Utils.convertStringToDate(date: lhs.dateCreated) ?? Date()
        let rightDate = Utils.convertStringToDate(date: rhs.dateCreated) ?? Date()

        return leftDate < rightDate
    }

    static func == (lhs: FolderModel, rhs: FolderModel) -> Bool {
        return lhs.id == rhs.id
    }

    init() {}

    // Used to create new folders within FolderBottomSheetView
    init(name: String, folderType: FolderType, captions: [CaptionModel], index: Int) {
        self.name = name
        self.folderType = folderType
        self.captions = captions
        self.index = index
    }

    // Used to retrieve folder from DB
    init(id: String, name: String, dateCreated: String, folderType: FolderType, captions: [CaptionModel], index: Int) {
        self.id = id
        self.name = name
        self.folderType = folderType
        self.captions = captions
        self.dateCreated = dateCreated
        self.index = index
    }

    var dictionary: [String: Any] {
        let data = (try? JSONEncoder().encode(self)) ?? Data()
        return (try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any]) ?? [:]
    }
}
