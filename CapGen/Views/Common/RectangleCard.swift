//
//  RectangleCard.swift
//  CapGen
//
//  Created by Kevin Vu on 12/30/22.
//

import SwiftUI

struct RectangleCard: View {
    let title: String
    let description: String
    let isSelected: Bool
    
    var body: some View {
        Color.ui.cultured
            .cornerRadius(16)
            .frame(width: 120, height: 120)
            .overlay(
                VStack(alignment: .leading) {
                    Text(title)
                        .foregroundColor(Color.ui.richBlack)
                        .font(.ui.graphikBold)
                        .padding(.top, 10)
                    
                    Spacer()
                    
                    Text(description)
                        .foregroundColor(Color.ui.cadetBlueCrayola)
                        .font(.ui.blackerTextMediumSmall)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Circle()
                        .strokeBorder(.black, lineWidth: 1)
                        .background(Circle().fill(isSelected ? Color.ui.middleYellowRed : Color.ui.cultured))
                        .frame(width: 15, height: 15)
                }
                    .padding(5)
                
            )
    }
}
