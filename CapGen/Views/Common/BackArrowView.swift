//
//  BackArrowView.swift
//  CapGen
//
//  Created by Kevin Vu on 1/14/23.
//

import SwiftUI

struct BackArrowView: View {
    var action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            Image("back_arrow")
                .resizable()
                .frame(width: 50, height: 40)
        }
    }
}
