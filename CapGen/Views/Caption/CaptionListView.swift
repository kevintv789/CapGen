//
//  CaptionListView.swift
//  CapGen
//
//  Created by Kevin Vu on 3/8/23.
//

import NavigationStack
import SwiftUI

enum CaptionListContext {
    /**
      Called directly from the FolderView(), this context allows the list to filter out to specific folder IDs versus
      generating a list of captions from all available folders
     */
    case folder

    /**
      This is the default context that generates a list of captions based on all available folders
     */
    case list
    
    /**
      Called directly from the SearchView()
     */
    case search
}

struct CaptionListView: View {
    @EnvironmentObject var navStack: NavigationStackCompat
    @EnvironmentObject var captionVm: CaptionViewModel
    @EnvironmentObject var savedCaptionHomeVm: SavedCaptionHomeViewModel
    @EnvironmentObject var folderVm: FolderViewModel
    @EnvironmentObject var searchVm: SearchViewModel

    @State var captions: [CaptionModel] = []
    var emptyTitle: String = "Oops, it looks like you haven't saved any captions yet."

    // private variables
    @State var folderId: String = ""

    var context: CaptionListContext = .list
    @Binding var showCaptionDeleteModal: Bool

    private func onEdit(caption: CaptionModel) {
        // on click of caption card should take the user to the edit caption screen
        captionVm.selectedCaption = caption
        navStack.push(EditCaptionView(context: .captionList))
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            if captions.isEmpty {
                BlankCaptionsView(title: emptyTitle, imageSize: savedCaptionHomeVm.isViewExpanded ? .regular : .small)
            } else {
                LazyVStack {
                    ForEach(captions) { caption in
                        Button {
                            onEdit(caption: caption)
                        } label: {
                            CaptionCardView(caption: caption, showFolderInfo: context != .folder, showCaptionDeleteModal: $showCaptionDeleteModal, onEdit: {
                                onEdit(caption: caption)
                            })
                            .padding(10)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top)
        .onReceive(folderVm.$updatedFolder.first()) { updatedFolder in
            if context == .folder, let updatedFolder = updatedFolder {
                self.folderId = updatedFolder.id
            }
        }
        .onReceive(AuthManager.shared.userManager.$user, perform: { user in
            if let user = user, context != .search {
                self.captions.removeAll()

                var captionsPerFolder: [[CaptionModel]] = []

                if context == .folder, !folderId.isEmpty {
                    // if folder Id is not empty, then use it to filter out necessary captions from specific folder
                    captionsPerFolder = user.folders.filter { $0.id == folderId }.map { $0.captions }

                } else {
                    captionsPerFolder = user.folders.map { $0.captions }
                }

                captionsPerFolder.forEach { captions in
                    self.captions.append(contentsOf: captions)
                }

                // Sort by most recent created
                let df = DateFormatter()
                df.dateFormat = "MMM d, h:mm a"
                self.captions.sort(by: { df.date(from: $0.dateCreated)!.compare(df.date(from: $1.dateCreated)!) == .orderedDescending })
            }
        })
        .onReceive(searchVm.$searchedCaptions) { searchedCaptions in
            if context == .search {
                self.captions = searchedCaptions
                
                // Sort by most recent created
                let df = DateFormatter()
                df.dateFormat = "MMM d, h:mm a"
                self.captions.sort(by: { df.date(from: $0.dateCreated)!.compare(df.date(from: $1.dateCreated)!) == .orderedDescending })
            }
        }
    }
}

struct CaptionListView_Previews: PreviewProvider {
    static var previews: some View {
        CaptionListView(context: .list, showCaptionDeleteModal: .constant(false))
            .environmentObject(NavigationStackCompat())
            .environmentObject(CaptionViewModel())
            .environmentObject(SavedCaptionHomeViewModel())
            .environmentObject(FolderViewModel())
            .environmentObject(SearchViewModel())

        CaptionListView(context: .folder, showCaptionDeleteModal: .constant(false))
            .environmentObject(NavigationStackCompat())
            .environmentObject(CaptionViewModel())
            .environmentObject(SavedCaptionHomeViewModel())
            .environmentObject(FolderViewModel())
            .environmentObject(SearchViewModel())
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE (3rd generation)")
    }
}
