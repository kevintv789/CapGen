//
//  SearchView.swift
//  CapGen
//
//  Created by Kevin Vu on 3/15/23.
//

import Heap
import NavigationStack
import SwiftUI

struct SearchView: View {
    @EnvironmentObject var navStack: NavigationStackCompat
    @EnvironmentObject var searchVm: SearchViewModel
    @EnvironmentObject var firestoreManager: FirestoreManager
    @EnvironmentObject var photoSelectionVm: PhotoSelectionViewModel

    @State var totalCaptions: [CaptionModel] = []
    @State var totalFolders: [FolderModel] = []
    @State var showCaptionDeleteModal: Bool = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.ui.cultured.ignoresSafeArea(.all)

            VStack {
                // top header area with search bar
                Rectangle()
                    .fill(Color.ui.lavenderBlue)
                    .frame(width: SCREEN_WIDTH, height: SCREEN_HEIGHT / 7)
                    .ignoresSafeArea()
                    .overlay(alignment: .top) {
                        SearchInputView {
                            // on cancel take user back to the previous screen
                            self.navStack.pop(to: .previous)
                        }
                        .padding(.horizontal)
                        .padding(.top)
                    }

                if searchVm.searchedText.isEmpty {
                    // empty view
                    EmptySearchResultsView(title: "Looking for something specific?", subtitle: "Type your search term above and we'll scour our content for any captions that match your keyword.")
                } else if !searchVm.searchedText.isEmpty && searchVm.searchedCaptions.isEmpty {
                    // no captions found
                    EmptySearchResultsView(title: "No captions found", subtitle: "Looks like we couldn't find any captions for your search")
                } else {
                    // captions found
                    CaptionListView(context: .search, showCaptionDeleteModal: $showCaptionDeleteModal)
                        .padding()
                        .padding(.top, -40)
                        .ignoresSafeArea(.all)
                }
            }
        }
        .onReceive(AuthManager.shared.userManager.$user, perform: { user in
            if let user = user {
                self.totalCaptions.removeAll()

                self.totalFolders = user.folders
                let captionsPerFolder = user.folders.compactMap { $0.captions }

                captionsPerFolder.forEach { captions in
                    self.totalCaptions.append(contentsOf: captions)
                }

                // Sort by most recent created
                let df = DateFormatter()
                df.dateFormat = "MMM d, h:mm a"
                self.totalCaptions.sort(by: { df.date(from: $0.dateCreated)!.compare(df.date(from: $1.dateCreated)!) == .orderedDescending })
            }
        })
        .onReceive(searchVm.$searchedText) { searchText in
            let searchUndercase = searchText.lowercased()

            /**
             Filer based on
             - Title
             - Caption description
             - Tones
             - Folder name
             - Folder type
             */
            searchVm.searchedCaptions = totalCaptions.filter { caption in
                let doesTitleMatch = caption.title.lowercased().contains(searchUndercase)
                let doesCaptionMatch = caption.captionDescription.lowercased().contains(searchUndercase)

                // Get a one dimensional map of tone's descriptions and title
                let tonesDescription = caption.tones.compactMap { $0.description.lowercased() }
                let tonesTitle = caption.tones.compactMap { $0.title.lowercased() }

                // combine both into one call
                let doesTonesMatch = tonesDescription.contains(where: { $0.contains(searchUndercase) }) || tonesTitle.contains(where: { $0.contains(searchUndercase) })

                // get folder information so we can match on folder name and type
                let captionFolderId = caption.folderId

                // get the folder from a filtered caption
                let filteredFolder = totalFolders.first(where: { $0.id == captionFolderId })

                var doesFolderNameMatch = false
                var doesFolderTypeMatch = false

                if let filteredFolder = filteredFolder {
                    doesFolderNameMatch = filteredFolder.name.lowercased().contains(searchUndercase)
                    doesFolderTypeMatch = filteredFolder.folderType.rawValue.lowercased().contains(searchUndercase)
                }

                return doesTitleMatch || doesCaptionMatch || doesTonesMatch || doesFolderNameMatch || doesFolderTypeMatch
            }
        }
        // Show caption delete modal
        .modalView(horizontalPadding: 40, show: $showCaptionDeleteModal) {
            DeleteModalView(title: "Delete caption", subTitle: "Are you sure you want to delete this caption? 🫢 This action cannot be undone.", lottieFile: "crane_hand_lottie", showView: $showCaptionDeleteModal, onDelete: {
                if let user = AuthManager.shared.userManager.user, let captionToBeRemoved = FolderViewModel.shared.captionToBeDeleted {
                    let uid = user.id
                    firestoreManager.deleteSingleCaption(for: uid, captionToBeRemoved: captionToBeRemoved) {
                        withAnimation {
                            // remove from the searched captions once deleted
                            if let captionToBeRemovedIndex = searchVm.searchedCaptions.firstIndex(where: { $0.id == captionToBeRemoved.id }) {
                                self.searchVm.searchedCaptions.remove(at: captionToBeRemovedIndex)
                            }

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
        .onAppear {
            Heap.track("onAppear SearchView")
        }
        // show full image on click
        .overlay(
            FullScreenImageOverlay(isFullScreenImage: $photoSelectionVm.showImageInFullScreen, image: photoSelectionVm.fullscreenImageClicked, imageHeight: .constant(nil))
        )
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
            .environmentObject(NavigationStackCompat())
            .environmentObject(SearchViewModel())
            .environmentObject(FolderViewModel())
            .environmentObject(FirestoreManager(folderViewModel: FolderViewModel.shared))
            .environmentObject(PhotoSelectionViewModel())

        SearchView()
            .environmentObject(NavigationStackCompat())
            .environmentObject(SearchViewModel())
            .environmentObject(FolderViewModel())
            .environmentObject(FirestoreManager(folderViewModel: FolderViewModel.shared))
            .environmentObject(PhotoSelectionViewModel())
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE (3rd generation)")
    }
}

struct SearchInputView: View {
    @EnvironmentObject var searchVm: SearchViewModel

    var onCancelSearch: () -> Void
    @FocusState var isFocused: Bool

    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.ui.cultured)
                .frame(width: SCREEN_WIDTH / 1.5, height: 50)
                .overlay(
                    HStack {
                        Image("search-gray")
                            .resizable()
                            .frame(width: 25, height: 25)

                        TextField("", text: $searchVm.searchedText)
                            .placeholder(when: searchVm.searchedText.isEmpty) {
                                Text("Search...")
                                    .foregroundColor(.ui.cadetBlueCrayola)
                            }
                            .padding(.leading, 8)
                            .font(.ui.headline)
                            .focused($isFocused)
                            .foregroundColor(.ui.richBlack)

                        if !searchVm.searchedText.isEmpty {
                            Button {
                                Haptics.shared.play(.soft)
                                searchVm.resetSearchConfigs()
                                self.isFocused = true
                            } label: {
                                Image(systemName: "x.circle.fill")
                                    .font(.ui.headline)
                                    .foregroundColor(.ui.cadetBlueCrayola)
                            }
                        }
                    }
                    .padding()
                )

            Button(action: {
                Haptics.shared.play(.soft)
                onCancelSearch()
                hideKeyboard()
                searchVm.resetSearchConfigs()

                Heap.track("onClick SearchView - Cancel button clicked")
            }, label: {
                Text("Cancel")
                    .foregroundColor(.ui.richBlack.opacity(0.7))
                    .padding(.trailing, 8)
                    .font(.ui.headline)
            })
            .padding(.leading, 15)
        }
        .onAppear {
            // only set focus automatically if user isn't already searching for something
            if searchVm.searchedText.isEmpty {
                self.isFocused = true
            }
        }
    }
}

struct EmptySearchResultsView: View {
    var title: String
    var subtitle: String

    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .foregroundColor(.ui.cadetBlueCrayola)
                .font(.ui.headline)

            Text(subtitle)
                .foregroundColor(.ui.cadetBlueCrayola)
                .font(.ui.headlineRegular)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
        }
        .frame(width: SCREEN_WIDTH * 0.8)
        .padding(.top, 100)
    }
}
