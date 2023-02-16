//
//  TaglistViewModel.swift
//
//
//  Created by Kevin Vu on 1/23/23.
//

import Foundation

class TaglistViewModel: ObservableObject {
    @Published var rows: [[ToneModel]] = []
    @Published var mutableTones: [ToneModel] = tones.map { $0 }

    func getTags() {
        var rows: [[ToneModel]] = []
        var currentRow: [ToneModel] = []

        var totalWidth: CGFloat = 0

        let screenWidth = SCREEN_WIDTH - 10
        let tagSpacing: CGFloat = 45

        if !mutableTones.isEmpty {
            for index in 0 ..< mutableTones.count {
                // Calculcate total size of the tag
                mutableTones[index].size = mutableTones[index].title.getSize() + mutableTones[index].icon.getSize()
            }

            mutableTones.forEach { tone in
                totalWidth += (tone.size + tagSpacing)

                // If tag exceeds screen width size, then increment row to start on a new line
                if totalWidth > screenWidth {
                    totalWidth = (tone.size + tagSpacing)
                    rows.append(currentRow)
                    currentRow.removeAll()
                    currentRow.append(tone)
                } else {
                    currentRow.append(tone)
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
