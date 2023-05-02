//
//  ImageRefinementView.swift
//  CapGen
//
//  Created by Kevin Vu on 4/14/23.
//

import Heap
import NavigationStack
import PhotosUI
import SwiftUI

struct ImageRefinementView: View {
    @EnvironmentObject var cameraViewModel: CameraViewModel
    @EnvironmentObject var photosSelectionVm: PhotoSelectionViewModel
    @EnvironmentObject var firestoreMan: FirestoreManager
    @EnvironmentObject var navStack: NavigationStackCompat
    @EnvironmentObject var taglistVM: TaglistViewModel

    let imageSelectionContext: NavigationContext

    @State private var imageData: Data? = nil
    @State private var imageHeight: CGFloat? = nil
    @State private var isFullScreenImage: Bool = false
    @State private var showTagsModal: Bool = false

    var body: some View {
        ZStack {
            Color.ui.lightOldPaper.ignoresSafeArea()

            VStack {
                // header
                GenerateCaptionsHeaderView(title: "Refine your captions", isOptional: true, isNextSubmit: false) {
                    Heap.track("onClick ImageRefinementView - Next button tapped") // Add tag properties here

                    // on click next, take to personalized options view
                    self.navStack.push(PersonalizeOptionsView(captionGenType: .image))
                }

                ScrollView(.vertical, showsIndicators: false) {
                    if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                        Button {
                            withAnimation {
                                self.isFullScreenImage.toggle()
                            }
                        } label: {
                            CapturedImageView(image: uiImage, imageHeight: $imageHeight, isFullScreen: false)
                        }
                    }

                    VStack {
                        HStack {
                            if !taglistVM.combinedTagTypes.isEmpty {
                                Text("\(taglistVM.combinedTagTypes.count) tags")
                                    .foregroundColor(Color.ui.cadetBlueCrayola)
                                    .font(.ui.headline)
                            }

                            Spacer()

                            // Add tags button
                            Button {
                                // on add tag click, show bottom sheet
                                showTagsModal.toggle()
                            } label: {
                                Text("+ Add tags")
                                    .foregroundColor(.ui.middleBluePurple)
                                    .font(.ui.title2)
                            }
                        }
                        .frame(width: SCREEN_WIDTH * 0.8)
                        .padding(.bottom, 8)

                        Divider()
                            .padding([.horizontal, .bottom])

                        // display instructional text if there are no tags
                        if taglistVM.combinedTagTypes.isEmpty {
                            InstructionalTagView()
                        } else {
                            ScrollableTagsView()
                        }
                    }
                    .padding()
                    .padding(.top, imageHeight != nil && imageHeight! > 0  ? 0 : .infinity) // Adjust the padding based on the actual image height

                    Spacer()
                }
            }
        }
        .fullScreenCover(isPresented: $showTagsModal) {
            TagsBottomSheetModal()
        }
        .onAppear {
            // determine which data to read from given the context
            if imageSelectionContext == .camera {
                self.imageData = cameraViewModel.imageData
            } else {
                self.imageData = photosSelectionVm.photosPickerData
            }

            // Assigns a UIImage to Published event so that the next few screens have access
            if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                photosSelectionVm.uiImage = uiImage
            }
            
            Heap.track("onAppear ImageRefinementView - With context: \(imageSelectionContext)")
        }
        .overlay(
            FullScreenImageOverlay(isFullScreenImage: $isFullScreenImage, image: photosSelectionVm.uiImage, imageHeight: $imageHeight)
        )
    }
}

struct ImageRefinementView_Previews: PreviewProvider {
    static var previews: some View {
        ImageRefinementView(imageSelectionContext: .camera)
            .environmentObject(PhotoSelectionViewModel())
            .environmentObject(FirestoreManager(folderViewModel: FolderViewModel.shared))
            .environmentObject(NavigationStackCompat())
            .environmentObject(CameraViewModel())
            .environmentObject(TaglistViewModel())

        ImageRefinementView(imageSelectionContext: .photosPicker)
            .environmentObject(PhotoSelectionViewModel())
            .environmentObject(FirestoreManager(folderViewModel: FolderViewModel.shared))
            .environmentObject(NavigationStackCompat())
            .environmentObject(CameraViewModel())
            .environmentObject(TaglistViewModel())
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE (3rd generation)")
    }
}

struct ScrollableTagsView: View {
    @EnvironmentObject var taglistVM: TaglistViewModel

    var body: some View {
        // Tag cloud view
        ScrollView(.horizontal, showsIndicators: false) {
            // Tags
            VStack(alignment: .leading, spacing: 15) {
                TagRows(tags: taglistVM.combinedTagTypes)
            }
            .padding(.leading, 10)
            .padding(.bottom)
            .frame(minWidth: 0, maxWidth: .infinity)
            .id(UUID())
        }
    }
}

struct InstructionalTagView: View {
    var body: some View {
        HStack(alignment: .top) {
            Image("tags_robot")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 160, height: 160)

            VStack(alignment: .leading) {
                Text("🏷️ Refine with tags")
                    .foregroundColor(.ui.richBlack.opacity(0.5))
                    .font(.ui.title2)
                    .padding(.bottom, 10)

                Text("Improve caption precision by tagging your photos, fine-tuning the AI's already impressive work.")
                    .foregroundColor(.ui.cadetBlueCrayola)
                    .font(.ui.headline)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(6)
            }
        }
    }
}

// Custom view to get the size of the view it's applied to
struct GeometryGetter: View {
    @Binding var rect: CGFloat?

    var body: some View {
        GeometryReader { geo in
            Color.clear.onAppear {
                rect = geo.size.height
            }
        }
    }
}

struct CapturedImageView: View {
    let image: UIImage
    @Binding var imageHeight: CGFloat?
    let isFullScreen: Bool

    var body: some View {
        if isFullScreen {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: SCREEN_WIDTH, height: SCREEN_HEIGHT)
        } else {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .cornerRadius(20)
                .frame(width: SCREEN_WIDTH * 0.75)
                .background(GeometryGetter(rect: $imageHeight)) // Get the height of the image
                .frame(maxHeight: SCREEN_HEIGHT * 0.65)
                .mask(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .ui.shadowGray, radius: 4, x: 2, y: 4)
        }
    }
}

struct FullScreenImageOverlay: View {
    @Binding var isFullScreenImage: Bool
    let image: UIImage?
    @Binding var imageHeight: CGFloat?

    var body: some View {
        ZStack {
            if isFullScreenImage {
                Color.black.opacity(0.9)
                    .edgesIgnoringSafeArea(.all)

                if let uiImage = image {
                    CapturedImageView(image: uiImage, imageHeight: $imageHeight, isFullScreen: true)
                }
            }
        }
        .onTapGesture {
            withAnimation {
                isFullScreenImage.toggle()
            }
        }
    }
}
