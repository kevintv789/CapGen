//
//  FolderView.swift
//  CapGen
//
//  Created by Kevin Vu on 2/21/23.
//

import SwiftUI

struct FolderView: View {
    @State var showCreateFolderBottomSheet: Bool = true

    let data = (1 ... 3).map { "Item \($0)" }

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(Array(data.enumerated()), id: \.element) { index, data in
                    if index == 0 {
                        AddFolderButtonView {
                            Haptics.shared.play(.soft)

                            // show bottom sheet
                            self.showCreateFolderBottomSheet = true
                        }
                    }
                    Text(data)
                }
                .padding()
            }
        }
        .sheet(isPresented: $showCreateFolderBottomSheet) {
            FolderBottomSheetView(isEditing: false)
                .presentationDetents([.fraction(0.8)])
        }
    }
}

struct AddFolderButtonView: View {
    var action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 30) {
                Image(systemName: "plus")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.ui.cultured)
                    .background(
                        Circle()
                            .fill(Color.ui.lighterLavBlue)
                            .frame(width: 60, height: 60)
                            .shadow(color: .ui.richBlack.opacity(0.35), radius: 3, x: 1, y: 2)
                    )

                Text("Create folder")
                    .foregroundColor(.ui.richBlack).opacity(0.5)
                    .font(.ui.headlineMd)
            }
        }
    }
}
