//
//  ImageSelectorView.swift
//  CapGen
//
//  Created by Kevin Vu on 4/13/23.
//

import Heap
import NavigationStack
import PhotosUI
import SwiftUI

struct ImageSelectorView: View {
    @EnvironmentObject var photoSelectionVm: PhotoSelectionViewModel
    @EnvironmentObject var navStack: NavigationStackCompat
    @EnvironmentObject var cameraModel: CameraViewModel

    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var isLoading: Bool = false
    @State private var enabled = false
    @State private var showCameraView: Bool = false
    @State private var capturedImage: UIImage?

    var body: some View {
        ZStack {
            Color.ui.lightOldPaper.ignoresSafeArea(.all)

            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    // header
                    GenerateCaptionsHeaderView(title: "Caption your photos", nextAction: nil)

                    Spacer()

                    // camera button
                    PhotoSelectionCardView(backgroundColor: Color.ui.middleBluePurple.opacity(0.4), title: "Snap & Caption 📸", subTitle: "Instantly create captions for your camera shots!", image: "camera_robot")
                        .onTapGesture {
                            if !cameraModel.showAlert {
                                showCameraView = true
                            }
                        }
                        .alert(isPresented: $cameraModel.showAlert) {
                            Alert(
                                title: Text("Camera Permission Denied"),
                                message: Text("Please allow the app to access your camera in Settings."),
                                dismissButton: .default(Text("OK"))
                            )
                        }
                        .fullScreenCover(isPresented: $showCameraView) {
                            // Present the CameraViewController, binding the captured image to the capturedImage property.
//                            CameraViewController(capturedImage: $capturedImage)
                            CustomCameraView()
                        }
                        .onChange(of: capturedImage, perform: { capturedImage in
                            if let image = capturedImage {
                                // reset photo selection
                                photoSelectionVm.resetPhotoSelection()

                                // Convert UIImage to JPEG data with a compression quality of 0.8 (80%)
                                if let jpegData = image.jpegData(compressionQuality: 0.8) {
                                    photoSelectionVm.assignCapturedImage(imageData: jpegData)

                                    // push to refinement view once data is saved to published object
                                    if photoSelectionVm.capturedImageData != nil {
                                        self.navStack.push(ImageRefinementView(imageSelectionContext: .camera))
                                    }
                                }
                            }
                        })
                        .padding(.bottom)

                    // album button
                    PhotosPicker(
                        selection: $selectedPhotos,
                        maxSelectionCount: 1,
                        matching: .images
                    ) {
                        PhotoSelectionCardView(backgroundColor: Color.ui.frenchBlueSky.opacity(0.4), title: "Caption Your Memories 🌟", subTitle: "Let your favorite photos inspire the perfect captions!", image: "album_robot")
                    }
                    .onChange(of: selectedPhotos) { image in
                        isLoading = true
                        Task {
                            // reset photo selection
                            photoSelectionVm.resetPhotoSelection()

                            if !image.isEmpty {
                                // save image data to picker item
                                await photoSelectionVm.assignPhotoPickerItem(image: image[0])
                            }

                            // push to refinement view once data is saved to published object
                            if photoSelectionVm.photosPickerData != nil {
                                self.navStack.push(ImageRefinementView(imageSelectionContext: .photosPicker))
                            }

                            isLoading = false
                        }
                    }

                    Spacer()
                }
            }
        }
        .overlay(
            ZStack {
                if isLoading {
                    Rectangle()
                        .fill(Color.ui.richBlack.opacity(0.4))
                        .blur(radius: 10)
                        .ignoresSafeArea(.all)

                    SimpleLoadingView(scaledSize: 3, title: "Loading...", loadTheme: .white)
                }
            }
        )
    }
}

struct ImageSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        ImageSelectorView()
            .environmentObject(PhotoSelectionViewModel())
            .environmentObject(NavigationStackCompat())
            .environmentObject(CameraViewModel())

        ImageSelectorView()
            .environmentObject(PhotoSelectionViewModel())
            .environmentObject(NavigationStackCompat())
            .environmentObject(CameraViewModel())
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE (3rd generation)")
    }
}

struct PhotoSelectionCardView: View {
    let backgroundColor: Color
    let title: String
    let subTitle: String
    let image: String

    let imageSize: CGFloat = SCREEN_WIDTH / 2.7

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .frame(width: SCREEN_WIDTH * 0.9, height: SCREEN_HEIGHT / 2.5)
            .foregroundColor(backgroundColor)
            .shadow(color: .ui.shadowGray, radius: 3, x: 2, y: 4)
            .overlay(
                GeometryReader { geo in
                    VStack(alignment: .center, spacing: 15) {
                        Text(title)
                            .font(.ui.title4)
                            .foregroundColor(.ui.richBlack.opacity(0.4))

                        Text(subTitle)
                            .font(.ui.headlineRegular)
                            .foregroundColor(.ui.richBlack.opacity(0.4))
                            .multilineTextAlignment(.center)
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(width: SCREEN_WIDTH / 1.7)

                        Image(image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geo.size.width * 0.6)
                    }
                    .padding(.top)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            )
    }
}
