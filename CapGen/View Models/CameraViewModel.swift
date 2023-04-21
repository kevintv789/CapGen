//
//  CameraViewModel.swift
//  CapGen
//
//  Created by Kevin Vu on 4/20/23.
//

import Foundation
import AVFoundation
import SwiftUI

class CameraViewModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var captureSession = AVCaptureSession()
    @Published var preview: AVCaptureVideoPreviewLayer!
    @Published var output = AVCapturePhotoOutput()
    @Published var showAlert: Bool = false
    @Published var isTaken: Bool = false
    @Published var imageData: Data = Data(count: 0)
    
    func checkPermissions() {
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch cameraAuthorizationStatus {
        case .authorized:
            configureSession()
            return
        case .notDetermined:
            // If the camera authorization status is not determined, request access to the camera.
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    // If access is granted, present the ImagePicker.
                    self.configureSession()
                    return
                } else {
                    // If access is denied, show an error alert.
                    self.showAlert = true
                    return
                }
            }
        default:
            // If the status is anything other than authorized or notDetermined, show an error alert.
            showAlert = true
            return
        }
    }
    
    func configureSession() {
        do {
            captureSession.beginConfiguration()
            
            // Add camera input
            let camera = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back)
            
            let deviceInput = try AVCaptureDeviceInput(device: camera!)
            
            if captureSession.canAddInput(deviceInput) {
                captureSession.addInput(deviceInput)
            }
            
            if captureSession.canAddOutput(output) {
                captureSession.addOutput(output)
            }
            
            captureSession.sessionPreset = .photo
            captureSession.commitConfiguration()
            
        } catch {
            print("Error in starting camera", error.localizedDescription)
        }
    }
    
    func takePicture() {
        DispatchQueue.global(qos: .background).async {
            self.output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
            
            // Stop session after a timer because stopRunning() should be called before the
            // picture can be outputted sometimes
            DispatchQueue.main.async {
                Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { (timer) in
                    self.captureSession.stopRunning()
                }
            }
            
            
            DispatchQueue.main.async {
                withAnimation {
                    self.isTaken.toggle()
                }
            }
        }
    }
    
    func retakePicture() {
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
            
            DispatchQueue.main.async {
                withAnimation {
                    self.isTaken.toggle()
                }
            }
        }
    }
    
    // BUG -- this sometimes doesn't work?
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if error != nil {
            print("Error when analyzing photo output", error!.localizedDescription)
            return
        }
        
        guard let data = photo.fileDataRepresentation() else {
            print("Unable to process captured image")
            return
        }
        
        self.imageData = data
    }
    
    // This function saves the captured image to photo album
    func savePicture() {
        if let image = UIImage(data: self.imageData) {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }
    }
    
    // When the view disappears
    func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.stopRunning()
        }
    }
}
