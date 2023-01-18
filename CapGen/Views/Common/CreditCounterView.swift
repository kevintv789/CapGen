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
        } label : {
            RoundedRectangle(cornerRadius: 100)
                .stroke(Color.ui.orangeWeb, lineWidth: 2)
                .overlay(
                    HStack(alignment: .center, spacing: 0) {
                        Text("\(credits > 1 ? "Credits" : "Credit"): \(credits > 100 ? "100+" : "\(credits)")")
                            .font(.ui.headline)
                            .foregroundColor(.ui.orangeWeb)
                            .padding(.leading, 10)
                        
                        Image("coin-icon")
                            .resizable()
                            .frame(width: 50, height: 40)
                            .padding(.bottom, 3)
                        
                    }
                )
        }
    }
}
