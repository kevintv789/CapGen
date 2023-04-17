//
//  ImageDataModel.swift
//  CapGen
//
//  Created by Kevin Vu on 4/17/23.
//

import Foundation

struct GeoLocation {
    let longitude: Double
    let latitude: Double
}

struct ImageGeoLocationAddress {
    let landmarkName: String?
    let locality: String?
    let state: String?
    let country: String?
}
