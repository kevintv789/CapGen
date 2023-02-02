//
//  ErrorModel.swift
//  CapGen
//
//  Created by Kevin Vu on 1/28/23.
//

import Foundation

enum ErrorModel: Error, LocalizedError {
    case genericError, capacityError
    
    var errorDescription: String? {
        switch self {
        case .genericError:
            return NSLocalizedString("Something went wrong, but it's not your fault! Our team is fixing it, please try again later.", comment: "")
        case .capacityError:
            return NSLocalizedString("We apologize, we're currently at over capacity. Our team is working hard to generate captions for everyone. Please try again later.", comment: "")
        }
    }
}

struct ErrorType: Identifiable {
    let id: String = UUID().uuidString
    let error: ErrorModel
}
