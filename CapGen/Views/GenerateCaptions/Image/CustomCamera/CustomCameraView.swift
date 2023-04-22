//
//  CustomCameraView.swift
//  CapGen
//
//  Created by Kevin Vu on 4/20/23.
//

import SwiftUI
import NavigationStack

struct CustomCameraView: View {
    @EnvironmentObject var cameraViewModel: CameraViewModel
    @EnvironmentObject var navStack: NavigationStackCompat
    @EnvironmentObject var photoSelectionVm: PhotoSelectionViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var lastScaleValue: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            CameraPreviewViewController(cameraModel: cameraViewModel)
                .ignoresSafeArea(.all)
            
            VStack {
                if !cameraViewModel.isTaken {
                    // Top right side buttons
                    CameraOptionButtons(onSwitchCameraClick: {
                        // on switch camera click
                        cameraViewModel.toggleCamera()
                    }, onFlashClick: {
                        // on flash click
                        if cameraViewModel.flashMode == .on {
                            cameraViewModel.flashMode = .off
                        } else {
                            cameraViewModel.flashMode = .on
                        }
                    })
                    .padding(.top)
                }
                
                
                // This spacer forces the below elements to be at the bottom
                Spacer()

                // Render the initial bottom buttons with a capture and a cancel button
                ZStack(alignment: .bottom) {
                    if cameraViewModel.isTaken {
                        HStack {
                            Spacer()
                            
                            // Camera retake
                            CameraRetakeButton() {
                                // on retake press
                                cameraViewModel.retakePicture()
                            }
                        }
                        .padding(.bottom)
                        .padding(.trailing)
                    }
                   
                    if !cameraViewModel.isTaken {
                        HStack {
                            Spacer()
                            
                            // Capture button
                            CameraCaptureButton() {
                                // on capture press
                                cameraViewModel.takePicture()
                            }

                            Spacer()
                        }
                    }
                    
                    
                    HStack {
                        // Cancel button
                        CameraNavButton(isTaken: $cameraViewModel.isTaken) {
                            // On save
                            if cameraViewModel.isTaken {
                                // Reset objects
                                photoSelectionVm.resetPhotoSelection()
                                
                                cameraViewModel.savePicture()
                                
                                // fetching image metadata
                                photoSelectionVm.fetchImageMetadata(imageData: cameraViewModel.imageData)
                                
                                // navigate to refinement view
                                navStack.push(ImageRefinementView(imageSelectionContext: .camera))
                            } else {
                                dismiss()
                            }
                        }
                        .padding(.bottom)
                        .padding(.leading)

                        Spacer()
                    }

                  
                }
            }
        }
        .onTapGesture(count: 2) {
            cameraViewModel.toggleCamera()
        }
        .gesture(MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScaleValue
                lastScaleValue = value
                cameraViewModel.setZoom(scale: delta)
            }
            .onEnded { value in
                lastScaleValue = 1.0
            }
        )
        .onAppear() {
            cameraViewModel.checkPermissions()
            cameraViewModel.initializeLocation()
            cameraViewModel.resetData()
        }
        .alert(isPresented: $cameraViewModel.showAlert) {
            Alert(
                title: Text("Camera Permission Denied"),
                message: Text("Please allow the app to access your camera in Settings."),
                dismissButton: .default(Text("OK"), action: {
                    dismiss()
                })
            )
        }
    }
}

struct CustomCameraView_Previews: PreviewProvider {
    static var previews: some View {
        CustomCameraView()
            .environmentObject(NavigationStackCompat())
            .environmentObject(PhotoSelectionViewModel())
            .environmentObject(CameraViewModel())

        CustomCameraView()
            .environmentObject(NavigationStackCompat())
            .environmentObject(PhotoSelectionViewModel())
            .environmentObject(CameraViewModel())
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE (3rd generation)")
    }
}

struct CameraNavButton: View {
    @Binding var isTaken: Bool
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.ui.richBlack.opacity(0.2))
                .frame(width: 100, height: 40)
                .overlay(
                    Text(isTaken ? "Save" : "Cancel")
                        .foregroundColor(.ui.cultured)
                        .font(.ui.headline)
                )
        }
    }
}

struct CameraRetakeButton: View {
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.ui.richBlack.opacity(0.2))
                .frame(width: 100, height: 40)
                .overlay(
                    Text("Retake")
                        .foregroundColor(.ui.cultured)
                        .font(.ui.headline)
                )
        }
    }
}

struct CameraCaptureButton: View {
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
            Haptics.shared.play(.soft)
        } label: {
            Circle()
                .strokeBorder(Color.ui.cultured, lineWidth: 6)
                .frame(width: 80, height: 80)
        }
    }
}

struct CameraOptionButtons: View {
    @EnvironmentObject var cameraViewModel: CameraViewModel
    let onSwitchCameraClick: () -> Void
    let onFlashClick: () -> Void
    
    @State private var size: CGFloat = 30
    
    var body: some View {
        VStack( alignment: .trailing, spacing: 10) {
            Button {
                // on switch camera
                onSwitchCameraClick()
            } label: {
                Image("switch-camera")
                    .resizable()
                    .frame(width: size, height: size)
            }
            .padding(.bottom, 10)
           
            Button {
                // on flash
                onFlashClick()
            } label: {
                Image(cameraViewModel.flashMode == .off ? "no-flash" : "flash")
                    .resizable()
                    .frame(width: size, height: size)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.ui.richBlack.opacity(0.2))
        )
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.trailing)
    }
}
