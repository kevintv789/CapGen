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

enum ImageSelectionContext {
    case camera, photosPicker
}

struct ImageRefinementView: View {
    @EnvironmentObject var cameraViewModel: CameraViewModel
    @EnvironmentObject var photosSelectionVm: PhotoSelectionViewModel
    @EnvironmentObject var firestoreMan: FirestoreManager
    @EnvironmentObject var navStack: NavigationStackCompat
    @EnvironmentObject var taglistVM: TaglistViewModel

    let imageSelectionContext: ImageSelectionContext

    @State private var imageData: Data? = nil
    @State private var imageHeight: CGFloat = 0
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

                    // Used for testing preview
//                    Image("test_pic_3")
//                        .resizable()
//                        .aspectRatio(contentMode: .fit)
//                        .cornerRadius(20)
//                        .frame(width: SCREEN_WIDTH * 0.7)
//                        .shadow(color: .ui.shadowGray, radius: 4, x: 2, y: 4)
//                        .background(GeometryGetter(rect: $imageHeight)) // Get the height of the image
//                        .frame(maxHeight: SCREEN_HEIGHT * 0.6)
//                        .mask(RoundedRectangle(cornerRadius: 20))

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
                            if !taglistVM.selectedTags.isEmpty {
                                Text("\(taglistVM.selectedTags.count) tags")
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
                        if taglistVM.selectedTags.isEmpty {
                            InstructionalTagView()
                        } else {
                            ScrollableTagsView()
                        }
                        
                    }
                    .padding()
                    .padding(.top, imageHeight > 0 ? 0 : .infinity) // Adjust the padding based on the actual image height

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

            Heap.track("onAppear ImageRefinementView - With context: \(imageSelectionContext)")
        }
        
        .overlay(
            ZStack {
                if self.isFullScreenImage {
                    Color.black.opacity(0.9)
                        .edgesIgnoringSafeArea(.all)

                    if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                        CapturedImageView(image: uiImage, imageHeight: $imageHeight, isFullScreen: true)
                    }
                }
            }.onTapGesture {
                withAnimation {
                    isFullScreenImage.toggle()
                }
            }
        )
    }
}

struct ImageRefinementView_Previews: PreviewProvider {
    static var previews: some View {
        ImageRefinementView(imageSelectionContext: .camera)
            .environmentObject(PhotoSelectionViewModel())
            .environmentObject(FirestoreManager())
            .environmentObject(NavigationStackCompat())
            .environmentObject(CameraViewModel())
            .environmentObject(TaglistViewModel())

        ImageRefinementView(imageSelectionContext: .photosPicker)
            .environmentObject(PhotoSelectionViewModel())
            .environmentObject(FirestoreManager())
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
            LazyVStack(alignment: .leading, spacing: 15) {
                ForEach(taglistVM.rows, id: \.self) { rows in
                    LazyHStack(spacing: 10) {
                        ForEach(rows) { tag in
                            if taglistVM.selectedTags.contains(tag) {
                                Button {
                                    withAnimation {
                                        // Remove tag from list if user taps on the tag
                                        if let index = taglistVM.selectedTags.firstIndex(where: { $0.id == tag.id }) {
                                            taglistVM.selectedTags.remove(at: index)
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 10) {
                                        Text(tag.title)
                                            .foregroundColor(.ui.cultured)
                                            .font(.ui.headlineMediumSm)
                                        
                                        if taglistVM.selectedTags.contains(tag) {
                                            Image("x-white")
                                                .resizable()
                                                .frame(width: 10, height: 10)
                                        }
                                    }
                                }
                                .padding(10)
                                .if(taglistVM.selectedTags.contains(tag), transform: { view in
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
                            }
                        }
                    }
                }
            }
            .padding(.leading, 10)
            .padding(.bottom)
            .frame(minWidth: 0, maxWidth: .infinity)
        }
        .onReceive(taglistVM.$selectedTags) { changedTag in
            if !taglistVM.selectedTags.isEmpty {
                taglistVM.updateMutableTags(tags: taglistVM.selectedTags)
                taglistVM.getTags()
            }
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
    @Binding var rect: CGFloat

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
    @Binding var imageHeight: CGFloat
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
