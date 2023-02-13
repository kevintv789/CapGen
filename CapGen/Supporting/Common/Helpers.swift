//
//  Helpers.swift
//  CapGen
//
//  Created by Kevin Vu on 2/12/23.
//

import Foundation
import SwiftUI

public func openSocialMediaLink(for platform: String) {
    @Environment(\.openURL) var openURL
    
    let socialMediaFiltered = socialMediaPlatforms.first(where: { $0.title == platform })
    let url = URL(string: socialMediaFiltered!.link)!
    let application = UIApplication.shared
    
    // Check if the App is installed
    if application.canOpenURL(url) {
        application.open(url)
    } else {
        // If Facebook App is not installed, open Safari Link
        application.open(URL(string: socialMediaFiltered!.websiteLink)!)
    }
    
    openURL(URL(string: socialMediaFiltered!.link)!)
}
