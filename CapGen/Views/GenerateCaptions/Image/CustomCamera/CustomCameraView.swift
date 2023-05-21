//
//  CustomCameraView.swift
//  CapGen
//
//  Created by Kevin Vu on 4/20/23.
//

import NavigationStack
import SwiftUI

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
                    HStack {
                        Spacer()
                        
                        // Capture button
                        CameraCaptureButton(isTaken: cameraViewModel.isTaken) {
                            if !cameraViewModel.isTaken {
                                // capture image if it's not already taken
                                cameraViewModel.takePicture()
                            } else {
                                // if already taken, on press will take the user to the next screen
                                
                                // Reset objects
                                photoSelectionVm.resetPhotoSelection()
                                
                                cameraViewModel.savePicture()
                                
                                // fetching image metadata
                                photoSelectionVm.fetchImageMetadata(imageData: cameraViewModel.imageData)
                                
                                // navigate to refinement view
                                navStack.push(ImageRefinementView(imageSelectionContext: .camera))
                            }
                            
                        }
                        
                        Spacer()
                    }
                    

                    HStack {
                        // Switches between 'back' and 'retake'
                        CameraNavButton(isTaken: $cameraViewModel.isTaken) {
                            // On retake once photo has been taken
                            if cameraViewModel.isTaken {
                                cameraViewModel.retakePicture()
                            } else {
                                // on back press
                                dismiss()
                            }
                        }
                        .padding(.bottom)
                        .padding(.leading, 40)

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
            .onEnded { _ in
                lastScaleValue = 1.0
            }
        )
        .onAppear {
            cameraViewModel.checkPermissions()
            cameraViewModel.initializeLocation()
            cameraViewModel.resetData()
        }
        .onDisappear {
            DispatchQueue.main.async {
                Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
                    self.cameraViewModel.locationManager.stopUpdatingLocation()
                    self.cameraViewModel.cameraPosition = .back
                    self.cameraViewModel.captureSession.stopRunning()
                }
            }
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
            VStack {
                Image("back-arrow-180")
                    .resizable()
                    .frame(width: 35, height: 35)
                
                Text(isTaken ? "Retake" : "Back")
                    .font(.ui.headlineMd)
                    .foregroundColor(.ui.cultured)
            }
            .shadow(color: .ui.shadowGray.opacity(0.7), radius: 2, x: 0, y: 2)
        }
    }
}

struct CameraCaptureButton: View {
    let isTaken: Bool
    let action: () -> Void

    var body: some View {
        Button {
            action()
            Haptics.shared.play(.soft)
        } label: {
            if isTaken {
                Circle()
                    .fill(Color.ui.cultured)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image("arrow-right-filled")
                            .resizable()
                            .frame(width: 30, height: 30)
                    )
            } else {
                Circle()
                    .strokeBorder(Color.ui.cultured, lineWidth: 6)
                    .frame(width: 80, height: 80)
            }
           
        }
    }
}

struct CameraOptionButtons: View {
    @EnvironmentObject var cameraViewModel: CameraViewModel
    let onSwitchCameraClick: () -> Void
    let onFlashClick: () -> Void

    @State private var size: CGFloat = 30

    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
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
