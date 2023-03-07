//
//  FolderView.swift
//  CapGen
//
//  Created by Kevin Vu on 2/21/23.
//

import NavigationStack
import SwiftUI

enum FolderViewContext {
    case saveToFolder, view
}

struct FolderGridView: View {
    @EnvironmentObject var firestoreMan: FirestoreManager
    @EnvironmentObject var folderVm: FolderViewModel
    @EnvironmentObject var navStack: NavigationStackCompat
    @EnvironmentObject var captionVm: CaptionViewModel

    @State var showFolderBottomSheet: Bool = false
    @State var folders: [FolderModel] = []
    @State var isEditing: Bool = false

    // Nav
    @State var router: Router? = nil

    // Context to determine determine logic
    // View context - Original context for HomeView. On click of folder will navigate user to the folder view
    // saveToFolder context - On click of folder will add a caption to the folder
    var context: FolderViewContext = .view

    // Disable all tap actions, important if the system is currently processing something
    @Binding var disableTap: Bool

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
                .disabled(disableTap)
                .padding(.top, 20)

                .padding(.top, 20)
                ForEach(Array(folders.enumerated()), id: \.element) { index, folder in
                    HStack(spacing: 0) {
                        FolderButtonView(folder: self.$folders[index], context: context) {
                            // Depending on context, do different things on click
                            if context == .view {
                                self.navStack.push(FolderView(folder: self.$folders[index]))
                            } else if context == .saveToFolder {
                                // The index of the already saved caption
                                let indexOfSavedCaption = self.folderVm.captionFolderStorage.firstIndex(where: { $0.id == folder.id && $0.caption.captionDescription == self.captionVm.selectedCaption.captionDescription }) ?? -1

                                if indexOfSavedCaption < 0 {
                                    // On click, append the saved caption to a temp storage array
                                    self.folderVm.captionFolderStorage.append(DestinationFolder(id: folder.id, caption: self.captionVm.selectedCaption))
                                } else {
                                    // On click again, remove that caption from the folder
                                    self.folderVm.captionFolderStorage.remove(at: indexOfSavedCaption)
                                }
                            }
                        }
                        .disabled(disableTap)

                        CustomMenuPopup(menuTheme: .dark, orientation: .vertical, shareableData: .constant(nil), socialMediaPlatform: .constant(nil), size: .medium, opacity: 0.25,
                                        edit: {
                                            // on edit, show bottom sheet with identifying information
                                            folderVm.currentFolder = folder
                                            self.isEditing = true
                                            self.showFolderBottomSheet = true

                                        }, delete: {
                                            // on delete, remove from firebase
                                            folderVm.currentFolder = folder
                                            folderVm.isDeleting.toggle()
                                        })
                                        .disabled(disableTap)
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
        .onAppear {
            self.router = Router(navStack: navStack)
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
    @EnvironmentObject var folderVm: FolderViewModel
    @State var filteredFolder: [DestinationFolder] = []

    @Binding var folder: FolderModel
    var context: FolderViewContext
    var action: () -> Void

    // Update caption count UI if there are items still within the temp storage
    // Only update within folders with the same ID and caption
    // Once folders are saved, then re-calculate how many captions are in each folder

    private func calcCountOfCaptions() -> String {
        let count = folder.captions.count + filteredFolder.count

        if count < 1000 {
            return "\(count)"
        }

        return "999+"
    }

    var body: some View {
        Button {
            withAnimation {
                Haptics.shared.play(.soft)
                action()
            }
        } label: {
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

                    if self.filteredFolder.count > 0 {
                        Text("\(calcCountOfCaptions())")
                            .font(.ui.headlineMd)
                            .foregroundColor(.ui.cultured)
                            .padding(.horizontal, 5)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 100)
                                        .stroke(Color.ui.cultured, lineWidth: 4)
                                        .shadow(color: .ui.richBlack.opacity(0.5), radius: 3, x: 0, y: 2)

                                    RoundedRectangle(cornerRadius: 100)
                                        .fill(Color.ui.darkerPurple)
                                }
                                .frame(minWidth: 20, minHeight: 20)
                                .frame(maxWidth: 150, maxHeight: 20)
                            )

                            .padding(35)
                            .padding(.trailing, -10)

                    } else {
                        Text("\(folder.captions.count)")
                            .padding(30)
                            .padding(.trailing, -5)
                            .font(.ui.headlineMd)
                            .foregroundColor(.ui.richBlack.opacity(0.5))
                    }
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
        .onReceive(folderVm.$captionFolderStorage) { list in
            if context == .saveToFolder {
                // filter out to the correct folder
                self.filteredFolder = list.filter { $0.id == folder.id }
            }
        }
    }
}
