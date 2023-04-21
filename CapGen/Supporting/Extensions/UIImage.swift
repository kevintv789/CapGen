//
//  UIImage.swift
//  CapGen
//
//  Created by Kevin Vu on 4/21/23.
//

import Foundation
import SwiftUI

extension UIImage {
    var mirrored: UIImage? {
        return UIImage(cgImage: cgImage!, scale: scale, orientation: .leftMirrored)
    }
}
