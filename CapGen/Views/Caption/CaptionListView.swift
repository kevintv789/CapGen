//
//  CaptionListView.swift
//  CapGen
//
//  Created by Kevin Vu on 3/8/23.
//

import SwiftUI
import NavigationStack

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
}

struct CaptionListView: View {
    @EnvironmentObject var navStack: NavigationStackCompat
    @EnvironmentObject var captionVm: CaptionViewModel
    @EnvironmentObject var savedCaptionHomeVm: SavedCaptionHomeViewModel
    @EnvironmentObject var folderVm: FolderViewModel
    
//    @State var captions: [CaptionModel] = foldersMock[0].captions // MOCK LIST
    @State var captions: [CaptionModel] = []
    var emptyTitle: String = "Oops, it looks like you haven't saved any captions yet."
    
    // private variables
    @State var folderId: String = ""
    
    var context: CaptionListContext = .list
    
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            if captions.isEmpty {
                BlankCaptionsView(title: emptyTitle, imageSize: savedCaptionHomeVm.isViewExpanded ? .regular : .small)
            } else {
                LazyVStack {
                    ForEach(captions) { caption in
                        Button {
                            // on click of caption card should take the user to the edit caption screen
                            captionVm.selectedCaption = caption
                            
                            self.navStack.push(EditCaptionView(context: .captionList))
                            
                        } label: {
                            CaptionCardView(caption: caption, showFolderInfo: context != .folder)
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
            if let user = user {
                var captionsPerFolder: [[CaptionModel]] = []
                
                if context == .folder && !folderId.isEmpty {
                    // if folder Id is not empty, then use it to filter out necessary captions from specific folder
                    captionsPerFolder = user.folders.filter({ $0.id == folderId }).map({ $0.captions })
                    
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
        .onDisappear() {
            if context == .folder {
                folderVm.updatedFolder = nil
            }
        }
    }
}

struct CaptionListView_Previews: PreviewProvider {
    static var previews: some View {
        CaptionListView(context: .list)
            .environmentObject(NavigationStackCompat())
            .environmentObject(CaptionViewModel())
            .environmentObject(SavedCaptionHomeViewModel())
            .environmentObject(FolderViewModel())
        
        CaptionListView(context: .folder)
            .environmentObject(NavigationStackCompat())
            .environmentObject(CaptionViewModel())
            .environmentObject(SavedCaptionHomeViewModel())
            .environmentObject(FolderViewModel())
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE (3rd generation)")
    }
}
