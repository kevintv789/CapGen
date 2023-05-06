//
//  TagsBottomSheetModal.swift
//  CapGen
//
//  Created by Kevin Vu on 4/26/23.
//

import SwiftUI
import Heap

struct TagsBottomSheetModal: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var taglistVM: TaglistViewModel
    @EnvironmentObject var firestoreMan: FirestoreManager

    @State private var tagInput: String = ""
    @State private var filterToSelectedTag: Bool = false
    @State private var showDeleteModal: Bool = false
    @State private var customTagTitle: String = ""
    
    // Temp selected tags is used to create a mutable selected list that can be removed and changed at will
    @State private var tempSelectedTags: [TagsModel] = []
    @State private var tempCustomSelectedTags: [TagsModel] = []
    
    private func appendCommaToSearch() {
        if !self.tagInput.isEmpty && !self.tagInput.hasSuffix(", ") {
            self.tagInput.append(", ")
        }
    }
    
    /**
        Example:
         tagInput = "apple, banana, cherry"
         Result: customTagTitle = "cherry"
     
         tagInput = "apple, banana, "
         Result: customTagTitle = "banana"
     
         tagInput = "apple, "
         Result: customTagTitle = "apple"
     
         tagInput = "apple"
         Result: customTagTitle = "apple"
     
         tagInput = ""
         Result: customTagTitle = ""
     */
    private func determineCustomTagTitle() {
        let tagInputComponents = tagInput.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }

        if let lastComponent = tagInputComponents.last, !lastComponent.isEmpty {
            customTagTitle = lastComponent
        } else if tagInputComponents.count > 1, let secondLastComponent = tagInputComponents.dropLast().last {
            customTagTitle = secondLastComponent
        } else {
            customTagTitle = tagInput
        }
    }

    var body: some View {
        ZStack {
            Color.ui.cultured.ignoresSafeArea(.all)

            VStack {
                TagsBottomSheetHeader(title: "Tag & Refine") {
                    // on reset
                    if !tempSelectedTags.isEmpty || !tempCustomSelectedTags.isEmpty {
                        showDeleteModal = true
                    }
                   
                } onSaveClick: {
                    // on save, copy temp selected tags list to official selected tags
                    taglistVM.selectedTags = tempSelectedTags
                    taglistVM.customSelectedTags = tempCustomSelectedTags
                    taglistVM.combineTagTypes() // combine both tags together once saved

                    // If there are custom tags, then save to firebase
                    if !tempCustomSelectedTags.isEmpty, let userId = AuthManager.shared.userManager.user?.id {
                        firestoreMan.saveCustomTags(for: userId, customImageTags: taglistVM.customSelectedTags)
                    }
                    
                    Heap.track("TagBottomSheetModal - onSaveClick", withProperties: ["Selected Tags": tempSelectedTags, "Custom Selected Tags": tempCustomSelectedTags])

                    dismiss()
                } onBackButtonClick: {
                    // If no tags were updated, then set to previous tag list
                    if !taglistVM.combinedTagTypes.isEmpty {
                        taglistVM.updateMutableTags(tags: taglistVM.combinedTagTypes)
                        taglistVM.getTags()
                    }
                    
                    Heap.track("TagBottomSheetModal - onBackButtonClick", withProperties: ["Selected Tags": tempSelectedTags, "Custom Selected Tags": tempCustomSelectedTags])
                   
                    dismiss()
                }

                // Search input
                TagInputField(tagInput: $tagInput)
                    .onChange(of: tagInput) { text in
                        determineCustomTagTitle()
                        
                        // Check if the searchText has some content after the comma and space
                        let lastChar = text.last
                        let delimiterSet = CharacterSet(charactersIn: ", ")
                        
                        if let lastChar = lastChar, !delimiterSet.contains(UnicodeScalar(String(lastChar))!) {
                            var filteredTags: [TagsModel] = []
                            
                            // Split the input by comma and use the last part for filtering
                            let searchText = text.split(separator: ",").last?.trimmingCharacters(in: .whitespaces) ?? ""
                            
                            if filterToSelectedTag {
                                // further filter the list of selected tags
                                // combine custom tags and default tags into one list
                                let combinedTagsList: [TagsModel] = tempSelectedTags + tempCustomSelectedTags
                                
                                filteredTags = combinedTagsList.filter { tag in
                                    tag.title.lowercased().contains(searchText.lowercased()) || searchText.isEmpty
                                }
                            } else {
                                // filters the list of default tags on search
                                filteredTags = taglistVM.allTags.filter { tag in
                                    tag.title.lowercased().contains(searchText.lowercased()) || searchText.isEmpty
                                }
                            }
                            
                            taglistVM.updateMutableTags(tags: filteredTags)
                            taglistVM.getTags() // update list
                        } else if text.isEmpty {
                            taglistVM.updateMutableTags(tags: taglistVM.allTags)
                            taglistVM.getTags() // update list
                        }
                    }

                // Divider with tags information
                TagsInfoView(filterToSelectedTag: $filterToSelectedTag, selectedTagsCount: tempSelectedTags.count + tempCustomSelectedTags.count)
                    .frame(width: SCREEN_WIDTH * 0.85)
                    .padding(.vertical)

                // Tag cloud view
                if !taglistVM.mutableTags.isEmpty {
                    // shows the entirety of the tag list
                    ScrollView(.vertical, showsIndicators: false) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            // Tags
                            LazyVStack(alignment: .leading, spacing: 15) {
                                ForEach(taglistVM.rows, id: \.self) { rows in
                                    LazyHStack(spacing: 10) {
                                        ForEach(rows) { tag in
                                            // render default selected tags
                                            TagButtonView(title: tag.title, doesContainTag: tempSelectedTags.contains(tag) || tempCustomSelectedTags.contains(where: { $0.id == tag.id })) {
                                                // on click remove tag from list if user taps on the tag again
                                                // otherwise add it to the list as a new tag
                                                if !tag.isCustom {
                                                    if let index = tempSelectedTags.firstIndex(where: { $0.id == tag.id }) {
                                                        self.tempSelectedTags.remove(at: index)
                                                    } else {
                                                        self.tempSelectedTags.append(tag)
                                                        appendCommaToSearch()
                                                    }
                                                }

                                                if tag.isCustom {
                                                    // For custom tags
                                                    if let index = tempCustomSelectedTags.firstIndex(where: { $0.id == tag.id }) {
                                                        self.tempCustomSelectedTags.remove(at: index)
                                                    } else {
                                                        self.tempCustomSelectedTags.append(tag)
                                                        appendCommaToSearch()
                                                    }
                                                }
                                            }
                                            .frame(maxWidth: SCREEN_WIDTH * 0.85, alignment: .leading)
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
                } else if taglistVM.mutableTags.isEmpty && !tagInput.isEmpty {
                    // if no default tags are present, AND if the user is searching for a tag
                    // then create a new tag object
//                    let searchText = tagInput.split(separator: ",").last?.trimmingCharacters(in: .whitespaces) ?? ""
//                    let customTagTitle = searchText.isEmpty ? tagInput : searchText
                   
                    
                    TagButtonView(title: "#\(customTagTitle)", doesContainTag: tempCustomSelectedTags.contains(where: { $0.title == "#\(customTagTitle)" })) {
                        // on click remove tag from list if user taps on the tag again
                        // otherwise add it to the list as a new tag
                        if let index = tempCustomSelectedTags.firstIndex(where: { $0.title == "#\(customTagTitle)" }) {
                            self.tempCustomSelectedTags.remove(at: index)
                        } else {
                            // Create new tag here
                            let newTag = TagsModel(id: UUID().uuidString, title: "#\(customTagTitle)", size: 0, isCustom: true)
                            self.tempCustomSelectedTags.append(newTag)
                            self.appendCommaToSearch()
                        }
                            
                    }
                    .frame(width: SCREEN_WIDTH * 0.85, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    
                }

                Spacer()
            }
        }
        .onAppear {
            // copy selected tags to temp selected tags so users will get the current list of tags
            self.tempSelectedTags = taglistVM.selectedTags
            self.tempCustomSelectedTags = taglistVM.customSelectedTags

            // Retrieve custom image tags from Firestore and add them to the total list
            taglistVM.updateAllTags()

            // Display all available tags
            taglistVM.updateMutableTags(tags: taglistVM.allTags)
            self.taglistVM.getTags()
        }
        .onDisappear {
            self.taglistVM.resetToDefault()
        }
        .onChange(of: filterToSelectedTag) { isFilter in
            // Filter list to selected tags
            withAnimation {
                if isFilter {
                    let combinedTagsList: [TagsModel] = tempSelectedTags + tempCustomSelectedTags
                    taglistVM.updateMutableTags(tags: combinedTagsList)
                } else {
                    taglistVM.updateMutableTags(tags: taglistVM.allTags)
                }

                taglistVM.getTags() // update list
            }
        }
        // Show erase text modal
        .modalView(horizontalPadding: 50, show: $showDeleteModal) {
            SimpleDeleteModal(showView: $showDeleteModal, title: "This will delete all of your selected tags. \nAre you sure?", buttonTitle: "Yes! Delete.") {
                // on delete
                Heap.track("TagBottomSheetModal - onReset", withProperties: ["Selected Tags": tempSelectedTags, "Custom Selected Tags": tempCustomSelectedTags])
                
                taglistVM.resetSelectedTags()
                tempSelectedTags.removeAll()
                tempCustomSelectedTags.removeAll()
            }
        }
    }
}

struct TagsBottomSheetModal_Previews: PreviewProvider {
    static var previews: some View {
        TagsBottomSheetModal()
            .environmentObject(TaglistViewModel())
            .environmentObject(FirestoreManager(folderViewModel: FolderViewModel.shared))

        TagsBottomSheetModal()
            .environmentObject(TaglistViewModel())
            .environmentObject(FirestoreManager(folderViewModel: FolderViewModel.shared))
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE (3rd generation)")
    }
}

struct TagsBottomSheetHeader: View {
    @ScaledMetric var scaledSize: CGFloat = 1
    let title: String
    var isNextSubmit: Bool? = false
    let onResetClick: () -> Void
    let onSaveClick: () -> Void
    let onBackButtonClick: () -> Void

    var body: some View {
        // Header
        HStack {
            Button {
                onBackButtonClick()
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

struct TagButtonView: View {
    let title: String
    let doesContainTag: Bool
    let action: () -> Void

    var body: some View {
        Button {
            withAnimation {
                action()
            }
        } label: {
            HStack(spacing: 10) {
                Text(title)
                    .foregroundColor(.ui.cultured)
                    .font(.ui.headlineMediumSm)
                    .multilineTextAlignment(.leading)

                if doesContainTag {
                    Image("x-white")
                        .resizable()
                        .frame(width: 10, height: 10)
                }
            }
        }
        .padding(10)
        .if(doesContainTag, transform: { view in
            view
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
        .if(!doesContainTag, transform: { view in
            view
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.ui.lighterLavBlue)
                )
        })
    }
}
