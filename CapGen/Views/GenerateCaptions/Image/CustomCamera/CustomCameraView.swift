//
//  CustomCameraView.swift
//  CapGen
//
//  Created by Kevin Vu on 4/20/23.
//

import SwiftUI
import NavigationStack

struct CustomCameraView: View {
    @StateObject private var cameraViewModel = CameraViewModel()
    @EnvironmentObject var navStack: NavigationStackCompat
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            CameraPreviewViewController(cameraModel: cameraViewModel)
                .ignoresSafeArea(.all)
            
            VStack {
                if !cameraViewModel.isTaken {
                    // Top right side buttons
                    CameraOptionButtons(onSwitchCameraClick: {
                        // on switch camera click
                    }, onFlashClick: {
                        // on flash click
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
                            
                            // Capture button
                            CameraRetakeButton() {
                                // on capture press
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
                                cameraViewModel.savePicture()
                            }
                            
                            dismiss()
                            
                        }
                        .padding(.bottom)
                        .padding(.leading)

                        Spacer()
                    }

                  
                }
            }
        }
        .onAppear() {
            cameraViewModel.checkPermissions()
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

        CustomCameraView()
            .environmentObject(NavigationStackCompat())
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
           
            Button {
                // on flash
                onFlashClick()
            } label: {
                Image("no-flash")
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
