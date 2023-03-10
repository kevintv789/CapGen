//
//  CaptionListView.swift
//  CapGen
//
//  Created by Kevin Vu on 3/8/23.
//

import SwiftUI
import NavigationStack

struct CaptionListView: View {
    @EnvironmentObject var navStack: NavigationStackCompat
    @EnvironmentObject var captionVm: CaptionViewModel
    @EnvironmentObject var savedCaptionHomeVm: SavedCaptionHomeViewModel
    
//    @State var captions: [CaptionModel] = foldersMock[0].captions
    @State var captions: [CaptionModel] = []
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            if captions.isEmpty {
                BlankCaptionsView(title: "Oops, it looks like you haven't saved any captions yet.", imageSize: savedCaptionHomeVm.isViewExpanded ? .regular : .small)
            } else {
                LazyVStack {
                    ForEach(captions) { caption in
                        Button {
                            // on click of caption card should take the user to the edit caption screen
                            captionVm.selectedCaption = caption
                            
                            self.navStack.push(EditCaptionView(context: .captionList))
                            
                        } label: {
                            CaptionCardView(caption: caption, showFolderInfo: true)
                                .padding(10)
                        }
                      
                    }
                }
            }
          
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top)
        .onReceive(AuthManager.shared.userManager.$user, perform: { user in
            // reset array to avoid duplicate IDs
            self.captions.removeAll()
            
            if let user = AuthManager.shared.userManager.user {
                let captionsPerFolder = user.folders.map { $0.captions }
                
                captionsPerFolder.forEach { captions in
                    // for some reason, the folders still contain the original caption that was just edited
                    // this bug resulted in the user seeing the previous and newly edited captions at the same time
                    // to fix, we must filter out the previous caption from the original folders list
                    let filteredCaptions = captions.filter({ $0.id != captionVm.selectedCaption.id })
                    self.captions.append(contentsOf: filteredCaptions)
                }
                
                // Sort by most recent created
                let df = DateFormatter()
                df.dateFormat = "MMM d, h:mm a"
                self.captions.sort(by: { df.date(from: $0.dateCreated)!.compare(df.date(from: $1.dateCreated)!) == .orderedDescending })
            }
        })

    }
}

struct CaptionListView_Previews: PreviewProvider {
    static var previews: some View {
        CaptionListView()
            .environmentObject(NavigationStackCompat())
            .environmentObject(CaptionViewModel())
            .environmentObject(SavedCaptionHomeViewModel())
        
        CaptionListView()
            .environmentObject(NavigationStackCompat())
            .environmentObject(CaptionViewModel())
            .environmentObject(SavedCaptionHomeViewModel())
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE (3rd generation)")
    }
}
