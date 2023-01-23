//
//  Font.swift
//  CapGen
//
//  Created by Kevin Vu on 12/28/22.
//

/**
 Family: Graphik Font names: ["Graphik-Regular", "Graphik-RegularItalic", "Graphik-Thin", "Graphik-ThinItalic", "Graphik-Extralight", "Graphik-ExtralightItalic", "Graphik-Light", "Graphik-LightItalic", "Graphik-Medium", "Graphik-MediumItalic", "Graphik-Semibold", "Graphik-SemiboldItalic", "Graphik-Bold", "Graphik-BoldItalic", "Graphik-Black", "Graphik-BlackItalic", "Graphik-Super", "Graphik-SuperItalic"]
 
 Family: Blacker Display Font names: ["BlackerDisplay-Regular", "BlackerDisplay-Italic", "BlackerDisplay-Light", "BlackerDisplay-LightItalic", "BlackerDisplay-Medium", "BlackerDisplay-MediumItalic", "BlackerDisplay-Bold", "BlackerDisplay-BoldItalic", "BlackerDisplay-ExtraBold", "BlackerDisplay-ExtraBoldItalic", "BlackerDisplay-Heavy", "BlackerDisplay-HeavyItalic"]
 
 Family: Blacker Text Font names: ["BlackerText-Book", "BlackerText-Regular", "BlackerText-BookItalic", "BlackerText-Italic", "BlackerText-Light", "BlackerText-LightItalic", "BlackerText-Medium", "BlackerText-MediumItalic", "BlackerText-Bold", "BlackerText-BoldItalic", "BlackerText-Heavy", "BlackerText-HeavyItalic"]
 */

import Foundation
import SwiftUI

struct Sizes {
    let LARGE = CGFloat(28)
    let REGULAR = CGFloat(18)
    let MEDIUM = CGFloat(16)
    let SMALL = CGFloat(14)
}

extension Font {
    static let ui = Font.UI()
    static let sizes = Sizes()

    struct UI {
        let graphikRegular = Font.custom("Graphik-Regular", size: sizes.REGULAR)
        let graphikRegularSmall = Font.custom("Graphik-Regular", size: sizes.SMALL)
        let graphikSemibold = Font.custom("Graphik-Semibold", size: sizes.REGULAR)
        let graphikSemiboldMed = Font.custom("Graphik-Semibold", size: sizes.MEDIUM)
        let graphikSemiboldLarge = Font.custom("Graphik-Semibold", size: sizes.LARGE)
        let graphikMedium = Font.custom("Graphik-Medium", size: sizes.REGULAR)
        let graphikMediumMed = Font.custom("Graphik-Medium", size: sizes.MEDIUM)
        let graphikBold = Font.custom("Graphik-Bold", size: sizes.REGULAR)
        let graphikBoldMed = Font.custom("Graphik-Bold", size: sizes.MEDIUM)
        let graphikLightItalic = Font.custom("Graphik-LightItalic", size: sizes.SMALL)
        let blackerTextMediumSmall = Font.custom("BlackerText-Medium", size: sizes.SMALL)
        
        let largeTitle = Font.custom("Graphik-Black", size: 34, relativeTo: .largeTitle)
        let largeTitleMd = Font.custom("Graphik-Black", size: 28, relativeTo: .largeTitle)
        let largeTitleSm = Font.custom("Graphik-Bold", size: 26, relativeTo: .largeTitle)
        let title = Font.custom("Graphik-Semibold", size: 28, relativeTo: .title)
        let title2 = Font.custom("Graphik-Medium", size: 22, relativeTo: .title2)
        let title3 = Font.custom("Graphik-Light", size: 20, relativeTo: .title3)
        let title4 = Font.custom("Graphik-Semibold", size: 20, relativeTo: .title3)
        let headline = Font.custom("Graphik-Medium", size: 18, relativeTo: .headline)
        let headlineMd = Font.custom("Graphik-Medium", size: 15, relativeTo: .headline)
        let headlineSm = Font.custom("Graphik-Medium", size: 13, relativeTo: .headline)
        let subheadline = Font.custom("Graphik-RegularItalic", size: 15, relativeTo: .subheadline)
        let bodyLarge = Font.custom("Graphik-Regular", size: 16, relativeTo: .body)
        let body = Font.custom("Graphik-Regular", size: 13, relativeTo: .body)
        let bodyLight = Font.custom("Graphik-Light", size: 13, relativeTo: .body)
        let callout = Font.custom("Graphik-SemiboldItalic", size: 11, relativeTo: .callout)
        let footnote = Font.custom("Graphik-Regular", size: 9, relativeTo: .footnote)
        let caption = Font.custom("Graphik-RegularItalic", size: 7, relativeTo: .caption)
        let caption2 = Font.custom("Graphik-Regular", size: 5, relativeTo: .caption2)
    }
}
