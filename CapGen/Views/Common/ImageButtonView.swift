//
//  ImageButtonView.swift
//  CapGen
//
//  Created by Kevin Vu on 2/21/23.
//

import SwiftUI

struct ImageButtonView: View {
    @ScaledMetric var scaledSize: CGFloat = 1

    let imgName: String
    var action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Image(imgName)
                .resizable()
                .frame(width: 25 * self.scaledSize, height: 25 * self.scaledSize)
        }
    }
}
