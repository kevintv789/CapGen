//
//  TagsModel.swift
//  CapGen
//
//  Created by Kevin Vu on 4/26/23.
//

import Foundation

struct TagsModel: Identifiable, Codable, Hashable {
    let id: Int
    let title: String
    var size: CGFloat
}

var defaultTags: [TagsModel] = load("Tags.json")
