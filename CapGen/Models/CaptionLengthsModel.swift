//
//  CaptionLengthsModel.swift
//  CapGen
//
//  Created by Kevin Vu on 1/1/23.
//

import Foundation

struct CaptionLengths: Decodable {
    let id: Int
    let value: String
    let title: String
    let type: String
    let min: Int
    let max: Int
}

var captionLengths: [CaptionLengths] = load("CaptionLengths.json")
