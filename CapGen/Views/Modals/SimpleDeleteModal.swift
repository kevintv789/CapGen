//
//  SimpleDeleteModal.swift
//  CapGen
//
//  Created by Kevin Vu on 2/24/23.
//

import SwiftUI

struct SimpleDeleteModal: View {
    @Binding var showView: Bool
    let title: String
    let buttonTitle: String
    var onDelete: () -> Void

    var body: some View {
        ZStack {
            Color.ui.cultured.ignoresSafeArea()

            VStack(alignment: .center, spacing: 20) {
                Text(title)
                    .foregroundColor(.ui.richBlack)
                    .font(.ui.title4)
                    .lineSpacing(5)
                    .multilineTextAlignment(.center)
                    .padding(.bottom)

                VStack(spacing: 20) {
                    Button {
                        showView = false
                        Haptics.shared.play(.soft)
                    } label: {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.ui.darkerPurple)
                            .frame(width: SCREEN_WIDTH / 1.4, height: 55)
                            .overlay(
                                Text("Cancel")
                                    .foregroundColor(.ui.cultured)
                                    .font(.ui.title2)
                            )
                    }

                    Button {
                        onDelete()
                        showView = false
                        Haptics.shared.play(.soft)
                    } label: {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.ui.dangerRed, lineWidth: 2)
                            .frame(width: SCREEN_WIDTH / 1.4, height: 55)
                            .overlay(
                                Text(buttonTitle)
                                    .foregroundColor(.ui.dangerRed)
                                    .font(.ui.title2)
                            )
                    }
                }
            }
        }
    }
}
