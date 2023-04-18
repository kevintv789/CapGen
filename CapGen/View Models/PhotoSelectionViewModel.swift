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
    @Published var imageAddress: ImageGeoLocationAddress? = nil
    @Published var visionData: GoogleVisionImageData? = nil
    
    func resetPhotoSelection() {
        self.photosPickerData = nil
        self.imageAddress = nil
    }
    
    func assignPhotoPickerItem(image: PhotosPickerItem) async {
        if let data = try? await image.loadTransferable(type: Data.self) {
            DispatchQueue.main.async {
                self.photosPickerData = data
                
                // Fetch image metadata
                let metadata = self.fetchPhotoMetadata()
                
                // Use metadata's geolocation to retrieve image location
                if let metadata = metadata, let geoLoc: GeoLocation = self.fetchImageLatLong(from: metadata) {
                    self.fetchLocation(from: geoLoc)
                }
            }
        }
    }
    
    // Use Google Cloud Vision API to analyze image
    func analyzeImage(image: UIImage, apiKey: String, completionHandler: @escaping (Result<JSON, Error>) -> Void) {
        // Encode the image to base64
        guard let base64Image = image.jpegData(compressionQuality: 0.8)?.base64EncodedString() else {
            completionHandler(.failure(NSError(domain: "Image encoding error", code: -1, userInfo: nil)))
            return
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
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                completionHandler(.success(json))
            case .failure(let error):
                completionHandler(.failure(error))
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
            
            self.visionData = GoogleVisionImageData(labels: labels, landmarks: landmarks, faceAnnotations: faceAnnotations, textAnnotations: textAnnotations, safeSearchAnnotations: safeSearchAnnotations)
        } else {
            print("Failed to decode JSON.")
        }
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
    private func fetchPhotoMetadata() -> [String: Any]? {
        if let data = self.photosPickerData {
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
