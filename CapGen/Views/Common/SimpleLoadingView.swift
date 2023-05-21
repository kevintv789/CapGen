//
//  SimpleLoadingView.swift
//  CapGen
//
//  Created by Kevin Vu on 3/11/23.
//

import SwiftUI

enum LoadingTheme {
    case white, black
}

struct SimpleLoadingView: View {
    @ScaledMetric var scaledSize: CGFloat = 1
    let title: String
    var loadTheme: LoadingTheme = .black

    var body: some View {
        VStack(alignment: .center) {
            ProgressView()
                .scaleEffect(scaledSize, anchor: .center)
                .progressViewStyle(CircularProgressViewStyle(tint: loadTheme == .black ? Color.ui.richBlack : Color.ui.cultured))
                .padding(.bottom, 40)

            Text(title)
                .font(.ui.headline)
                .foregroundColor(loadTheme == .black ? Color.ui.richBlack : Color.ui.cultured)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

struct SimpleLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        SimpleLoadingView(title: "Saving...")
    }
}
