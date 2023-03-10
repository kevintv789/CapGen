//
//  SavedCaptionsGridView.swift
//  CapGen
//
//  Created by Kevin Vu on 2/21/23.
//

import SwiftUI

struct SavedCaptionsHomeView: View {
    @EnvironmentObject var savedCaptionHomeVm: SavedCaptionHomeViewModel

    var body: some View {
        VStack(alignment: .leading) {
            // Top level
            HStack {
                // Saved captions title
                HStack {
                    Image("bookmark")
                        .resizable()
                        .frame(width: 40, height: 40)

                    Text("Your saved captions")
                        .font(.ui.headline)
                        .foregroundColor(.ui.cultured)
                }

                Spacer()

                // Buttons
                HStack(spacing: 15) {
                    // Search
                    ImageButtonView(imgName: "magnifier") {}

                    // Grid/List view
                    ImageButtonView(imgName: savedCaptionHomeVm.isGridView ? "list_menu" : "grid_menu") {
                        withAnimation {
                            Haptics.shared.play(.soft)
                            savedCaptionHomeVm.isGridView.toggle()
                        }
                    }

                    // Expand
                    ImageButtonView(imgName: savedCaptionHomeVm.isViewExpanded ? "collapse" : "expand") {
                        withAnimation {
                            Haptics.shared.play(.soft)
                            savedCaptionHomeVm.isViewExpanded.toggle()
                        }
                    }
                }
            }

            if savedCaptionHomeVm.isGridView {
                FolderGridView(disableTap: .constant(false))
            } else {
                CaptionListView()
            }
            
        }
        .padding()
        .padding(.top, savedCaptionHomeVm.isViewExpanded ? 15 : 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

 struct SavedCaptionsHomeView_Previews: PreviewProvider {
    static var previews: some View {
        SavedCaptionsHomeView()
            .environmentObject(SavedCaptionHomeViewModel())
    }
 }
