//
//  FolderView.swift
//  CapGen
//
//  Created by Kevin Vu on 2/21/23.
//

import NavigationStack
import SwiftUI

struct FolderGridView: View {
    @EnvironmentObject var firestoreMan: FirestoreManager
    @EnvironmentObject var folderVm: FolderViewModel

    @State var showFolderBottomSheet: Bool = false
    @State var folders: [FolderModel] = []
    @State var isEditing: Bool = false

    let columns = [
        GridItem(.flexible(minimum: 10), spacing: 0),
        GridItem(.flexible(minimum: 10), spacing: 0),
        GridItem(.flexible(minimum: 10), spacing: 0),
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                AddFolderButtonView {
                    Haptics.shared.play(.soft)

                    // show bottom sheet
                    self.isEditing = false
                    self.showFolderBottomSheet = true
                }
                .padding(.top, 20)

                .padding(.top, 20)
                ForEach(Array(folders.enumerated()), id: \.element) { _, data in
                    HStack(spacing: 0) {
                        FolderButtonView(folder: data)

                        CustomMenuPopup(menuTheme: .dark, orientation: .vertical, shareableData: .constant(nil), size: .medium, opacity: 0.25,
                                        edit: {
                                            // on edit, show bottom sheet with identifying information
                                            folderVm.currentFolder = data
                                            self.isEditing = true
                                            self.showFolderBottomSheet = true

                                        }, delete: {
                                            // on delete, remove from firebase
                                            folderVm.currentFolder = data
                                            folderVm.isDeleting.toggle()
                                        })

                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                        .padding(.leading, -33)
                                        .padding(.top)
                    }
                }
                .padding(.bottom, -10)
            }
        }
        .sheet(isPresented: $showFolderBottomSheet) {
            FolderBottomSheetView(isEditing: $isEditing)
                .presentationDetents([.fraction(0.8)])
        }
        .onReceive(AuthManager.shared.userManager.$user) { user in
            if let user = user {
                self.folders = user.folders

                // Resets selected folder back to nil so that the bottom sheet wil only retain most updated data
                folderVm.resetFolder()
            }
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

struct FolderButtonView: View {
    @State var folder: FolderModel

    var body: some View {
        PushView(destination: FolderView(folder: $folder)) {
            VStack(spacing: 0) {
                ZStack(alignment: .bottomTrailing) {
                    Image("main_folder")
                        .resizable()
                        .frame(width: 120, height: 120)
                        .overlay(
                            ZStack(alignment: .topLeading) {
                                // Renders the social media platform image
                                HStack {
                                    if folder.folderType != .General {
                                        Image("\(folder.folderType.rawValue)-circle")
                                            .resizable()
                                            .frame(width: 25, height: 25)
                                            .background(
                                                Circle()
                                                    .fill(Color.ui.cultured)
                                                    .frame(width: 35, height: 35)
                                            )
                                            .padding(30)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                            .padding(.top, 5)
                                    }
                                }
                            }
                        )

                    Text("\(folder.captions.count)")
                        .padding(30)
                        .padding(.trailing, -5)
                        .font(.ui.headlineMd)
                        .foregroundColor(.ui.richBlack.opacity(0.5))
                }

                Text(folder.name)
                    .font(.ui.headlineMd)
                    .foregroundColor(.ui.richBlack).opacity(0.5)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.top, -15)

                Spacer()
            }
        }
        .simultaneousGesture(TapGesture().onEnded { _ in
            Haptics.shared.play(.soft)
        })
    }
}
