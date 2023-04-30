//
//  TagListView.swift
//  CapGen
//
//  Created by Kevin Vu on 4/30/23.
//

import SwiftUI

/// Create a helper function createTagRows(from tags: [TagsModel]) -> [[TagsModel]] that takes an array of TagsModel objects and returns an array of arrays of TagsModel objects representing rows. This function calculates the appropriate tags that should be displayed in each row based on their width and spacing.
func createTagRows(from tags: [TagsModel]) -> [[TagsModel]] {
    var rows: [[TagsModel]] = []
    var currentRow: [TagsModel] = []
    var totalWidth: CGFloat = 0

    for tag in tags {
        let tagSize = tag.title.getSize() + 10
        if totalWidth + tagSize + 30 > UIScreen.main.bounds.width {
            rows.append(currentRow)
            currentRow = [tag]
            totalWidth = tagSize
        } else {
            currentRow.append(tag)
            totalWidth += tagSize + 30
        }
    }

    if !currentRow.isEmpty {
        rows.append(currentRow)
    }

    return rows
}

struct TagRows: View {
    @EnvironmentObject var taglistVM: TaglistViewModel
    let tags: [TagsModel]
    private let rows: [[TagsModel]]

    init(tags: [TagsModel]) {
        self.tags = tags
        self.rows = createTagRows(from: tags)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(row) { tag in
                        TagButtonView(title: tag.title, doesContainTag: taglistVM.combinedTagTypes.contains(where: { $0.id == tag.id })) {
                            // Remove tag from list if user taps on the tag
                            if let index = taglistVM.combinedTagTypes.firstIndex(where: { $0.id == tag.id }) {
                                taglistVM.combinedTagTypes.remove(at: index)
                            }

                            // remove it from the default selectd tags list
                            if !tag.isCustom, let index = taglistVM.selectedTags.firstIndex(where: { $0.id == tag.id }) {
                                taglistVM.selectedTags.remove(at: index)
                            }

                            // remove it from the custom selectd tags list
                            if tag.isCustom, let index = taglistVM.customSelectedTags.firstIndex(where: { $0.id == tag.id }) {
                                taglistVM.customSelectedTags.remove(at: index)
                            }
                        }
                    }
                }
            }
        }
    }
}
