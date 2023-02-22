//
//  PrimaryButtonView.swift
//  CapGen
//
//  Created by Kevin Vu on 2/22/23.
//

import SwiftUI

struct PrimaryButtonView: View {
    let title: String
    @Binding var isLoading: Bool
    var action: () -> Void
    
    func displayBtnOverlay() -> some View {
        if isLoading {
            return AnyView(
                LottieView(name: "btn_loader", loopMode: .loop, isAnimating: true)
                    .frame(width: 100, height: 100)
            )
        } else {
            return AnyView(
                Text("Save")
                    .foregroundColor(.ui.cultured)
                    .font(.ui.title2)
            )
        }
    }
    
    var body: some View {
        Button {
            Haptics.shared.play(.soft)
            action()
        } label: {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.ui.darkerPurple)
                .shadow(color: Color.ui.shadowGray, radius: 2, x: 3, y: 4)
                .overlay(displayBtnOverlay())
        }
        .disabled(self.isLoading)
    }
}
