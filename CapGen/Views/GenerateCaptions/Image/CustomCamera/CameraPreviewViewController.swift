//
//  CameraPreviewViewController.swift
//  CapGen
//
//  Created by Kevin Vu on 4/20/23.
//

import AVFoundation
import Foundation
import SwiftUI
import UIKit

struct CameraPreviewViewController: UIViewRepresentable {
    @ObservedObject var cameraModel: CameraViewModel

    func makeUIView(context _: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        DispatchQueue.main.async {
            cameraModel.preview = AVCaptureVideoPreviewLayer(session: cameraModel.captureSession)
            cameraModel.preview.frame = view.frame

            cameraModel.preview.videoGravity = .resizeAspectFill
            view.layer.addSublayer(cameraModel.preview)

            cameraModel.startSession()
        }

        return view
    }

    // we want to ensure that the preview layer's frame is always equal to the UIView's bounds.
    func updateUIView(_: UIView, context _: Context) {}
}
