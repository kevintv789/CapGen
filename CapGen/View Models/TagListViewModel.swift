//
//  TaglistViewModel.swift
//
//
//  Created by Kevin Vu on 1/23/23.
//

import Foundation

class TaglistViewModel: ObservableObject {
    @Published var rows: [[TagsModel]] = []
    @Published var mutableTags: [TagsModel] = []
    @Published var selectedTags: [TagsModel] = []
    @Published var customSelectedTags: [TagsModel] = [] // this is to store custom tags that have been selected
    @Published var combinedTagTypes: [TagsModel] = []
    @Published var allTags: [TagsModel] // this is used to keep an immutable storage for firestore tags plus default tags

    init() {
        allTags = defaultTags
    }

    func updateAllTags() {
        var totalTags = defaultTags
        if let customImageTags = AuthManager.shared.userManager.user?.customImageTags, !customImageTags.isEmpty {
            totalTags.append(contentsOf: customImageTags)
        }

        allTags = totalTags
    }

    func resetSelectedTags() {
        selectedTags.removeAll()
        customSelectedTags.removeAll()
    }
    
    func resetAll() {
        selectedTags.removeAll()
        customSelectedTags.removeAll()
        combinedTagTypes.removeAll()
    }

    func updateMutableTags(tags: [TagsModel]) {
        mutableTags = tags
    }

    func combineTagTypes() {
        combinedTagTypes = selectedTags + customSelectedTags
    }

    func resetToDefault() {
        mutableTags = allTags.map { $0 }
    }

    func getTags() {
        var rows: [[TagsModel]] = []
        var currentRow: [TagsModel] = []

        var totalWidth: CGFloat = 0

        let screenWidth = SCREEN_WIDTH
        let tagSpacing: CGFloat = 30

        if !mutableTags.isEmpty {
            for index in 0 ..< mutableTags.count {
                // Calculcate total size of the tag
                mutableTags[index].size = mutableTags[index].title.getSize() + 10
            }

            mutableTags.forEach { tag in
                totalWidth += (tag.size + tagSpacing)

                // If tag exceeds screen width size, then increment row to start on a new line
                if totalWidth > screenWidth {
                    totalWidth = (tag.size + tagSpacing)
                    rows.append(currentRow)
                    currentRow.removeAll()
                    currentRow.append(tag)
                } else {
                    currentRow.append(tag)
                }
            }

            if !currentRow.isEmpty {
                rows.append(currentRow)
                currentRow.removeAll()
            }
            
            self.rows = rows
        } else {
            self.rows = []
        }
    }
}
