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
}

var captionLengths: [CaptionLengths] = load("CaptionLengths.json")
