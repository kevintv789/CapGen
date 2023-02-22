//
//  FolderModel.swift
//  CapGen
//
//  Created by Kevin Vu on 2/22/23.
//

import Foundation

enum FolderType: Codable {
    case General, Instagram, Twitter, Facebook, Snapchat, LinkedIn, Pinterest, TikTok, Reddit, YouTube
}

struct FolderModel: Identifiable, Codable, Comparable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var dateCreated: String = Utils.getCurrentDate()
    var folderType: FolderType
    var captions: [GeneratedCaptions]
    
    static func < (lhs: FolderModel, rhs: FolderModel) -> Bool {
        let leftDate = Utils.convertStringToDate(date: lhs.dateCreated) ?? Date()
        let rightDate = Utils.convertStringToDate(date: rhs.dateCreated) ?? Date()

        return leftDate < rightDate
    }

    static func == (lhs: FolderModel, rhs: FolderModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    init(name: String, folderType: FolderType, captions: [GeneratedCaptions]) {
        self.name = name
        self.folderType = folderType
        self.captions = captions
    }
}
