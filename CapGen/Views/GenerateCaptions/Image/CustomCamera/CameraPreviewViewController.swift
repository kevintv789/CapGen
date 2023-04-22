//
//  CameraPreviewViewController.swift
//  CapGen
//
//  Created by Kevin Vu on 4/20/23.
//

import Foundation
import AVFoundation
import UIKit
import SwiftUI

struct CameraPreviewViewController: UIViewRepresentable {
    @ObservedObject var cameraModel: CameraViewModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        DispatchQueue.main.async {
            DispatchQueue.global(qos: .background).async {
                // start session before view can load so camera has time to finish loading first
                cameraModel.captureSession.startRunning()
            }
            
            cameraModel.preview = AVCaptureVideoPreviewLayer(session: cameraModel.captureSession)
            cameraModel.preview.frame = view.frame
            
            cameraModel.preview.videoGravity = .resizeAspectFill
            view.layer.addSublayer(cameraModel.preview)
        }
        
        return view
    }
    
    // we want to ensure that the preview layer's frame is always equal to the UIView's bounds.
    func updateUIView(_ uiView: UIView, context: Context) {}
}
