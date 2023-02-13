//
//  String.swift
//  CapGen
//
//  Created by Kevin Vu on 1/10/23.
//

import Foundation
import SwiftUI

enum SizeTye {
    case height, width
}

extension String {
    func split(usingRegex pattern: String) -> [String] {
        let regex = try! NSRegularExpression(pattern: pattern)
        let matches = regex.matches(in: self, range: NSRange(startIndex..., in: self))
        let splits = [startIndex]
            + matches
            .map { Range($0.range, in: self)! }
            .flatMap { [$0.lowerBound, $0.upperBound] }
            + [endIndex]

        return zip(splits, splits.dropFirst())
            .map { String(self[$0 ..< $1]) }
    }

    subscript(offset: Int) -> Character {
        self[index(startIndex, offsetBy: offset)]
    }

    // Get total width of a string
    func getSize(of type: SizeTye = .width) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 20)
        let attributes = [NSAttributedString.Key.font: font]
        let size = (self as NSString).size(withAttributes: attributes)
        return type == .width ? size.width : size.height
    }
}
