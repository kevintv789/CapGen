//
//  CaptionCardView.swift
//  CapGen
//
//  Created by Kevin Vu on 2/24/23.
//

import SwiftUI

struct CaptionCardView: View {
    // Scaled size
    @ScaledMetric var scaledSize: CGFloat = 1
    
    var caption: CaptionModel
    
    // optional dependency to display folder name
    var showFolderInfo: Bool = false
    
//    @State var folderInfo: FolderModel? = foldersMock[0] // replace with nil without mock
    @State var folderInfo: FolderModel? = nil
    
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
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack {
                        CircularIndicatorView(caption: caption)

                        Spacer()

                        VStack(alignment: .trailing) {
                            // Display folder information on each caption
                            if showFolderInfo, folderInfo != nil {
                                HStack(spacing: 5) {
                                    Image(folderInfo!.folderType == .General ? "empty_folder_white" : "\(folderInfo!.folderType)-circle")
                                        .resizable()
                                        .frame(width: 16 * scaledSize, height: 16 * scaledSize)
                                        .if(folderInfo!.folderType != .General) { image in
                                            return image
                                                .padding(2)
                                                .background(
                                                    Circle()
                                                        .fill(Color.ui.cultured)
                                                )
                                        }
                                    
                                    Text(folderInfo!.name)
                                        .font(.ui.body)
                                        .foregroundColor(.ui.cultured)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: SCREEN_WIDTH / 3, alignment: .trailing)
                            }

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
        .onAppear() {
            if let user = AuthManager.shared.userManager.user {
                // filter to a folder for a specific caption
                self.folderInfo = user.folders.first { $0.id == caption.folderId } ?? nil
            }
        }
    }
}

struct CircularIndicatorView: View {
    // Scaled size
    @ScaledMetric var scaledSize: CGFloat = 1
    
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
            CircularView(image: caption.captionLength, imageWidth: 20 * scaledSize)
        }
    }
}
