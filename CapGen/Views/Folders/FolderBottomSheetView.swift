//
//  FolderBottomSheetView.swift
//  CapGen
//
//  Created by Kevin Vu on 2/22/23.
//  Used for creation and editing a folder

import Heap
import SwiftUI

struct FolderBottomSheetView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var firestoreMan: FirestoreManager

    @State var title: String = "Create your folder"

    // If the user is going to edit the folder
    @Binding var isEditing: Bool
    @State var folder: FolderModel? = nil

    @State var folderName: String = ""
    @State var selectedPlatform: FolderType = .General // default selected
    @State var isLoading: Bool = false
    @State var isFolderNameError: Bool = false

    private func onSubmit() {
        isFolderNameError = false

        if folderName.isEmpty {
            isFolderNameError = true
            return
        }

        isLoading = true

        // Call API to update firebase
        if let user = AuthManager.shared.userManager.user {
            let userId = user.id

            // calculates index based off current amount of folders
            let newFolder = FolderModel(name: folderName, folderType: selectedPlatform, captions: [], index: user.folders.count)

            if !isEditing {
                // Creating a new folder
                firestoreMan.saveFolder(for: userId, folder: newFolder) {
                    self.isLoading = false
                    FolderViewModel.shared.folders.append(newFolder)
                    Heap.track("Successfully created folder", withProperties: ["folderId": newFolder.id, "folderName": newFolder.name, "folderType": newFolder.folderType.rawValue])
                    dismiss()
                }
            } else {
                // Editing a folder
                if let curFolder = folder {
                    var currFolders = AuthManager.shared.userManager.user?.folders ?? []
                    let updatedFolder = FolderModel(id: curFolder.id, name: folderName, dateCreated: curFolder.dateCreated, folderType: selectedPlatform, captions: curFolder.captions, index: curFolder.index)

                    firestoreMan.updateFolder(for: userId, newFolder: updatedFolder, currentFolders: &currFolders) { updatedFolder in
                        if let updatedFolder = updatedFolder {
                            FolderViewModel.shared.editedFolder = updatedFolder
                            FolderViewModel.shared.updatedFolder = updatedFolder
                            FolderViewModel.shared.folders = currFolders
                        }

                        self.isLoading = false
                        dismiss()
                    }
                }
            }
        }
    }

    var body: some View {
        ZStack {
            Color.ui.cultured.ignoresSafeArea()

            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack {
                        Text(title)
                            .font(.ui.largeTitleSm)
                            .foregroundColor(.ui.richBlack)
                            .padding(.bottom, 40)

                        // Folder name input
                        FolderNameInput(folderName: $folderName, isError: $isFolderNameError)
                            .padding(.bottom, 20)
                            .onSubmit {
                                withAnimation {
                                    scrollProxy.scrollTo("submit-btn", anchor: .bottom)
                                }
                            }

                        // Choose a platform 3x3 grid
                        PlatformGridView(selectedPlatform: $selectedPlatform)

                        // Submit button
                        PrimaryButtonView(title: "Create", isLoading: $isLoading) {
                            // Run API to create the specified folder
                            onSubmit()
                        }
                        .id("submit-btn")
                        .frame(width: SCREEN_WIDTH * 0.8, height: 55)
                        .padding(.top)

                        Spacer()
                    }
                    .padding()
                }
            }
        }
        .onReceive(FolderViewModel.shared.$currentFolder) { folder in
            if !folder.name.isEmpty, isEditing {
                self.folder = folder
                self.title = "Edit folder"
                self.selectedPlatform = folder.folderType
                self.folderName = folder.name
            }
        }
    }
}

struct FolderNameInput: View {
    @Binding var folderName: String
    @Binding var isError: Bool

    var body: some View {
        VStack {
            Text("Folder name (required)")
                .foregroundColor(isError ? .ui.dangerRed : .ui.cadetBlueCrayola)
                .font(.ui.headline)

            RoundedRectangle(cornerRadius: 14)
                .fill(isError ? .ui.dangerRed.opacity(0.3) : Color.ui.lighterLavBlue)
                .opacity(0.4)
                .frame(width: SCREEN_WIDTH * 0.8, height: 51)
                .overlay(
                    HStack(spacing: 0) {
                        TextField("", text: $folderName)
                            .submitLabel(.next)
                            .padding()
                            .placeholder(when: folderName.isEmpty) {
                                Text("Enter a folder name")
                                    .font(.ui.headlineMd)
                                    .foregroundColor(.ui.cadetBlueCrayola)
                                    .padding()
                            }
                            .foregroundColor(.ui.richBlack)

                        if !folderName.isEmpty {
                            Button {
                                Haptics.shared.play(.soft)
                                folderName.removeAll()
                            } label: {
                                Image(systemName: "x.circle.fill")
                                    .font(.ui.headline)
                                    .foregroundColor(.ui.cadetBlueCrayola)
                            }
                            .padding(.trailing)
                        }
                    }
                )
        }
    }
}

struct PlatformGridView: View {
    @ScaledMetric var scaledSize: CGFloat = 1
    @Binding var selectedPlatform: FolderType
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        VStack {
            Text("Choose a platform")
                .foregroundColor(.ui.cadetBlueCrayola)
                .font(.ui.headline)
                .padding(.bottom)

            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(socialMediaPlatforms) { platform in
                    Button {
                        self.selectedPlatform = FolderType(rawValue: platform.title)!
                    } label: {
                        VStack(spacing: 10) {
                            Image("\(platform.title)-circle")
                                .resizable()
                                .frame(width: 35 * scaledSize, height: 35 * scaledSize)
                                .background(
                                    ZStack(alignment: .topTrailing) {
                                        if self.selectedPlatform == FolderType(rawValue: platform.title)! {
                                            Circle()
                                                .strokeBorder(Color.ui.middleBluePurple, lineWidth: 3)

                                            Circle()
                                                .fill(Color.ui.middleBluePurple)
                                                .overlay(
                                                    Image("checkmark-white")
                                                        .resizable()
                                                        .foregroundColor(.ui.cultured)
                                                        .frame(width: 10 * scaledSize, height: 10 * scaledSize)
                                                )
                                                .frame(width: 22 * scaledSize, height: 22 * scaledSize)
                                        }
                                    }
                                    .frame(width: 65 * scaledSize, height: 65 * scaledSize)
                                )
                                .padding(10)

                            Text(platform.title)
                                .foregroundColor(self.selectedPlatform == FolderType(rawValue: platform.title)! ? .ui.middleBluePurple : .ui.lighterLavBlue)
                                .font(.ui.headline)
                        }
                    }
                }
            }
        }
    }
}
