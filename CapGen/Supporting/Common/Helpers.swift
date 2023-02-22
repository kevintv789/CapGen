//
//  Helpers.swift
//  CapGen
//
//  Created by Kevin Vu on 2/12/23.
//

import Foundation
import SwiftUI

enum DayType {
    case morning, afternoon, evening
}

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

func calculateTimeOfDay() -> DayType {
    var timeOfDay: DayType = .afternoon
    let hour: Int = Calendar.current.component(.hour, from: Date())

    // 6PM - 4AM = Good evening
    if (18 ... 23).contains(hour) || (0 ... 3).contains(hour) {
        timeOfDay = .evening
    } else if (5 ... 11).contains(hour) {
        // 5AM - 11AM = Good morning
        timeOfDay = .morning
    }

    return timeOfDay
}

struct Utils {
    static func getCurrentDate() -> String {
        let date = Date()
        let df = DateFormatter()
        df.dateFormat = "MMM d, h:mm a"
        df.timeZone = TimeZone.current
        return df.string(from: date)
    }

    static func convertStringToDate(date: String?) -> Date? {
        guard let date = date else { return nil }
        let df = DateFormatter()
        df.dateFormat = "MMM d, h:mm a"
        return df.date(from: date)
    }
}
