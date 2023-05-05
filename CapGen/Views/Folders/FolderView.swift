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
    @EnvironmentObject var firestoreManager: FirestoreManager
    @EnvironmentObject var navStack: NavigationStackCompat
    @StateObject var folderVm: FolderViewModel
    @EnvironmentObject var photoSelectionVm: PhotoSelectionViewModel

    // private variables
    @State var showFolderBottomSheet: Bool = false
    @State var showFolderDeleteModal: Bool = false
    @State var showCaptionDeleteModal: Bool = false
    
    // Necessary to share data from the custom menu
    @State var shareableData: ShareableData? = nil

    var body: some View {
        ZStack {
            Color.ui.lavenderBlue.ignoresSafeArea()

            VStack {
                // Header
                FolderHeaderView(platform: $folderVm.editedFolder.folderType, shareableData: self.$shareableData) {
                    // on edit
                    self.showFolderBottomSheet.toggle()
                    FolderViewModel.shared.currentFolder = folderVm.editedFolder
                } onMenuOpen: {
                    self.shareableData = mapShareableDataFromCaptionList(captions: folderVm.editedFolder.captions)
                } onDelete: {
                    // on delete
                    self.showFolderDeleteModal = true
                } onBack: {
                    // reset updated folder
                    FolderViewModel.shared.updatedFolder = nil
                    self.navStack.pop(to: .previous)
                }

                // Folder title
                Button {
                    // on edit
                    FolderViewModel.shared.currentFolder = folderVm.editedFolder

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

                        Text(folderVm.editedFolder.name)
                            .font(.ui.title4Medium)
                            .foregroundColor(.ui.cultured)
                            .multilineTextAlignment(.leading)
                            .padding(.top, 5)

                        Spacer()
                    }
                }
                .padding(.leading)

                CaptionListView(emptyTitle: "Oops, it looks like you haven't saved any captions to this folder yet.", folderId: folderVm.editedFolder.id, context: .folder, showCaptionDeleteModal: $showCaptionDeleteModal)
                    .padding()

                Spacer()
            }
        }
        .sheet(isPresented: $showFolderBottomSheet) {
            FolderBottomSheetView(isEditing: .constant(true))
                .presentationDetents([.fraction(0.8)])
        }
        // Show folder delete modal
        .modalView(horizontalPadding: 40, show: $showFolderDeleteModal) {
            DeleteModalView(title: "Remove folder", subTitle: "Deleting this folder will permanently erase all of its contents. Are you sure you want to proceed? 🫢", lottieFile: "crane_hand_lottie", showView: $showFolderDeleteModal, onDelete: {
                if !self.folderVm.editedFolder.name.isEmpty {
                    let uid = AuthManager.shared.userManager.user?.id ?? nil
                    let currentFolders = AuthManager.shared.userManager.user?.folders ?? []

                    firestoreManager.onFolderDelete(for: uid, curFolder: self.folderVm.editedFolder, currentFolders: currentFolders) {
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
                if let user = AuthManager.shared.userManager.user, let captionToBeRemoved = FolderViewModel.shared.captionToBeDeleted {
                    let uid = user.id
                    firestoreManager.deleteSingleCaption(for: uid, captionToBeRemoved: captionToBeRemoved) {
                        withAnimation {
                            FolderViewModel.shared.resetCaptionToBeDeleted()
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
        // show full image on click
        .overlay(
            FullScreenImageOverlay(isFullScreenImage: $photoSelectionVm.showImageInFullScreen, image: photoSelectionVm.fullscreenImageClicked, imageHeight: .constant(nil))
        )
    }
}

struct FolderView_Previews: PreviewProvider {
    static var previews: some View {
        FolderView(folderVm: FolderViewModel.shared)
            .environmentObject(FolderViewModel())
            .environmentObject(FirestoreManager(folderViewModel: FolderViewModel.shared))
            .environmentObject(NavigationStackCompat())
            .environmentObject(PhotoSelectionViewModel())

        FolderView(folderVm: FolderViewModel.shared)
            .environmentObject(FolderViewModel())
            .environmentObject(FirestoreManager(folderViewModel: FolderViewModel.shared))
            .environmentObject(NavigationStackCompat())
            .environmentObject(PhotoSelectionViewModel())
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
