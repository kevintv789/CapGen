//
//  ImageCache.swift
//  CapGen
//
//  Created by Kevin Vu on 5/5/23.
//

import Foundation
import UIKit

/// In-memory cache: In this caching mechanism, the data is stored directly in the device's RAM (Random Access Memory). Since RAM is faster than disk storage, accessing data from an in-memory cache is very fast. However, RAM is a volatile storage medium, which means that the data stored in it is lost when the application is terminated or the device is powered off. Additionally, RAM has limited capacity, so in-memory caches need to manage their size and remove items when necessary.
class ImageCache {
    static let shared = ImageCache()
    private init() {}
    
    private let cache = NSCache<NSString, UIImage>()
    
    func setImage(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
    
    func image(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
}
