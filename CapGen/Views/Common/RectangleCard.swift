//
//  RectangleCard.swift
//  CapGen
//
//  Created by Kevin Vu on 12/30/22.
//

import SwiftUI

struct RectangleCard: View {
    let title: String
    let description: String?
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.ui.cultured, lineWidth: 3)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color.ui.middleYellowRed : Color.ui.cultured)
                )
                .overlay(
                    VStack(alignment: .leading) {
                        Text(title)
                            .foregroundColor(Color.ui.richBlack)
                            .font(.ui.graphikBold)
                            .padding(.top, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Spacer()
                            .frame(height: 10)
                        
                        if (description != nil) {
                            Text(description!)
                                .foregroundColor(isSelected ? Color.ui.richBlack : Color.ui.cadetBlueCrayola)
                                .font(.ui.blackerTextMediumSmall)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        Spacer()
                        
                    }
                        .padding(5)
                )
            
        }
        
    }
}
