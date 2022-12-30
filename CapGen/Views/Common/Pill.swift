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
        Text(title)
            .font(.ui.graphikMedium)
            .foregroundColor(isToggled ? Color.ui.richBlack : Color.ui.cadetBlueCrayola)
            .padding(10)
            .overlay(
                RoundedRectangle(cornerRadius: 100)
                    .stroke(isToggled ? .black : Color.ui.cadetBlueCrayola, lineWidth: 2)
                    .shadow(
                        color: Color.ui.shadowGray.opacity(isToggled ? 0.8 : 0),
                        radius: 2,
                        x: 1,
                        y: 2
                    )
            )
            .background(
                RoundedRectangle(cornerRadius: 100)
                    .fill(isToggled ? Color.ui.lightOldPaper : .white.opacity(0))
            )
    }
}
