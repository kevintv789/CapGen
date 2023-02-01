//
//  CreditCounterView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/17/23.
//

import SwiftUI

struct CreditCounterView: View {
    @Binding var credits: Int
    @Binding var showModal: Bool
    
    var body: some View {
        Button {
            withAnimation {
                self.showModal = true
            }
            
            Haptics.shared.play(.medium)
        } label : {
            HStack(alignment: .center, spacing: 0) {
                Text("\(credits > 100 ? "100+" : "\(credits)")")
                    .font(.ui.headline)
                    .foregroundColor(.ui.orangeWeb)
                    .padding(.leading, 15)
                    
                
                Image("coin-icon")
                    .resizable()
                    .frame(width: 40, height: 35)
                    .padding(.bottom, 3)
                
            }
        }
        .overlay (
            RoundedRectangle(cornerRadius: 100)
                .stroke(Color.ui.orangeWeb, lineWidth: 2)
        )
    }
}
