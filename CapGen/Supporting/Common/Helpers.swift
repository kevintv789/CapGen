//
//  Helpers.swift
//  CapGen
//
//  Created by Kevin Vu on 2/12/23.
//

import Foundation
import SwiftUI
import UIKit

enum DayType {
    case morning, afternoon, evening
}

public func openSocialMediaLink(for platform: String) {
    @Environment(\.openURL) var openURL

    let socialMediaFiltered = socialMediaPlatforms.first(where: { $0.title == platform })

    if let socialMediaFiltered = socialMediaFiltered {
        let url = URL(string: socialMediaFiltered.link)!
        let application = UIApplication.shared

        // Check if the App is installed
        if application.canOpenURL(url) {
            application.open(url)
        } else {
            // If Facebook App is not installed, open Safari Link
            application.open(URL(string: socialMediaFiltered.websiteLink)!)
        }

        openURL(URL(string: socialMediaFiltered.link)!)
    }
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

/// Extracts and correctly numbers the lines from the input text.
///
/// This function searches for lines in the input text that are either numbered or not, and returns a list of strings
/// with the correctly numbered lines.
///
/// - Parameters:
///   - text: The input text containing the lines to be extracted and numbered.
///
/// - Returns: An array of strings containing the correctly numbered lines.
func extractNumberedLines(text: String) -> [String] {
    // Define the regular expression pattern to match lines, whether they have numbers or not.
    let regexPattern = "(?m)^\\s*(?:\\d+\\.)?\\s*(.+)"
    var results: [String] = []

    do {
        // Create a regular expression object with the defined pattern.
        let regex = try NSRegularExpression(pattern: regexPattern, options: [])
        
        // Define the range for the entire input text.
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        
        // Search for matches using the regular expression object.
        let matches = regex.matches(in: text, options: [], range: nsRange)

        // Iterate through the matches.
        for match in matches {
            // Extract the content of the line, without the number and the period.
            if let range = Range(match.range(at: 1), in: text) {
                var lineContent = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Remove any existing numbering and extra newline characters, if present.
                if let existingNumberRange = lineContent.range(of: "^\\d+\\.\\s*\\n?", options: .regularExpression) {
                    lineContent.removeSubrange(existingNumberRange)
                }
                
                // Append the corrected line to the results array.
                results.append(lineContent)
            }
        }
    } catch {
        print("Invalid regex pattern")
    }

    // Return the array of correctly numbered lines.
    return results
}

/**
 Filters a given text, extracting only real words and returning them as a comma-separated string.

 - Parameters:
    - text: A String containing the text to filter. The text should have words separated by newline characters.

 - Returns: A String with real words separated by commas.

 - Note: This function uses `UITextChecker` to check if a word is misspelled or not. It considers words that are not misspelled as real words. The language used for checking is English (language code "en").
 **/
func filterToRealWords(text: String) -> String {
    let words = text.components(separatedBy: .newlines)
    let textChecker = UITextChecker()

    let filteredWords = words.filter { word in
        let range = NSRange(location: 0, length: word.utf16.count)
        let misspelledRange = textChecker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
        let containsNumber = word.rangeOfCharacter(from: .decimalDigits) != nil
        
        return misspelledRange.location == NSNotFound && !containsNumber
    }
    
    return filteredWords.joined(separator: ", ")
}

enum Utils {
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

    static func convertGeneratedCaptions(for generatedCaptions: [[String: AnyObject]]?) -> [CaptionModel] {
        guard let captions = generatedCaptions else { return [] }

        var result: [CaptionModel] = []

        captions.forEach { element in
            let captionLength = element["captionLength"] as! String
            let captionDescription = element["captionDescription"] as! String
            let dateCreated = element["dateCreated"] as! String
            let id = element["id"] as! String
            let includeEmojis = element["includeEmojis"] as! Bool
            let includeHashtags = element["includeHashtags"] as! Bool
            let prompt = element["prompt"] as! String
            let title = element["title"] as! String
            let folderId = element["folderId"] as! String
            let color = element["color"] as! String
            let index = element["index"] as! Int

            let tonesDict = element["tones"] as? [[String: AnyObject]] ?? []
            var tones: [ToneModel] = []
            tonesDict.forEach { ele in
                let tone = ToneModel(id: ele["id"] as! Int, title: ele["title"] as! String, description: ele["description"] as! String, icon: ele["icon"] as! String)
                tones.append(tone)
            }

            let mappedCaption = CaptionModel(id: id, captionLength: captionLength, dateCreated: dateCreated, captionDescription: captionDescription, includeEmojis: includeEmojis, includeHashtags: includeHashtags, folderId: folderId, prompt: prompt, title: title, tones: tones, color: color, index: index)

            result.append(mappedCaption)
        }

        // Sort by most recent created
        let df = DateFormatter()
        df.dateFormat = "MMM d, h:mm a"
        result.sort(by: { df.date(from: $0.dateCreated)!.compare(df.date(from: $1.dateCreated)!) == .orderedDescending })

        return result
    }
}
