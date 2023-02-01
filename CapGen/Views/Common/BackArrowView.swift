//
//  BackArrowView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/14/23.
//

import SwiftUI
import NavigationStack

struct BackArrowView: View {
    var action: (() -> Void)?
    
    var body: some View {
        if (action != nil) {
            Button {
                action!()
                Haptics.shared.play(.medium)
            } label: {
                Image("back_arrow")
                    .resizable()
                    .frame(width: 50, height: 40)
            }
        } else {
            PopView(destination: .previous) {
                Image("back_arrow")
                    .resizable()
                    .frame(width: 50, height: 40)
            }
            .simultaneousGesture(TapGesture().onEnded({ _ in
                Haptics.shared.play(.medium)
            }))
        }
    }
}
