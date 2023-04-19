//
//  CameraViewController.swift
//  CapGen
//
//  Created by Kevin Vu on 4/19/23.
//

import Foundation
import SwiftUI
import UIKit

struct CameraViewController: UIViewControllerRepresentable {
    // A binding to pass the captured image back to the parent view.
    @Binding var capturedImage: UIImage?
    
    // A property wrapper to access and control the presentation mode.
    @Environment(\.presentationMode) private var presentationMode
    
    // Create and configure the UIImagePickerController.
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = context.coordinator
        imagePickerController.sourceType = .camera
        return imagePickerController
    }
    
    // Update the UIImagePickerController.
    // In this case, no updates are needed.
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No updates needed.
    }
    
    // Make the coordinator for the UIImagePickerController.
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // A coordinator class to handle UIImagePickerController delegate methods.
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        // A reference to the parent ImagePicker.
        let parent: CameraViewController
        
        // Initialize the Coordinator with a reference to the parent ImagePicker.
        init(_ parent: CameraViewController) {
            self.parent = parent
        }
        
        // Called when the user captures an image.
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            // Get the captured image and assign it to the parent's selectedImage property.
            if let image = info[.originalImage] as? UIImage {
                parent.capturedImage = image
                
                // Save the captured image to the user's photo library.
                // The nil values for the completion target, selector, and context info indicate that we don't need any callbacks or additional information after the image is saved.
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)

            }
            // Dismiss the UIImagePickerController.
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        // Called when the user cancels the image capture.
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            // Dismiss the UIImagePickerController.
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
