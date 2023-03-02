//
//  FolderView.swift
//  CapGen
//
//  Created by Kevin Vu on 2/24/23.
//

import NavigationStack
import SwiftUI

struct FolderView: View {
    @ScaledMetric var scaledSize: CGFloat = 1
    @EnvironmentObject var folderVm: FolderViewModel
    @EnvironmentObject var firestoreManager: FirestoreManager
    @EnvironmentObject var navStack: NavigationStackCompat

    // private variables
    @State var showFolderBottomSheet: Bool = false
    @State var showFolderDeleteModal: Bool = false

    // dependencies
    @Binding var folder: FolderModel

    var body: some View {
        ZStack {
            Color.ui.lavenderBlue.ignoresSafeArea()

            VStack {
                // Header
                FolderHeaderView(platform: folder.folderType.rawValue, shareableData: .constant(nil)) {
                    // on edit
                    self.showFolderBottomSheet = true
                    folderVm.currentFolder = folder
                } onDelete: {
                    // on delete
                    self.showFolderDeleteModal = true
                }

                // Folder title
                HStack {
                    Image("empty_folder_white")
                        .resizable()
                        .frame(width: 38 * scaledSize, height: 38 * scaledSize, alignment: .topLeading)

                    Text(folder.name)
                        .font(.ui.title4Medium)
                        .foregroundColor(.ui.cultured)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 5)

                    Spacer()
                }
                .padding(.leading)

                if folder.captions.isEmpty {
                    // Empty folder view
                    BlankCaptionsView(title: "Oops, it looks like you haven't saved any captions to this folder yet.")
                } else {
                    // Populated folder view
                    ScrollView {
                        ForEach(self.folder.captions) { caption in
                            CaptionCardView(caption: caption)
                                .padding(10)
                                .padding(.horizontal, 10)
                        }
                    }
                    .padding(.top)
                }

                Spacer()
            }
        }
        .sheet(isPresented: $showFolderBottomSheet) {
            FolderBottomSheetView(isEditing: .constant(true))
                .presentationDetents([.fraction(0.8)])
        }
        .onReceive(folderVm.$editedFolder) { editedFolder in
            if !editedFolder.name.isEmpty {
                // Update folder in view so that this view will receive any incoming changes on edit of folder
                self.folder = editedFolder
            }
        }
        // Show folder delete modal
        .modalView(horizontalPadding: 40, show: $showFolderDeleteModal) {
            DeleteModalView(title: "Remove folder", subTitle: "Deleting this folder will permanently erase all its contents. Are you sure you want to proceed? 🫢", lottieFile: "crane_hand_lottie", showView: $showFolderDeleteModal, onDelete: {
                if !self.folder.name.isEmpty {
                    let uid = AuthManager.shared.userManager.user?.id ?? nil
                    let currentFolders = AuthManager.shared.userManager.user?.folders ?? []

                    Task {
                        await firestoreManager.onFolderDelete(for: uid, curFolder: self.folder, currentFolders: currentFolders) {
                            // Once deleted, dismiss view or pop back to previous view
                            self.navStack.pop(to: .previous)
                        }
                    }
                }

            })
        } onClickExit: {
            withAnimation {
                self.showFolderDeleteModal = false
            }
        }
    }
}

struct FolderView_Previews: PreviewProvider {
    static var previews: some View {
        FolderView(folder: .constant(foldersMock[0]))
            .environmentObject(FolderViewModel())
            .environmentObject(FirestoreManager())
            .environmentObject(NavigationStackCompat())

        FolderView(folder: .constant(foldersMock[0]))
            .environmentObject(FolderViewModel())
            .environmentObject(FirestoreManager())
            .environmentObject(NavigationStackCompat())
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE (3rd generation)")
    }
}

struct FolderHeaderView: View {
    @ScaledMetric var scaledSize: CGFloat = 1
    let platform: String
    @Binding var shareableData: ShareableData?

    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        // Header
        HStack {
            BackArrowView()
                .padding(.leading, 8)

            Spacer()

            if platform != "General" {
                Image("\(platform)-circle")
                    .resizable()
                    .frame(width: 20 * scaledSize, height: 20 * scaledSize)
            }

            Text(platform)
                .foregroundColor(.ui.richBlack)
                .font(.ui.headline)
                .scaledToFit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Spacer()

            CustomMenuPopup(menuTheme: .dark, orientation: .horizontal, shareableData: $shareableData, edit: { onEdit() }, delete: { onDelete() })
                .padding(.horizontal)
        }
        .padding(.bottom, 20)
    }
}
