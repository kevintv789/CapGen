//
//  CustomMenuPopup.swift
//  CapGen
//
//  Created by Kevin Vu on 1/24/23.
//

import SwiftUI

enum MenuTheme {
    case light, dark
}

enum Orientation {
    case vertical, horizontal
}

struct CustomMenuPopup: View {
    @State var menuTheme: MenuTheme = .light
    @State var orientation: Orientation = .vertical
    @Binding var shareableData: ShareableData?
    var edit: (() -> Void)?
    var copy: (() -> Void)?
    var delete: (() -> Void)?
    var reset: (() -> Void)?
    var onMenuOpen: (() -> Void)?
    
    var body: some View {
        Menu {
            if (edit != nil) {
                Button(action: { edit!() }) {
                    Label("Edit", systemImage: "pencil")
                }
            }
            
            if (copy != nil) {
                Button(action: { copy!() }) {
                    Label("Copy", systemImage: "doc.on.doc")
                }
            }
           
            if (shareableData != nil) {
                ShareLink(item: shareableData!.item, subject: Text(shareableData!.subject)) {
                    Label("Share", systemImage: "arrowshape.turn.up.right")
                }
            }
            
            if (delete != nil) {
                Button(role: .destructive, action: { delete!() }) {
                    Label("Delete", systemImage: "trash")
                }
            }
            
            if (reset != nil) {
                Button(role: .destructive, action: { reset!() }) {
                    Label("Reset", systemImage: "arrow.clockwise")
                }
            }
            
        } label: {
            Image(systemName: "ellipsis")
                .rotationEffect(orientation == .vertical ? .degrees(90) : .degrees(0))
                .font(.ui.title)
                .foregroundColor(menuTheme == .light ? .ui.cultured : .ui.richBlack)
                .frame(width: 50, height: 50)
        }
        .onTapGesture {
            if (onMenuOpen != nil) {
                onMenuOpen!()
            }
        }
    }
}