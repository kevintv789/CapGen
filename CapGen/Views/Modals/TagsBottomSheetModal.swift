//
//  TagsBottomSheetModal.swift
//  CapGen
//
//  Created by Kevin Vu on 4/26/23.
//

import SwiftUI

struct TagsBottomSheetModal: View {
    @EnvironmentObject var taglistVM: TaglistViewModel

    @State private var tagInput: String = ""
    @State private var filterToSelectedTag: Bool = false
    
    var body: some View {
        ZStack {
            Color.ui.cultured.ignoresSafeArea(.all)
            
            VStack {
                TagsBottomSheetHeader(title: "Tag & Refine") {
                    // on reset
                    taglistVM.resetSelectedTags()
                } onSaveClick: {
                    // on save
                }
                
                // Search input
                TagInputField(tagInput: $tagInput)
                    .onChange(of: tagInput) { text in
                        var filteredTags: [TagsModel] = []
                        
                        if filterToSelectedTag {
                            // further filter the list of selected tags
                            filteredTags = taglistVM.selectedTags.filter { tag in
                                return tag.title.lowercased().contains(tagInput.lowercased()) || tagInput.isEmpty
                            }
                        } else {
                            // filters the list of default tags on search
                            filteredTags = defaultTags.filter({ tag in
                                return tag.title.lowercased().contains(tagInput.lowercased()) || tagInput.isEmpty
                            })
                        }
                        
                        taglistVM.updateMutableTags(tags: filteredTags)
                        taglistVM.getTags() // update list
                    }
                
                // Divider with tags information
                TagsInfoView(filterToSelectedTag: $filterToSelectedTag)
                    .frame(width: SCREEN_WIDTH * 0.85)
                    .padding(.vertical)
                
                // Tag cloud view
                ScrollView(.vertical, showsIndicators: false) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        // Tags
                        LazyVStack(alignment: .leading, spacing: 15) {
                            ForEach(taglistVM.rows, id: \.self) { rows in
                                LazyHStack(spacing: 10) {
                                    ForEach(rows) { tag in
                                        Button {
                                            withAnimation {
                                                taglistVM.addTagToList(tag: tag)
                                            }
                                        } label: {
                                            HStack(spacing: 10) {
                                                Text(tag.title)
                                                    .foregroundColor(.ui.cultured)
                                                    .font(.ui.headlineMediumSm)
                                                
                                                if taglistVM.selectedTags.contains(tag) {
                                                    Image("x-white")
                                                        .resizable()
                                                        .frame(width: 10, height: 10)
                                                }
                                            }
                                        }
                                        .padding(10)
                                        .if(taglistVM.selectedTags.contains(tag), transform: { view in
                                            return view
                                                .background(
                                                    ZStack {
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .fill(Color.ui.middleBluePurple)
                                                        
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .strokeBorder(Color.ui.cultured, lineWidth: 2)
                                                    }
                                                        .shadow(color: Color.ui.shadowGray.opacity(0.4), radius: 4, x: 0, y: 4)
                                                )
                                        })
                                        .if(!taglistVM.selectedTags.contains(tag), transform: { view in
                                            return view
                                                .background(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .fill(Color.ui.lighterLavBlue)
                                                )
                                        })
                                    }
                                }
                            }
                        }
                        .padding(.leading, 30)
                        .padding(.bottom)
                        .frame(width: SCREEN_WIDTH * 0.85)
                        .frame(minWidth: 0, maxWidth: .infinity)
                    }
                }
                
                Spacer()
            }
        }
        .onAppear() {
            self.taglistVM.getTags()
        }
        .onDisappear() {
            self.taglistVM.resetToDefault()
        }
        .onChange(of: filterToSelectedTag) { isFilter in
            // Filter list to selected tags
            withAnimation {
                if isFilter {
                    taglistVM.updateMutableTags(tags: taglistVM.selectedTags)
                } else {
                    taglistVM.updateMutableTags(tags: defaultTags)
                }
                
                taglistVM.getTags() // update list
            }
        }
    }
}

struct TagsBottomSheetModal_Previews: PreviewProvider {
    static var previews: some View {
        TagsBottomSheetModal()
            .environmentObject(TaglistViewModel())
        
        TagsBottomSheetModal()
            .environmentObject(TaglistViewModel())
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE (3rd generation)")
    }
}

struct TagsBottomSheetHeader: View {
    @Environment(\.dismiss) var dismiss
    @ScaledMetric var scaledSize: CGFloat = 1
    let title: String
    var isNextSubmit: Bool? = false
    let onResetClick: () -> Void
    let onSaveClick: () -> Void

    var body: some View {
        // Header
        HStack {
            Button {
                dismiss()
            } label: {
                Image("close")
                    .resizable()
                    .frame(width: 24, height: 24)
            }

            Spacer()
            
            Text(title)
                .foregroundColor(.ui.richBlack.opacity(0.5))
                .font(.ui.title4)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.leading, 30)
            
            Spacer()

            HStack(spacing: 10) {
                // Reset button
                Button {
                    onResetClick()
                } label: {
                    Image("undo_red")
                        .resizable()
                        .frame(width: 33, height: 33)
                }
                
                // Save button
                Button {
                    onSaveClick()
                } label: {
                    Image(systemName: "checkmark.circle")
                        .resizable()
                        .frame(width: 33, height: 33)
                        .foregroundColor(Color.ui.green)
                }
            }
          
        }
        .padding(.leading)
        .padding(.bottom, 20)
        .padding(.horizontal)
    }
}

struct TagInputField: View {
    @Binding var tagInput: String
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .strokeBorder(Color.ui.cadetBlueCrayola, lineWidth: 1)
            .frame(width: SCREEN_WIDTH * 0.85, height: 50, alignment: .center)
            .overlay(
                HStack {
                    Image("search-gray")
                        .resizable()
                        .frame(width: 25, height: 25)

                    TextField("", text: $tagInput)
                        .placeholder(when: tagInput.isEmpty) {
                            Text("Add your own tags")
                                .foregroundColor(.ui.cadetBlueCrayola)
                        }
                        .padding(.leading, 8)
                        .font(.ui.headline)
                        .foregroundColor(.ui.richBlack)

                    if !tagInput.isEmpty {
                        Button {
                            Haptics.shared.play(.soft)
                            tagInput.removeAll()
                        } label: {
                            Image(systemName: "x.circle.fill")
                                .font(.ui.headline)
                                .foregroundColor(.ui.cadetBlueCrayola)
                        }
                    }
                }
                .padding()
            )
    }
}

struct TagsInfoView: View {
    @EnvironmentObject var taglistVM: TaglistViewModel
    @Binding var filterToSelectedTag: Bool
    
    var body: some View {
        VStack {
            HStack {
                // tag counter
                Text("\(taglistVM.mutableTags.count) tags")
                    .foregroundColor(Color.ui.cadetBlueCrayola)
                    .font(.ui.headline)
                
                Spacer()
                
                // filter to selected tags button
                Button {
                    withAnimation {
                        filterToSelectedTag.toggle()
                    }
                } label: {
                    HStack {
                        Image(filterToSelectedTag ? "funnel-selected" : "funnel-unselected")
                            .resizable()
                            .frame(width: 20, height: 20)
                        
                        Text("Selected tags")
                            .foregroundColor(filterToSelectedTag ? Color.ui.darkerPurple : Color.ui.cadetBlueCrayola)
                            .font(.ui.headline)
                    }
                }
            }
            
            Divider()
        }
    }
}
