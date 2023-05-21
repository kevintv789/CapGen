//
//  BackArrowView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/14/23.
//

import Heap
import NavigationStack
import SwiftUI

struct BackArrowView: View {
    var action: (() -> Void)?

    var body: some View {
        if action != nil {
            Button {
                Heap.track("onClick BackArrowView - Back button clicked")
                action!()
                Haptics.shared.play(.soft)
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
            .simultaneousGesture(TapGesture().onEnded { _ in
                Heap.track("onClick BackArrowView - Back button clicked")
                Haptics.shared.play(.soft)
            })
        }
    }
}
