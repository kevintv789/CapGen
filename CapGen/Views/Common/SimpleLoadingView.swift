//
//  SimpleLoadingView.swift
//  CapGen
//
//  Created by Kevin Vu on 3/11/23.
//

import SwiftUI

struct SimpleLoadingView: View {
    @ScaledMetric var scaledSize: CGFloat = 1
    let title: String

    var body: some View {
        VStack(alignment: .center) {
            ProgressView()
                .scaleEffect(scaledSize, anchor: .center)
                .progressViewStyle(CircularProgressViewStyle(tint: Color.ui.richBlack))
                .padding(.bottom, 40)

            Text(title)
                .font(.ui.headline)
                .foregroundColor(.ui.richBlack)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

struct SimpleLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        SimpleLoadingView(title: "Saving...")
    }
}
