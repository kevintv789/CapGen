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

    let imageSelectionContext: ImageSelectionContext

    @State private var imageData: Data? = nil
    @State private var imageHeight: CGFloat = 0
    @State private var isFullScreenImage: Bool = false

    var body: some View {
        ZStack {
            Color.ui.lightOldPaper.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    // header
                    GenerateCaptionsHeaderView(title: "Refine your captions", isOptional: true, isNextSubmit: false) {
                        Heap.track("onClick ImageRefinementView - Next button tapped") // Add tag properties here

                        // on click next, take to personalized options view
                        self.navStack.push(PersonalizeOptionsView(captionGenType: .image))
                    }

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
                        // Add tags button
                        Button {
                            // on add tag click, show bottom sheet
                        } label: {
                            Text("+ Add tags")
                                .foregroundColor(.ui.middleBluePurple)
                                .font(.ui.title2)
                        }
                        .frame(width: SCREEN_WIDTH * 0.8, alignment: .trailing)

                        Divider()
                            .padding()

                        // display instructional text if there are no tags
                        InstructionalTagView()
                    }
                    .padding()
                    .padding(.top, imageHeight > 0 ? 0 : .infinity) // Adjust the padding based on the actual image height

                    Spacer()
                }
            }
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

        ImageRefinementView(imageSelectionContext: .photosPicker)
            .environmentObject(PhotoSelectionViewModel())
            .environmentObject(FirestoreManager())
            .environmentObject(NavigationStackCompat())
            .environmentObject(CameraViewModel())
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE (3rd generation)")
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