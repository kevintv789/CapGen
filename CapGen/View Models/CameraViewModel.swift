//
//  CameraViewModel.swift
//  CapGen
//
//  Created by Kevin Vu on 4/20/23.
//

import AVFoundation
import CoreLocation
import Foundation
import SwiftUI

class CameraViewModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate, CLLocationManagerDelegate {
    @Published var locationManager = CLLocationManager()
    @Published var captureSession = AVCaptureSession()
    @Published var preview: AVCaptureVideoPreviewLayer!
    @Published var output = AVCapturePhotoOutput()
    @Published var showAlert: Bool = false
    @Published var isTaken: Bool = false
    @Published var imageData: Data = .init(count: 0)
    @Published var imageAddress: ImageGeoLocationAddress? = nil
    @Published var cameraPosition: AVCaptureDevice.Position = .back
    @Published var flashMode: AVCaptureDevice.FlashMode = .off

    func resetData() {
        imageData.removeAll()
        imageAddress = nil
        isTaken = false
        showAlert = false
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
        // Stop the session before making any changes
        if captureSession.isRunning {
            captureSession.stopRunning()
        }

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
        guard captureSession.isRunning else {
            return
        }

        cameraPosition = (cameraPosition == .back) ? .front : .back

        // Stop session after a timer because stopRunning() should be called before the
        // picture can be outputted sometimes
        configureSession()

        startSession()
    }

    func takePicture() {
        DispatchQueue.global(qos: .background).async {
            let photoSettings = AVCapturePhotoSettings()

            // Set the flash mode
            if self.output.supportedFlashModes.contains(self.flashMode) {
                photoSettings.flashMode = self.flashMode
            }

            self.output.capturePhoto(with: photoSettings, delegate: self)

            // Stop session after a timer because stopRunning() should be called before the
            // picture can be outputted sometimes
            DispatchQueue.main.async {
                Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
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

    func setZoom(scale: CGFloat) {
        guard let input = captureSession.inputs.first as? AVCaptureDeviceInput else { return }
        let device = input.device

        do {
            try device.lockForConfiguration()

            let minimumZoomFactor: CGFloat = 1.0
            let maximumZoomFactor = device.activeFormat.videoMaxZoomFactor
            let currentZoomFactor = device.videoZoomFactor
            let newZoomFactor = max(minimumZoomFactor, min(currentZoomFactor * scale, maximumZoomFactor))

            device.videoZoomFactor = newZoomFactor
            device.unlockForConfiguration()
        } catch {
            print("Error while setting zoom: \(error.localizedDescription)")
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

    func photoOutput(_: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
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
            if cameraPosition == .front {
                if let mirroredImage = image.mirrored {
                    imageData = mirroredImage.jpegData(compressionQuality: 0.8) ?? data
                }
            } else {
                imageData = data
            }
        }
    }

    // This function saves the captured image to photo album
    func savePicture() {
        if let image = UIImage(data: imageData) {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }
    }

    // When the view disappears
    func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.stopRunning()
        }
    }

    func startSession() {
        DispatchQueue.global(qos: .background).async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }
}
