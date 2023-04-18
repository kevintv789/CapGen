//
//  ImageDataModel.swift
//  CapGen
//
//  Created by Kevin Vu on 4/17/23.
//

import Foundation

struct GeoLocation {
    let longitude: Double
    let latitude: Double
}

struct ImageGeoLocationAddress {
    let landmarkName: String?
    let locality: String?
    let state: String?
    let country: String?
    
    /// A computed property that combines all available address components in a comma-delimited format.
    ///
    /// This property checks each optional string property (landmarkName, locality, state, and country) and
    /// appends the non-nil ones to an array. Then, it joins the array elements into a single string,
    /// separated by commas.
    ///
    /// Usage:
    /// ```
    /// let address = ImageGeoLocationAddress(landmarkName: "Eiffel Tower", locality: "Paris", state: nil, country: "France")
    /// print(address.combinedAddress) // Output: "Eiffel Tower, Paris, France"
    /// ```
    var combinedAddress: String {
        var components: [String] = []
        
        if let landmarkName = landmarkName {
            components.append(landmarkName)
        }
        if let locality = locality {
            components.append(locality)
        }
        if let state = state {
            components.append(state)
        }
        if let country = country {
            components.append(country)
        }
        
        return components.joined(separator: ", ")
    }
}

// MARK: Google Vision AI Data
struct GoogleVisionImageData: Codable {
    let labels: [LabelAnnotation]?
    let landmarks: [LandmarkAnnotation]?
    let faceAnnotations: [FaceAnnotations]?
    let textAnnotations: [TextAnnotations]?
    let safeSearchAnnotations: SafeSearchAnnotations? // Safe Search Annotations returns as an object, instead of array
}

struct ParsedGoogleVisionImageData: Codable {
    let labelAnnotations: String
    let landmarkAnnotations: String
    let faceAnnotations: String
    let textAnnotations: String
    let safeSearchAnnotations: String
}


/// `mid (String)`: A machine-generated identifier that represents the detected entity or concept. This ID can be used to look up more information about the entity in Google's Knowledge Graph or other databases.
/// Example: "/m/019nj4"
///
/// `description (String)`: A human-readable description of the detected entity or concept. This is typically a single word or short phrase that summarizes the entity or concept.
/// Example: "Smile"
///
/// `topicality (Double)`: A floating-point value between 0 and 1 that represents the relevance of the detected entity or concept to the content of the image. A higher value indicates a stronger association between the entity and the image.
/// Example: 0.98310180000000003
///
/// `score (Double)`: A floating-point value between 0 and 1 that represents the confidence level of the detection. A higher score indicates a higher level of confidence that the detected entity or concept is accurate.
/// Example: 0.98310180000000003
struct LabelAnnotation: Codable {
    let mid: String
    let description: String
    let topicality: Double
    let score: Double
}

/// `score (Double)`: A floating-point value between 0 and 1 that represents the confidence level of the detection. A higher score indicates a higher level of confidence that the detected landmark is accurate.
/// Example: 0.30936265000000002

/// `description (String)`: A human-readable description of the detected landmark. This is typically the name of the landmark.
/// Example: "Bellagio Hotel & Casino"
///
/// `locations (Array)`: An array of dictionaries that contains the geographical coordinates (latitude and longitude) of the detected landmark. Each dictionary has a latLng key that holds another dictionary with longitude and latitude keys.
///
/// `mid (String)`: A machine-generated identifier that represents the detected landmark. This ID can be used to look up more information about the landmark in Google's Knowledge Graph or other databases.
/// Example: "/m/033bxs"
struct LandmarkAnnotation: Codable {
    let score: Double
    let description: String
    let locations: [Location]
    let mid: String
    
    struct Location: Codable {
        let latLng: LatLng
        
        struct LatLng: Codable {
            let longitude: Double
            let latitude: Double
        }
    }
}

/// An enumeration representing the likelihood of an emotion being detected in a face.
///
/// Conforms to the `Codable` protocol and uses a raw value type of `String` for compatibility with JSON data.
enum Likelihood: String, Codable {
    case unknown = "UNKNOWN"
    case veryUnlikely = "VERY_UNLIKELY"
    case unlikely = "UNLIKELY"
    case possible = "POSSIBLE"
    case likely = "LIKELY"
    case veryLikely = "VERY_LIKELY"
    
    /// An integer value representing the likelihood.
    ///
    /// Can be used for easy comparison between likelihoods.
    /// Example:
    /// if faceAnnotation.joyLikelihood.value >= Likelihood.possible.value  {}
    /// Include this faceAnnotation since the joy likelihood is "possible" or above
    var value: Int {
        switch self {
        case .unknown:
            return 0
        case .veryUnlikely:
            return 1
        case .unlikely:
            return 2
        case .possible:
            return 3
        case .likely:
            return 4
        case .veryLikely:
            return 5
        }
    }
}

/// FaceAnnotation: A structure representing the emotion annotations detected in a face.
///
/// Conforms to the `Codable` protocol to facilitate encoding and decoding from JSON data.
struct FaceAnnotations: Codable {
    let sorrowLikelihood: Likelihood
    let joyLikelihood: Likelihood
    let surpriseLikelihood: Likelihood
    let angerLikelihood: Likelihood

    /// The coding keys used when encoding and decoding the struct.
    enum CodingKeys: String, CodingKey {
        case sorrowLikelihood
        case joyLikelihood
        case surpriseLikelihood
        case angerLikelihood
    }
}

struct TextAnnotations: Codable {
    let description: String
}

struct SafeSearchAnnotations: Codable {
    let adult: Likelihood
    let medical: Likelihood
    let racy: Likelihood
    let spoof: Likelihood
    let violence: Likelihood
    
    /// The coding keys used when encoding and decoding the struct.
    enum CodingKeys: String, CodingKey {
        case adult
        case medical
        case racy
        case spoof
        case violence
    }
}

func decodeGoogleVisionImageData(from jsonString: String) -> GoogleVisionImageData? {
    let jsonData = Data(jsonString.utf8)
    let decoder = JSONDecoder()

    do {
        let imageData = try decoder.decode(GoogleVisionImageData.self, from: jsonData)
        return imageData
    } catch {
        print("Error decoding JSON: \(error)")
        return nil
    }
}
