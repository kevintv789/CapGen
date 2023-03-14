//
//  FolderView.swift
//  CapGen
//
//  Created by Kevin Vu on 2/24/23.
//
// This view is directly from inside a folder

import NavigationStack
import SwiftUI

func mapShareableDataFromCaptionList(captions: [CaptionModel]) -> ShareableData {
    var item: String {
        """
        Behold the precious captions I generated from ⚡CapGen⚡:

        \(captions.enumerated().map { index, caption in
            "\(index + 1). \(caption.captionDescription)"
        }.joined(separator: "\n\n"))
        """
    }

    return ShareableData(item: item, subject: "Check out my captions from CapGen!")
}

struct FolderView: View {
    @ScaledMetric var scaledSize: CGFloat = 1
    @EnvironmentObject var folderVm: FolderViewModel
    @EnvironmentObject var firestoreManager: FirestoreManager
    @EnvironmentObject var navStack: NavigationStackCompat

    // private variables
    @State var showFolderBottomSheet: Bool = false
    @State var showFolderDeleteModal: Bool = false
    @State var showCaptionDeleteModal: Bool = false

    // dependencies
    @State var folder: FolderModel

    // Necessary to share data from the custom menu
    @State var shareableData: ShareableData? = nil

    var body: some View {
        ZStack {
            Color.ui.lavenderBlue.ignoresSafeArea()

            VStack {
                // Header
                FolderHeaderView(platform: $folder.folderType, shareableData: self.$shareableData) {
                    // on edit
                    self.showFolderBottomSheet.toggle()
                    folderVm.currentFolder = folder
                } onMenuOpen: {
                    self.shareableData = mapShareableDataFromCaptionList(captions: folder.captions)
                } onDelete: {
                    // on delete
                    self.showFolderDeleteModal = true
                } onBack: {
                    // reset updated folder
                    folderVm.updatedFolder = nil
                    self.navStack.pop(to: .previous)
                }

                // Folder title
                Button {
                    // on edit
                    folderVm.currentFolder = folder

                    // Set a delay to show bottom sheet
                    // This is a direct result of having the custom menu opened right before pressing this button
                    // which will result in a "View is already presented" error
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.showFolderBottomSheet.toggle()
                    }

                } label: {
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
                }
                .padding(.leading)

                CaptionListView(emptyTitle: "Oops, it looks like you haven't saved any captions to this folder yet.", folderId: folder.id, context: .folder, showCaptionDeleteModal: $showCaptionDeleteModal)
                    .padding()

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
            DeleteModalView(title: "Remove folder", subTitle: "Deleting this folder will permanently erase all of its contents. Are you sure you want to proceed? 🫢", lottieFile: "crane_hand_lottie", showView: $showFolderDeleteModal, onDelete: {
                if !self.folder.name.isEmpty {
                    let uid = AuthManager.shared.userManager.user?.id ?? nil
                    let currentFolders = AuthManager.shared.userManager.user?.folders ?? []

                    firestoreManager.onFolderDelete(for: uid, curFolder: self.folder, currentFolders: currentFolders) {
                        // Once deleted, dismiss view or pop back to previous view
                        self.navStack.pop(to: .previous)
                    }
                }

            })
        } onClickExit: {
            withAnimation {
                self.showFolderDeleteModal = false
            }
        }
        // Show caption delete modal
        .modalView(horizontalPadding: 40, show: $showCaptionDeleteModal) {
            DeleteModalView(title: "Delete caption", subTitle: "Are you sure you want to delete this caption? 🫢 This action cannot be undone.", lottieFile: "crane_hand_lottie", showView: $showCaptionDeleteModal, onDelete: {
                if let user = AuthManager.shared.userManager.user, let captionToBeRemoved = folderVm.captionToBeDeleted {
                    let uid = user.id
                    firestoreManager.deleteSingleCaption(for: uid, captionToBeRemoved: captionToBeRemoved) {
                        withAnimation {
                            folderVm.resetCaptionToBeDeleted()
                            self.showCaptionDeleteModal = false
                        }
                    }
                }
            })
        } onClickExit: {
            withAnimation {
                self.showCaptionDeleteModal = false
            }
        }
    }
}

struct FolderView_Previews: PreviewProvider {
    static var previews: some View {
        FolderView(folder: foldersMock[0])
            .environmentObject(FolderViewModel())
            .environmentObject(FirestoreManager())
            .environmentObject(NavigationStackCompat())

        FolderView(folder: foldersMock[0])
            .environmentObject(FolderViewModel())
            .environmentObject(FirestoreManager())
            .environmentObject(NavigationStackCompat())
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE (3rd generation)")
    }
}

struct FolderHeaderView: View {
    @ScaledMetric var scaledSize: CGFloat = 1
    @Binding var platform: FolderType
    @Binding var shareableData: ShareableData?

    let onEdit: () -> Void
    let onMenuOpen: () -> Void
    let onDelete: () -> Void
    let onBack: () -> Void

    var body: some View {
        // Header
        HStack {
            BackArrowView {
                onBack()
            }
            .padding(.leading, 8)

            Spacer()

            if platform != .General {
                Image("\(platform)-circle")
                    .resizable()
                    .frame(width: 20 * scaledSize, height: 20 * scaledSize)
            }

            Text(platform.rawValue)
                .foregroundColor(.ui.richBlack)
                .font(.ui.headline)
                .scaledToFit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Spacer()

            CustomMenuPopup(menuTheme: .dark, orientation: .horizontal, shareableData: $shareableData, socialMediaPlatform: .constant(nil), edit: { onEdit() }, delete: { onDelete() }, onMenuOpen: { onMenuOpen() })
                .padding(.horizontal)
        }
        .padding(.bottom, 20)
    }
}
