//
//  ImageThumbnailView.swift
//  CapGen
//
//  Created by Kevin Vu on 5/1/23.
//

import SwiftUI

struct ImageThumbnailView: View {
    let uiImage: UIImage
    var showShadow: Bool = true
    let action: () -> Void
    
    var body: some View {
        Button {
            // On thumbnail image press
            action()
        } label: {
            Image(uiImage: uiImage)
                .resizable()
                .cornerRadius(100)
                .if(showShadow, transform: { view in
                    return view.customShadow()
                })
                .frame(width: 60, height: 60)
                .aspectRatio(contentMode: .fill)
                .padding(.bottom)
        }
    }
}
