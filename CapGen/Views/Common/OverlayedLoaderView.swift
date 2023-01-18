//
//  LoaderView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/18/23.
//

import SwiftUI

struct OverlayedLoaderView: View {
    var body: some View {
        ZStack {
            Color.ui.cultured.ignoresSafeArea()
            
            VStack {
                LottieView(name: "lightbulb_loader_lottie", loopMode: .loop, isAnimating: true)
                    .frame(width: 300, height: 300)
                    .padding(-50)
                
                Text("Loading the goods")
                    .foregroundColor(.ui.richBlack)
                    .font(.ui.title2)
                    .padding(.bottom, 15)
            }
            
        }
    }
}
