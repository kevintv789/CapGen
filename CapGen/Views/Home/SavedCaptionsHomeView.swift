//
//  SavedCaptionsGridView.swift
//  CapGen
//
//  Created by Kevin Vu on 2/21/23.
//

import SwiftUI

struct SavedCaptionsHomeView: View {
    // private variables
    @State var isGridView: Bool = true
    
    // dependencies
    @Binding var isExpanded: Bool

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
                    ImageButtonView(imgName: isGridView ? "list_menu" : "grid_menu") {
                        withAnimation {
                            Haptics.shared.play(.soft)
                            self.isGridView.toggle()
                        }
                    }

                    // Expand
                    ImageButtonView(imgName: isExpanded ? "collapse" : "expand") {
                        withAnimation {
                            Haptics.shared.play(.soft)
                            self.isExpanded.toggle()
                        }
                    }
                }
            }

            if isGridView {
                FolderGridView(disableTap: .constant(false))
            } else {
                CaptionListView(isExpanded: $isExpanded)
            }
            
        }
        .padding()
        .padding(.top, isExpanded ? 15 : 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

 struct SavedCaptionsHomeView_Previews: PreviewProvider {
    static var previews: some View {
        SavedCaptionsHomeView(isExpanded: .constant(true))
    }
 }
