//
//  TagsModel.swift
//  CapGen
//
//  Created by Kevin Vu on 4/26/23.
//

import Foundation

struct TagsModel: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    var size: CGFloat
    let isCustom: Bool

    var dictionary: [String: Any] {
        let data = (try? JSONEncoder().encode(self)) ?? Data()
        return (try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any]) ?? [:]
    }
}

var defaultTags: [TagsModel] = load("Tags.json")
