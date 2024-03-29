//
//  CaptionCardView.swift
//  CapGen
//
//  Created by Kevin Vu on 2/24/23.
//

import SwiftUI

struct CaptionCardView: View {
    @EnvironmentObject var firestoreMan: FirestoreManager
    @EnvironmentObject var photoSelectionVm: PhotoSelectionViewModel
    
    // Scaled size
    @ScaledMetric var scaledSize: CGFloat = 1

    // private variables
    @State var folderInfo: FolderModel? = nil
    @State var shouldShowSocialMediaPlatform: Bool = false
    @State var folderType: String? = ""
    @State var shareableData: ShareableData? = nil
    @State var showCaptionsGuideModal: Bool = false
    @State var uiImage: UIImage? = nil

    // dependencies
    var caption: CaptionModel
    // optional dependency to display folder name
    var showFolderInfo: Bool = false
    @Binding var showCaptionDeleteModal: Bool

    // Custom menu actions
    var onEdit: () -> Void

    private func showSocialmediaPresence() -> Binding<String?> {
        if shouldShowSocialMediaPlatform {
            return $folderType
        }

        return .constant(nil)
    }

    private func updateFolderInfo(folderInfo: FolderModel) {
        // return true if folder type is anything but General
        shouldShowSocialMediaPlatform = folderInfo.folderType != .General

        folderType = folderInfo.folderType.rawValue
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.ui.cultured, lineWidth: 4)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.ui.middleBluePurple)
                        .shadow(color: .ui.richBlack.opacity(0.35), radius: 4, x: 0, y: 3)
                )

            VStack(alignment: .trailing, spacing: 0) {
                VStack(alignment: .leading) {
                    HStack {
                        HStack {
                            if let uiImage = uiImage {
                                ImageThumbnailView(uiImage: uiImage) {
                                    // on thumbnail press, show full image
                                    withAnimation {
                                        photoSelectionVm.assignImageClickedFullscreen(uiImage: uiImage)
                                    }
                                }
                                .padding([.top, .leading])
                                .padding(.trailing, -5)
                            }
                            
                            Text(caption.title.trimmingCharacters(in: .whitespaces))
                                .padding(EdgeInsets(top: 15, leading: 10, bottom: 15, trailing: 15))
                                .font(.ui.title2)
                                .foregroundColor(.ui.cultured)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                       

                        CustomMenuPopup(menuTheme: .light, shareableData: self.$shareableData, socialMediaPlatform: showSocialmediaPresence(),
                                        edit: onEdit,
                                        delete: {
                                            // on delete of single caption
                                            self.showCaptionDeleteModal = true
                                            FolderViewModel.shared.captionToBeDeleted = caption
                                        }, onMenuOpen: {
                                            self.shareableData = mapShareableData(caption: caption.captionDescription, platform: shouldShowSocialMediaPlatform ? folderType : nil)
                                        },
                                        onCopyAndGo: {
                                            // Copy and go run openSocialMediaLink(for: platform)
                                            UIPasteboard.general.string = caption.captionDescription
                                            openSocialMediaLink(for: showSocialmediaPresence().wrappedValue ?? "")
                                        })
                                        .onTapGesture {}
                                        .frame(maxHeight: .infinity, alignment: .topTrailing)
                                        .padding(.trailing, -10)
                    }

                    Text(caption.captionDescription.trimmingCharacters(in: .whitespaces))
                        .padding(EdgeInsets(top: 0, leading: 10, bottom: 5, trailing: 15))
                        .font(.ui.bodyLarge)
                        .foregroundColor(.ui.cultured)
                        .lineLimit(2)
                        .lineSpacing(5)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack {
                        Button {
                            // display caption guides on click
                            self.showCaptionsGuideModal = true
                        } label: {
                            CircularIndicatorView(caption: caption)
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            // Display folder information on each caption
                            if showFolderInfo, folderInfo != nil {
                                HStack(spacing: 5) {
                                    Image(shouldShowSocialMediaPlatform ? "\(folderInfo!.folderType)-circle" : "empty_folder_white")
                                        .resizable()
                                        .frame(width: 16 * scaledSize, height: 16 * scaledSize)
                                        .if(folderInfo!.folderType != .General) { image in
                                            image
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
        .onAppear {
            self.uiImage = nil
            
            if let user = AuthManager.shared.userManager.user {
                // filter to a folder for a specific caption
                if let folderInfo = user.folders.first(where: { $0.id == caption.folderId }) {
                    self.folderInfo = folderInfo
                    self.updateFolderInfo(folderInfo: folderInfo)
                    
                    // retrieve image if any
                    let imagePath = "saved_images/users/\(user.id)/folders/\(folderInfo.id)/caption_images/\(caption.id).jpg"
                    firestoreMan.retrieveImage(imagePath: imagePath) { result in
                        switch result {
                        case .success(let image):
                            self.uiImage = image
                        case .failure:
                            break;
                        }
                    }
                }
            }
        }
        .onReceive(FolderViewModel.shared.$editedFolder) { editedFolder in
            self.updateFolderInfo(folderInfo: editedFolder)
        }
        .sheet(isPresented: $showCaptionsGuideModal) {
            CaptionGuidesView(tones: self.caption.tones, includeEmojis: self.caption.includeEmojis, includeHashtags: self.caption.includeHashtags, captionLength: self.caption.captionLength)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
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
