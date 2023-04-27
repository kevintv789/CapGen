//
//  TagsBottomSheetModal.swift
//  CapGen
//
//  Created by Kevin Vu on 4/26/23.
//

import SwiftUI

struct TagsBottomSheetModal: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var taglistVM: TaglistViewModel

    @State private var tagInput: String = ""
    @State private var filterToSelectedTag: Bool = false
    
    // Temp selected tags is used to create a mutable selected list that can be removed and changed at will
    @State private var tempSelectedTags: [TagsModel] = []
    
    var body: some View {
        ZStack {
            Color.ui.cultured.ignoresSafeArea(.all)
            
            VStack {
                TagsBottomSheetHeader(title: "Tag & Refine") {
                    // on reset
                    taglistVM.resetSelectedTags()
                    tempSelectedTags.removeAll()
                } onSaveClick: {
                    // on save, copy temp selected tags list to official selected tags
                    taglistVM.selectedTags = tempSelectedTags
                    dismiss()
                }
                
                // Search input
                TagInputField(tagInput: $tagInput)
                    .onChange(of: tagInput) { text in
                        var filteredTags: [TagsModel] = []
                        
                        if filterToSelectedTag {
                            // further filter the list of selected tags
                            filteredTags = tempSelectedTags.filter { tag in
                                return tag.title.lowercased().contains(text.lowercased()) || text.isEmpty
                            }
                        } else {
                            // filters the list of default tags on search
                            filteredTags = defaultTags.filter({ tag in
                                return tag.title.lowercased().contains(text.lowercased()) || text.isEmpty
                            })
                        }
                        
                        taglistVM.updateMutableTags(tags: filteredTags)
                        taglistVM.getTags() // update list
                    }
                
                // Divider with tags information
                TagsInfoView(filterToSelectedTag: $filterToSelectedTag, selectedTagsCount: tempSelectedTags.count)
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
                                                // Remove tag from list if user taps on the tag again
                                                // otherwise add it to the list as a new tag
                                                if let index = tempSelectedTags.firstIndex(where: { $0.id == tag.id }) {
                                                    self.tempSelectedTags.remove(at: index)
                                                } else {
                                                    self.tempSelectedTags.append(tag)
                                                }
                                            }
                                        } label: {
                                            HStack(spacing: 10) {
                                                Text(tag.title)
                                                    .foregroundColor(.ui.cultured)
                                                    .font(.ui.headlineMediumSm)
                                                
                                                if tempSelectedTags.contains(tag) {
                                                    Image("x-white")
                                                        .resizable()
                                                        .frame(width: 10, height: 10)
                                                }
                                            }
                                        }
                                        .padding(10)
                                        .if(tempSelectedTags.contains(tag), transform: { view in
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
                                        .if(!tempSelectedTags.contains(tag), transform: { view in
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
            taglistVM.updateMutableTags(tags: defaultTags)
            self.taglistVM.getTags()
            
            // copy selected tags to temp selected tags so users will get the current list of tags
            self.tempSelectedTags = taglistVM.selectedTags
        }
        .onDisappear() {
            self.taglistVM.resetToDefault()
        }
        .onChange(of: filterToSelectedTag) { isFilter in
            // Filter list to selected tags
            withAnimation {
                if isFilter {
                    taglistVM.updateMutableTags(tags: tempSelectedTags)
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
                        .autocorrectionDisabled(true)

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
    var selectedTagsCount: Int = 0
    
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
                        
                        Text("Selected tags (\(selectedTagsCount))")
                            .foregroundColor(filterToSelectedTag ? Color.ui.darkerPurple : Color.ui.cadetBlueCrayola)
                            .font(.ui.headline)
                            .animation(nil)
                    }
                }
            }
            
            Divider()
        }
    }
}
