//
//  FloatingNotification.swift
//  CapGen
//
//  Created by Kevin Vu on 1/26/23.
//

import SwiftUI

struct FloatingNotificationView: View {
    let title: String
    
    var body: some View {
        ZStack(alignment: .center) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.ui.richBlack)
                .shadow(color: Color.ui.richBlack, radius: 3, x: 2, y: 2)
            
            Text(title)
                .foregroundColor(.ui.cultured)
                .font(.ui.headline)
        }
        .frame(width: SCREEN_WIDTH / 1.1, height: 40, alignment: .center)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 40)
    }
}

