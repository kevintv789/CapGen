//
//  PhotoSelectionViewModel.swift
//  CapGen
//
//  Created by Kevin Vu on 4/14/23.
//

import Alamofire
import CoreLocation
import Foundation
import Heap
import Photos
import PhotosUI
import SwiftUI
import SwiftyJSON

class PhotoSelectionViewModel: ObservableObject {
    @Published var photosPickerData: Data? = nil
    @Published var imageAddress: ImageGeoLocationAddress? = nil
    @Published var visionData: ParsedGoogleVisionImageData? = nil

    func resetPhotoSelection() {
        photosPickerData = nil
        imageAddress = nil
        visionData = nil
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
                        ["type": "SAFE_SEARCH_DETECTION", "maxResults": 20, "model": "builtin/latest"],
                    ],
                ] as [String: Any],
            ],
        ]

        // Send the request using Alamofire
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                switch response.result {
                case let .success(value):
                    let json = JSON(value)
                    continuation.resume(returning: json)
                case let .failure(error):
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

            visionData = ParsedGoogleVisionImageData(labelAnnotations: filteredLabelAnnotations, landmarkAnnotations: filteredLandmarkAnnotations, faceAnnotations: filteredFaceAnnotations, textAnnotations: filteredTextAnnotations, safeSearchAnnotations: filteredSafeSearchAnnotations)

            Heap.track("onAppear - Decoding Image with PARSED Google Vision Data", withProperties: ["parsed_vision_data": visionData ?? "NONE"])

        } else {
            print("Failed to decode JSON.")
        }
    }

    func fetchImageMetadata(imageData: Data?) {
        // Fetch image metadata
        let metadata = fetchPhotoMetadata(imageData: imageData)
        
        // Use metadata's geolocation to retrieve image location
        if let metadata = metadata, let geoLoc: GeoLocation = fetchImageLatLong(from: metadata) {
            fetchLocation(from: geoLoc) { result in
                self.imageAddress = result
            }
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
            let filteredLabels = labelAnnotations.filter { $0.score >= 0.9 }
            let filteredLabelDescriptions = filteredLabels.map { $0.description }
            return filteredLabelDescriptions.joined(separator: ", ")
        }

        return ""
    }

    // This function maps all landmarks description and returns it as a comma delimited string
    private func filterLandmarkAnnotations(landmarkAnnotations: [LandmarkAnnotation]?) -> String {
        if let landmarkAnnotations = landmarkAnnotations {
            return landmarkAnnotations.map { $0.description }.joined(separator: ", ")
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
}
