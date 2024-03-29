//
//  CustomMenuPopup.swift
//  CapGen
//
//  Created by Kevin Vu on 1/24/23.
//

import Heap
import SwiftUI

enum MenuTheme {
    case light, dark
}

enum Orientation {
    case vertical, horizontal
}

enum Size {
    case large, medium
}

struct CustomMenuPopup: View {
    @State var menuTheme: MenuTheme = .light
    @State var orientation: Orientation = .vertical
    @Binding var shareableData: ShareableData?
    @Binding var socialMediaPlatform: String?
    @State var size: Size = .large
    @State var opacity: CGFloat = 1
    var edit: (() -> Void)?
    var copy: (() -> Void)?
    var delete: (() -> Void)?
    var reset: (() -> Void)?
    var onMenuOpen: (() -> Void)?
    var onCopyAndGo: (() -> Void)?

    var body: some View {
        Menu {
            if edit != nil {
                Button(action: {
                    Haptics.shared.play(.soft)
                    edit!(
                    )
                }) {
                    Label("Edit", systemImage: "pencil")
                }
            }

            if copy != nil {
                Button(action: { copy!(); Haptics.shared.play(.soft) }) {
                    Label("Copy", systemImage: "doc.on.doc")
                }
            }

            if shareableData != nil {
                ShareLink(item: shareableData!.item, subject: Text(shareableData!.subject)) {
                    Label("Share", systemImage: "arrowshape.turn.up.right")
                }
            }

            if socialMediaPlatform != nil && onCopyAndGo != nil {
                Button {
                    Haptics.shared.play(.soft)
                    onCopyAndGo!()
                } label: {
                    HStack {
                        Image(socialMediaPlatform!)
                        Text("Copy & Go")
                    }
                }
            }

            if delete != nil {
                Button(role: .destructive, action: { delete!(); Haptics.shared.play(.soft) }) {
                    Label("Delete", systemImage: "trash")
                }
            }

            if reset != nil {
                Button(role: .destructive, action: { reset!(); Haptics.shared.play(.soft) }) {
                    Label("Reset", systemImage: "arrow.clockwise")
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .rotationEffect(orientation == .vertical ? .degrees(90) : .degrees(0))
                .font(size == .large ? .ui.title : .ui.title2)
                .foregroundColor(menuTheme == .light ? .ui.cultured.opacity(opacity) : .ui.richBlack.opacity(opacity))
                .frame(width: 50, height: 50)
        }
        .onTapGesture {
            if onMenuOpen != nil {
                onMenuOpen!()
            }

            Haptics.shared.play(.soft)
        }
    }
}
