//
//  PillButton.swift
//  CapGen
//
//  Created by Kevin Vu on 12/28/22.
//

import SwiftUI

struct Pill: View {
    @ScaledMetric var scaledSize: CGFloat = 1
    
    let title: String
    let isToggled: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 100)
            .fill(isToggled ? Color.ui.middleBluePurple : Color.ui.cultured)
            .frame(width: isToggled ? 170 * scaledSize : 45 * scaledSize, height: 45 * scaledSize)
            .shadow(color: isToggled ? Color.ui.lavenderBlue : Color.ui.shadowGray, radius: isToggled ? 0 : 3, x: isToggled ? 0 : 1, y: isToggled ? 0 : 3)
            .overlay(
                HStack(spacing: 10) {
                    Image(title)
                        .resizable()
                        .frame(width: 25 * scaledSize, height: 25 * scaledSize)
                    
                    if (isToggled) {
                        Text(title)
                            .font(.ui.title4)
                            .foregroundColor(Color.ui.cultured)
                    }
                }
            )
    }
}
