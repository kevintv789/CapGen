//
//  CustomMenuPopup.swift
//  CapGen
//
//  Created by Kevin Vu on 1/24/23.
//

import SwiftUI

struct CustomMenuPopup: View {
    var edit: () -> Void
    var share: () -> Void
    var delete: () -> Void
    
    var body: some View {
        Menu {
            Button(action: { edit() }) {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(action: { share() }) {
                Label("Share", systemImage: "arrowshape.turn.up.right")
            }
            
            Button(role: .destructive, action: { delete() }) {
                Label("Delete", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .rotationEffect(.degrees(90))
                .font(.ui.title)
                .foregroundColor(.ui.cultured)
                .contentShape(Rectangle().inset(by: -100))
        }
        .contentShape(Rectangle().inset(by: -100))
    }
}
