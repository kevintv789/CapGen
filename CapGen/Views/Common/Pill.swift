//
//  PillButton.swift
//  CapGen
//
//  Created by Kevin Vu on 12/28/22.
//

import SwiftUI

struct Pill: View {
    let title: String
    let isToggled: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: isToggled ? 100 : 200)
            .fill(isToggled ? Color.ui.middleBluePurple : Color.ui.cultured)
            .frame(width: isToggled ? 170 : 45, height: 45)
            .shadow(color: isToggled ? Color.ui.lavenderBlue : Color.ui.shadowGray, radius: isToggled ? 0 : 3, x: isToggled ? 0 : 1, y: isToggled ? 0 : 3)
            .overlay(
                HStack(spacing: 10) {
                    Image(title)
                        .resizable()
                        .frame(width: 25, height: 25)
                    
                    if (isToggled) {
                        Text(title)
                            .font(.ui.title4)
                            .foregroundColor( Color.ui.cultured)
                    }
                }
            )
    }
}
