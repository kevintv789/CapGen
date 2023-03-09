//
//  CaptionListView.swift
//  CapGen
//
//  Created by Kevin Vu on 3/8/23.
//

import SwiftUI

struct CaptionListView: View {
//    @State var captions: [CaptionModel] = foldersMock[0].captions
    @State var captions: [CaptionModel] = []
    @Binding var isExpanded: Bool
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            if captions.isEmpty {
                BlankCaptionsView(title: "Oops, it looks like you haven't saved any captions yet.", imageSize: isExpanded ? .regular : .small)
            } else {
                LazyVStack {
                    ForEach(captions) { caption in
                        Button {
                            // on click of caption card should take the user to the edit caption screen
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
        .onAppear() {
            // maps all captions in all folders
            if let user = AuthManager.shared.userManager.user {
                let captionsPerFolder = user.folders.map { $0.captions }
                
                captionsPerFolder.forEach { captions in
                    self.captions.append(contentsOf: captions)
                }
                
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
        CaptionListView(isExpanded: .constant(false))
        
        CaptionListView(isExpanded: .constant(false))
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE (3rd generation)")
    }
}
