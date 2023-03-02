//
//  Color.swift
//  CapGen
//
//  Created by Kevin Vu on 12/27/22.
//

import SwiftUI

extension Color {
    static let ui = Color.UI()

    struct UI {
        let middleYellowRed = Color("Middle Yellow Red")
        let middleBluePurple = Color("Middle Blue Purple")
        let lavenderBlue = Color("Lavender Blue")
        let cadetBlueCrayola = Color("Cadet Blue Crayola")
        let pink = Color("Orchid Crayola")
        let darkSalmon = Color("Dark Salmon")
        let frenchBlueSky = Color("French Blue Sky")
        let lightCyan = Color("Light Cyan")
        let richBlack = Color("Rich Black")
        let cultured = Color("Cultured")
        let lightOldPaper = Color("Light Old Paper")
        let lighterLavBlue = Color("Lighter Lavender Blue")
        let shadowGray = Color("Shadow Gray")
        let dangerRed = Color("Danger Red")
        let orangeWeb = Color("Orange Web")
        let darkerPurple = Color("Darker Purple")
    }

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
