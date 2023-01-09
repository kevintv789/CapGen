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
    }
}
