//
//  CameraViewModel.swift
//  CapGen
//
//  Created by Kevin Vu on 4/20/23.
//

import Foundation
import AVFoundation
import SwiftUI
import CoreLocation

class CameraViewModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate, CLLocationManagerDelegate {
    @Published var locationManager = CLLocationManager()
    @Published var captureSession = AVCaptureSession()
    @Published var preview: AVCaptureVideoPreviewLayer!
    @Published var output = AVCapturePhotoOutput()
    @Published var showAlert: Bool = false
    @Published var isTaken: Bool = false
    @Published var imageData: Data = Data(count: 0)
    @Published var imageAddress: ImageGeoLocationAddress? = nil
    @Published var cameraPosition: AVCaptureDevice.Position = .back
    
    func resetData() {
        self.imageData.removeAll()
        self.imageAddress = nil
    }
    
    func initializeLocation() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }
    
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
            
            // Remove current inputs
            // By removing the current inputs before configuring the session with the new camera position, we ensure that only one camera input is active at a time. This way, when you toggle the camera, the capture session will cleanly switch between the front and back cameras without any issues.
            for input in captureSession.inputs {
                captureSession.removeInput(input)
            }
            
            for output in captureSession.outputs {
                captureSession.removeOutput(output)
            }
            
            // Add camera input
            if let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition) {
                let deviceInput = try AVCaptureDeviceInput(device: camera)
                
                if captureSession.canAddInput(deviceInput) {
                    captureSession.addInput(deviceInput)
                }
                
                if captureSession.canAddOutput(output) {
                    captureSession.addOutput(output)
                }
                
                captureSession.sessionPreset = .photo
            }
            
            captureSession.commitConfiguration()
            
        } catch {
            print("Error in starting camera", error.localizedDescription)
        }
    }
    
    // Toggle the camera position
    func toggleCamera() {
        // Make sure capture session is running
        print("IS RUNNING", captureSession.isRunning)
        guard captureSession.isRunning else {
            return
        }
        
        cameraPosition = (cameraPosition == .back) ? .front : .back
        
        // Stop session after a timer because stopRunning() should be called before the
        // picture can be outputted sometimes
        self.captureSession.stopRunning()
        
        // Configure the session with the new camera position
        configureSession()
        
        // Start the session
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
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
                    self.locationManager.stopUpdatingLocation()
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
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if error != nil {
            print("Error when analyzing photo output", error!.localizedDescription)
            return
        }
        
        guard let data = photo.fileDataRepresentation() else {
            print("Unable to process captured image")
            return
        }
        
        if let userLocation = locationManager.location?.coordinate {
            let latitude = userLocation.latitude
            let longitude = userLocation.longitude
            // Use the latitude and longitude values as needed
            
            let geoLoc = GeoLocation(longitude: longitude, latitude: latitude)
            fetchLocation(from: geoLoc) { result in
                self.imageAddress = result
            }
        }
        
        
        if let image = UIImage(data: data) {
            // Mirror the image if the front camera is used
            if self.cameraPosition == .front {
                if let mirroredImage = image.mirrored {
                    self.imageData = mirroredImage.jpegData(compressionQuality: 0.8) ?? data
                }
            } else {
                self.imageData = data
            }
        }
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
            self.locationManager.stopUpdatingLocation()
        }
    }
}
