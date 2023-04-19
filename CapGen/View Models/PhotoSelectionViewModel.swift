//
//  PhotoSelectionViewModel.swift
//  CapGen
//
//  Created by Kevin Vu on 4/14/23.
//

import Foundation
import SwiftUI
import PhotosUI
import Alamofire
import SwiftyJSON
import Photos
import CoreLocation
import Heap

class PhotoSelectionViewModel: ObservableObject {
    @Published var photosPickerData: Data? = nil
    @Published var capturedImageData: Data? = nil
    @Published var imageAddress: ImageGeoLocationAddress? = nil
    @Published var visionData: ParsedGoogleVisionImageData? = nil
    
    func resetPhotoSelection() {
        self.photosPickerData = nil
        self.imageAddress = nil
        self.visionData = nil
        self.capturedImageData = nil
    }
    
    func assignCapturedImage(imageData: Data) {
        self.capturedImageData = imageData
        
        // Fetch image metadata and get geolocation
        self.fetchImageMetadata(imageData: self.capturedImageData)
    }
    
    func assignPhotoPickerItem(image: PhotosPickerItem) async {
        if let data = try? await image.loadTransferable(type: Data.self) {
            DispatchQueue.main.async {
                self.photosPickerData = data
                
                // Fetch image metadata and get geolocation
                self.fetchImageMetadata(imageData: self.photosPickerData)
            }
        }
    }
    
    // Use Google Cloud Vision API to analyze image
    func analyzeImage(image: UIImage, apiKey: String) async throws -> JSON {
        // Encode the image to base64
        guard let base64Image = image.jpegData(compressionQuality: 0.8)?.base64EncodedString() else {
            throw NSError(domain: "Image encoding error", code: -1, userInfo: nil)
        }
        
        // Set up the request URL and headers
        let url = "https://vision.googleapis.com/v1/images:annotate?key=\(apiKey)"
        let headers: HTTPHeaders = ["Content-Type": "application/json"]
        
        // Set up the request parameters
        let parameters: [String: Any] = [
            "requests": [
                [
                    "image": ["content": base64Image],
                    "features": [
                        ["type": "LABEL_DETECTION", "maxResults": 20],
                        ["type": "LANDMARK_DETECTION", "maxResults": 20, "model": "builtin/latest"],
                        ["type": "FACE_DETECTION", "maxResults": 20, "model": "builtin/latest"],
                        ["type": "TEXT_DETECTION", "maxResults": 20, "model": "builtin/latest"],
                        ["type": "SAFE_SEARCH_DETECTION", "maxResults": 20, "model": "builtin/latest"]
                    ]
                ] as [String : Any]
            ]
        ]
        
        // Send the request using Alamofire
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    continuation.resume(returning: json)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func decodeGoogleVisionData(from jsonString: String) {
        if let imageData = decodeGoogleVisionImageData(from: jsonString) {
            let labels = imageData.labels
            let landmarks = imageData.landmarks
            let faceAnnotations = imageData.faceAnnotations
            let textAnnotations = imageData.textAnnotations
            let safeSearchAnnotations = imageData.safeSearchAnnotations
            
            Heap.track("onAppear - Decoding Image with FULL Google Vision Data", withProperties: ["full_vision_data": GoogleVisionImageData(labels: labels, landmarks: landmarks, faceAnnotations: faceAnnotations, textAnnotations: textAnnotations, safeSearchAnnotations: safeSearchAnnotations)])
            
            // Further filtering vision data
            let filteredLabelAnnotations = filterLabelAnnotations(labelAnnotations: labels)
            let filteredTextAnnotations = filterTextAnnotationsToRealWords(textAnnotations: textAnnotations)
            let filteredLandmarkAnnotations = filterLandmarkAnnotations(landmarkAnnotations: landmarks)
            let filteredFaceAnnotations = filterFaceAnnotations(faceAnnotations: faceAnnotations)
            let filteredSafeSearchAnnotations = filterSafeSearchAnnotations(safeSearchAnnotations: safeSearchAnnotations)
            
            self.visionData = ParsedGoogleVisionImageData(labelAnnotations: filteredLabelAnnotations, landmarkAnnotations: filteredLandmarkAnnotations, faceAnnotations: filteredFaceAnnotations, textAnnotations: filteredTextAnnotations, safeSearchAnnotations: filteredSafeSearchAnnotations)
            
            Heap.track("onAppear - Decoding Image with PARSED Google Vision Data", withProperties: [ "parsed_vision_data": self.visionData ?? "NONE" ])
            
        } else {
            print("Failed to decode JSON.")
        }
    }
    
    private func fetchImageMetadata(imageData: Data?) {
        // Fetch image metadata
        let metadata = self.fetchPhotoMetadata(imageData: imageData)
        
        // Use metadata's geolocation to retrieve image location
        if let metadata = metadata, let geoLoc: GeoLocation = self.fetchImageLatLong(from: metadata) {
            self.fetchLocation(from: geoLoc)
        }
    }
    
    // This function filters any text annotation to only real world words
    private func filterTextAnnotationsToRealWords(textAnnotations: [TextAnnotations]?) -> String {
        if let textAnnotations = textAnnotations, !textAnnotations.isEmpty, let textDescription = textAnnotations.first {
            let filteredTextAnnotations = filterToRealWords(text: textDescription.description)
            return filteredTextAnnotations
        }
        
        return ""
    }
    
    // This function filter any label annotation if the score is 0.9 or higher
    private func filterLabelAnnotations(labelAnnotations: [LabelAnnotation]?) -> String {
        if let labelAnnotations = labelAnnotations {
            let filteredLabels = labelAnnotations.filter({ $0.score >= 0.9 })
            let filteredLabelDescriptions = filteredLabels.map { $0.description }
            return filteredLabelDescriptions.joined(separator: ", ")
        }
        
        return ""
    }
    
    // This function maps all landmarks description and returns it as a comma delimited string
    private func filterLandmarkAnnotations(landmarkAnnotations: [LandmarkAnnotation]?) -> String {
        if let landmarkAnnotations = landmarkAnnotations {
            return landmarkAnnotations.map({ $0.description }).joined(separator: ", ")
        }
        
        return ""
    }
    
    // This function filters all facial annotations with a POSSIBLE likelihood and above
    private func filterFaceAnnotations(faceAnnotations: [FaceAnnotations]?) -> String {
        var filteredResults: Set<String> = []
        
        if let faceAnnotations = faceAnnotations {
            faceAnnotations.forEach { face in
                if face.angerLikelihood.value >= 3 {
                    filteredResults.insert("anger")
                }
                
                if face.joyLikelihood.value >= 3 {
                    filteredResults.insert("joy")
                }
                
                if face.sorrowLikelihood.value >= 3 {
                    filteredResults.insert("sorrow")
                }
                
                if face.surpriseLikelihood.value >= 3 {
                    filteredResults.insert("surprise")
                }
            }
        }
        
        return filteredResults.joined(separator: ", ")
    }
    
    // This function filters all safe search annotations with a POSSIBLE likelihood and above
    private func filterSafeSearchAnnotations(safeSearchAnnotations: SafeSearchAnnotations?) -> String {
        var filteredResults = ""
        
        if let safeSearchAnnotations = safeSearchAnnotations {
            if safeSearchAnnotations.adult.value >= 3 {
                filteredResults += "adult-themed, "
            }
            
            if safeSearchAnnotations.medical.value >= 3 {
                filteredResults += "medical-themed, "
            }
            
            if safeSearchAnnotations.racy.value >= 3 {
                filteredResults += "racy-themed, "
            }
            
            if safeSearchAnnotations.spoof.value >= 3 {
                filteredResults += "spoof-themed, "
            }
            
            if safeSearchAnnotations.violence.value >= 3 {
                filteredResults += "violence-themed "
            }
        }
        
        return filteredResults
    }
    
    /// Fetches photo metadata from the selected image using CGImageSource.
    ///
    /// This function retrieves the image metadata stored in `self.photosPickerData`.
    /// The metadata is extracted using the Core Graphics framework's CGImageSource API.
    ///
    /// Usage:
    /// Call this function to fetch and print metadata from the image data.
    ///
    /// Example:
    /// ```
    /// fetchPhotoMetadata()
    /// ```
    ///
    /// Note:
    /// This function assumes that the image data is already available in `self.photosPickerData`.
    /// Make sure to populate this variable with the image data before calling this function.
    private func fetchPhotoMetadata(imageData: Data?) -> [String: Any]? {
        if let data = imageData {
            if let imageSource = CGImageSourceCreateWithData(data as CFData, nil) {
                if let metadata = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] {
                    return metadata
                }
            }
        }
        
        return nil
    }
    
    /// Fetches latitude and longitude from the image metadata.
    ///
    /// - Parameter metadata: A dictionary containing image metadata.
    ///
    /// - Returns: A GeoLocation object containing the latitude and longitude values, or nil if the GPS data is not available in the metadata.
    ///
    /// This function takes the image metadata as input and checks if there is a GPS dictionary within it.
    /// If GPS data is present, the function extracts the latitude, latitude reference, longitude, and longitude reference values.
    /// It then adjusts the latitude and longitude values based on their respective reference values (north/south and east/west),
    /// and returns a GeoLocation object with the adjusted values.
    ///
    private func fetchImageLatLong(from metadata: [String: Any]) -> GeoLocation? {
        if let gpsData = metadata["{GPS}"] as? [String: Any] {
            if let latitude = gpsData["Latitude"] as? Double,
               let latitudeRef = gpsData["LatitudeRef"] as? String,
               let longitude = gpsData["Longitude"] as? Double,
               let longitudeRef = gpsData["LongitudeRef"] as? String {
               
                let latitudeValue = (latitudeRef == "S" ? -1 : 1) * latitude
                let longitudeValue = (longitudeRef == "W" ? -1 : 1) * longitude
                
                return GeoLocation(longitude: longitudeValue, latitude: latitudeValue)
            }
        }
        
        return nil
    }
    
    /// Fetches the location (address) from a GeoLocation object.
    ///
    /// - Parameter geoLoc: A GeoLocation object containing the latitude and longitude values.
    ///
    /// This function takes a GeoLocation object as input and uses the Core Location framework's CLGeocoder to perform
    /// reverse geocoding and retrieve the address associated with the latitude and longitude values.
    /// If successful, the function creates an ImageGeoLocationAddress object containing the landmark name, locality,
    /// state, and country information, and updates the self.imageAddress variable.
    ///
    /// This function also tracks the success or failure of reverse geocoding using the Heap analytics platform.
    ///
    private func fetchLocation(from geoLoc: GeoLocation) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: geoLoc.latitude, longitude: geoLoc.longitude)
        
        geocoder.reverseGeocodeLocation(location) { result, error in
            if let error = error {
                print("Error in reverse geocoding: \(error)")
                return
            }
            
            if let placemark = result?.first {
                let imageAddress: ImageGeoLocationAddress = ImageGeoLocationAddress(landmarkName: placemark.name, locality: placemark.locality, state: placemark.administrativeArea, country: placemark.country)
                
                self.imageAddress = imageAddress
                
                Heap.track("onAppear PhotoSelectionViewModel - fetch image location", withProperties: [ "location": imageAddress ])
            } else {
                print("No location found")
                Heap.track("onAppear PhotoSelectionViewModel - fetching image location shows NO results")
            }
        }
    }
}
