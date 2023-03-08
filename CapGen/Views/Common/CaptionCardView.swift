//
//  CaptionCardView.swift
//  CapGen
//
//  Created by Kevin Vu on 2/24/23.
//

import SwiftUI

struct CaptionCardView: View {
    var caption: CaptionModel

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.ui.cultured, lineWidth: 4)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.ui.middleBluePurple)
                )

            VStack(alignment: .trailing, spacing: 0) {
                VStack(alignment: .leading) {
                    HStack {
                        Text(caption.title.trimmingCharacters(in: .whitespaces))
                            .padding(EdgeInsets(top: 15, leading: 10, bottom: 15, trailing: 15))
                            .font(.ui.title2)
                            .foregroundColor(.ui.cultured)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        CustomMenuPopup(menuTheme: .light, shareableData: .constant(nil), socialMediaPlatform: .constant(nil))
                            .onTapGesture {}
                            .frame(maxHeight: .infinity, alignment: .topTrailing)
                            .padding(.trailing, -10)
                    }

                    Text(caption.captionDescription.trimmingCharacters(in: .whitespaces))
                        .padding(EdgeInsets(top: 0, leading: 10, bottom: 5, trailing: 15))
                        .font(.ui.bodyLarge)
                        .foregroundColor(.ui.cultured)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack {
                        CircularIndicatorView(caption: caption)

                        Spacer()

                        VStack {
                            // TODO: - Folder information if exists

                            // Date
                            Text(caption.dateCreated)
                                .foregroundColor(.ui.cultured)
                                .font(.ui.headlineMd)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct CircularIndicatorView: View {
    let caption: CaptionModel

    var body: some View {
        HStack {
            // Tones
            if !caption.tones.isEmpty {
                CircularTonesView(tones: caption.tones)
            }

            // Emojis
            CircularView(image: caption.includeEmojis ? "yes-emoji" : "no-emoji")

            // Hashtags
            CircularView(image: caption.includeHashtags ? "yes-hashtag" : "no-hashtag")

            // Caption length
            CircularView(image: caption.captionLength, imageWidth: 20)
        }
    }
}
