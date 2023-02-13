//
//  SupportEmailModel.swift
//  CapGen
//
//  Created by Kevin Vu on 1/27/23.
//

import Foundation
import SwiftUI

struct SupportEmailModel {
    let toAddress: String = "contact@capgen.app"
    let subject: String = "CapGen Support Contact"
    var body: String = ""

    func send(openURL: OpenURLAction) {
        let urlString = "mailto:\(toAddress)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")"

        guard let url = URL(string: urlString) else { return }
        openURL(url) { accepted in
            if !accepted {
                print("Failed to open email")
            }
        }
    }
}
