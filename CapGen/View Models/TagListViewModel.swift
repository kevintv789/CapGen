//
//  TaglistViewModel.swift
//
//
//  Created by Kevin Vu on 1/23/23.
//

import Foundation

class TaglistViewModel: ObservableObject {
    @Published var rows: [[TagsModel]] = []
    @Published var mutableTags: [TagsModel] = defaultTags.map { $0 }
    @Published var selectedTags: [TagsModel] = []
    
    func resetSelectedTags() {
        self.selectedTags.removeAll()
    }
    
    func updateMutableTags(tags: [TagsModel]) {
        self.mutableTags = tags
    }
    
    func resetToDefault() {
        self.mutableTags = defaultTags.map { $0 }
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
