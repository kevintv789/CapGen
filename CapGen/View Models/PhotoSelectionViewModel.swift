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

class PhotoSelectionViewModel: ObservableObject {
    @Published var photosPickerData: Data? = nil
    
    func resetPhotoSelection() {
        self.photosPickerData = nil
    }
    
    func assignPhotoPickerItem(image: PhotosPickerItem) async {
        if let data = try? await image.loadTransferable(type: Data.self) {
            self.photosPickerData = data
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
                        ["type": "LANDMARK_DETECTION", "maxResults": 20] as [String : Any],
                        ["type": "FACE_DETECTION", "maxResults": 20]
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
}
