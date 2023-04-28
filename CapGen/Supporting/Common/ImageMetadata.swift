//
//  ImageMetadata.swift
//  CapGen
//
//  Created by Kevin Vu on 4/21/23.
//

import CoreLocation
import Foundation
import Heap
import Photos

// This file has helper methods to parse and extract image metadata

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
func fetchPhotoMetadata(imageData: Data?) -> [String: Any]? {
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
func fetchImageLatLong(from metadata: [String: Any]) -> GeoLocation? {
    if let gpsData = metadata["{GPS}"] as? [String: Any] {
        if let latitude = gpsData["Latitude"] as? Double,
           let latitudeRef = gpsData["LatitudeRef"] as? String,
           let longitude = gpsData["Longitude"] as? Double,
           let longitudeRef = gpsData["LongitudeRef"] as? String
        {
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
func fetchLocation(from geoLoc: GeoLocation, completion: @escaping (_ address: ImageGeoLocationAddress?) -> Void) {
    let geocoder = CLGeocoder()
    let location = CLLocation(latitude: geoLoc.latitude, longitude: geoLoc.longitude)

    geocoder.reverseGeocodeLocation(location) { result, error in
        if let error = error {
            print("Error in reverse geocoding: \(error)")
            completion(nil)
            return
        }

        if let placemark = result?.first {
            let imageAddress = ImageGeoLocationAddress(landmarkName: placemark.name, locality: placemark.locality, state: placemark.administrativeArea, country: placemark.country)

            Heap.track("onAppear PhotoSelectionViewModel - fetch image location", withProperties: ["location": imageAddress])

            completion(imageAddress)

        } else {
            print("No location found")
            Heap.track("onAppear PhotoSelectionViewModel - fetching image location shows NO results")
            completion(nil)
            return
        }
    }
}
