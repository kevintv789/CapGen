//
//  LogoView.swift
//  CapGen
//
//  Created by Kevin Vu on 2/20/23.
//

import SwiftUI

struct LogoView: View {
    var body: some View {
        HStack {
            Image("appIcon-ref")
                .resizable()
                .frame(width: 30, height: 30)
            
            Text("CapGen")
                .font(.ui.headline)
                .foregroundColor(.ui.richBlack)
        }
    }
}
