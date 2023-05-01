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

enum GoogleCloudVisionError: LocalizedError, Identifiable {
    case imageSizeExceeded
    case unsupportedImageFormat
    case encodingError
    case otherError(String)

    var errorDescription: String? {
        switch self {
        case .imageSizeExceeded:
            return "The selected image is too large. Please select an image smaller than 4MB."
        case .unsupportedImageFormat:
            return "The selected image format is not supported. Please select a JPEG, PNG, GIF, BMP, or WEBP image."
        case .encodingError:
            return "There was an error encoding the image. Please try again with a different image."
        case .otherError(let message):
            return message
        }
    }
    
    var id: String {
        switch self {
        case .imageSizeExceeded:
            return "imageSizeExceeded"
        case .unsupportedImageFormat:
            return "unsupportedImageFormat"
        case .encodingError:
            return "encodingError"
        case .otherError(let errorMessage):
            return errorMessage
        }
    }
}

class PhotoSelectionViewModel: ObservableObject {
    @Published var photosPickerData: Data? = nil
    @Published var imageAddress: ImageGeoLocationAddress? = nil
    @Published var visionData: ParsedGoogleVisionImageData? = nil
    @Published var googleCloudVisionError: GoogleCloudVisionError?
    
    // Combined published event to store UIImage for BOTH camera and photo picker
    @Published var uiImage: UIImage? = nil

    func resetPhotoSelection() {
        photosPickerData = nil
        imageAddress = nil
        visionData = nil
    }
    
    func assignPhotoPickerItem(image: PhotosPickerItem) async {
        if let data = try? await image.loadTransferable(type: Data.self) {
            DispatchQueue.main.async {
                // Reset the error property before processing the image
                self.googleCloudVisionError = nil
                
                // Check if the image format is supported
                guard self.isImageFormatSupported(imageData: data) else {
                    self.googleCloudVisionError = .unsupportedImageFormat
                    return
                }
                
                // Check if the image size is small enough
                if data.count > 20 * 1024 * 1024 {
                    self.googleCloudVisionError = .imageSizeExceeded
                    return
                }
                
                
                
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
            // Check for encoding errors
            self.googleCloudVisionError = .encodingError
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
    
    /**
     This function checks if the image format of the given imageData is supported by examining the first byte of the imageData. The first byte, also known as the magic number or signature, can be used to identify common image formats.

     - Parameter imageData: The image data to be checked for supported format.
     
     - Returns: A boolean value indicating whether the image format is supported or not.

     Supported image formats:
     - 0xFF: JPEG (Joint Photographic Experts Group) format
     - 0x89: PNG (Portable Network Graphics) format
     - 0x47: GIF (Graphics Interchange Format) 87a or 89a format
     - 0x42: BMP (Windows Bitmap) format
     - 0x52: WebP format
    */
    func isImageFormatSupported(imageData: Data) -> Bool {
        let supportedFormats: [UInt8] = [0xFF, 0x89, 0x47, 0x42, 0x52]
        let firstByte = imageData[0]
        return supportedFormats.contains(firstByte)
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
