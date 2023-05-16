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
    @EnvironmentObject var taglistVM: TaglistViewModel
    @EnvironmentObject var userPrefsVm: UserPreferencesViewModel
    
    let userManager = AuthManager.shared.userManager

    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var isLoading: Bool = false
    @State private var enabled = false
    @State private var showCameraView: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var googleCloudVisionError: GoogleCloudVisionError? = nil

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
                            // reset all tags associated with the pic
                            Haptics.shared.play(.soft)
                            taglistVM.resetAll()
                            
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
                            CustomCameraView()
                        }
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
                            cameraModel.resetData()
                            
                            // reset all tags associated with the pic
                            taglistVM.resetAll()
                            
                            if !image.isEmpty {
                                // save image data to picker item
                                await photoSelectionVm.assignPhotoPickerItem(image: image[0])
                                
                                if photoSelectionVm.googleCloudVisionError != nil {
                                    showErrorAlert = true
                                } else {
                                    // push to refinement view once data is saved to published object
                                    if photoSelectionVm.photosPickerData != nil {
                                        self.navStack.push(ImageRefinementView(imageSelectionContext: .photosPicker))
                                    }
                                }
                            }

                            isLoading = false
                        }
                    }
                    .simultaneousGesture(TapGesture().onEnded { _ in
                        Haptics.shared.play(.soft)
                    })

                    Spacer()
                    
                    Text("By selecting an image and generating a caption, you agree to our [End User License Agreement](https://capgen.app/eula), [Terms of Service](https://capgen.app/terms-conditions), and [Privacy Policy](https://capgen.app/privacy-policy).")
                        .font(.ui.headlineLightSm)
                        .multilineTextAlignment(.center)
                        .frame(width: SCREEN_WIDTH * 0.85)
                        .lineSpacing(10)
                        .padding(.vertical)
                        .foregroundColor(.ui.richBlack)
                }
            }
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("Error"),
                message: Text(photoSelectionVm.googleCloudVisionError?.localizedDescription ?? "An unknown error occurred."),
                dismissButton: .default(Text("OK")) {
                    // Reset the error state after the alert is dismissed
                    photoSelectionVm.googleCloudVisionError = nil
                }
            )
        }
        .onAppear {
            // resets selected tags
            taglistVM.resetToDefault()
            taglistVM.resetSelectedTags()
            
            // Sets the default setting with user settings on Firebase
            if let user = userManager.user {
                if let persistImageFlag = user.userPrefs.persistImagesOnSave {
                    userPrefsVm.persistImage = persistImageFlag
                } else {
                    // default to true if the persist images flag is nil
                    userPrefsVm.persistImage = true
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
            .environmentObject(TaglistViewModel())
            .environmentObject(UserPreferencesViewModel())

        ImageSelectorView()
            .environmentObject(PhotoSelectionViewModel())
            .environmentObject(NavigationStackCompat())
            .environmentObject(CameraViewModel())
            .environmentObject(TaglistViewModel())
            .environmentObject(UserPreferencesViewModel())
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
            .frame(width: SCREEN_WIDTH * 0.85, height: SCREEN_HEIGHT / 2.6)
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
