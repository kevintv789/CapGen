//
//  SocialMediaPlatformsModel.swift
//  CapGen
//
//  Created by Kevin Vu on 1/25/23.
//

import Foundation

struct SocialMediaPlatformsModel: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let characterLimit: Int
    let hashtagLimit: Int
    let link: String
    let websiteLink: String
}

var socialMediaPlatforms: [SocialMediaPlatformsModel] = load("SocialMediaPlatforms.json")
