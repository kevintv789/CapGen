//
//  PaymentViewModel.swift
//  CapGen
//
//  Created by Kevin Vu on 5/16/23.
//

import Foundation
import StoreKit
import Heap

public enum PurchaseResult {
    case success(VerificationResult<Transaction>)
    case userCancelled
    case pending
}

public enum VerificationResult<SignedType> {
    case unverified(SignedType, VerificationError)
    case verified(SignedType)
    
    public enum VerificationError: Error {
        case invalidSignature
        case unknown
    }
}

@MainActor
class PaymentViewModel: ObservableObject {
    let ten_credits_product_id: String = Bundle.main.infoDictionary?["TEN_CREDITS_PRODUCT_ID"] as! String
    let fifty_credits_product_id: String = Bundle.main.infoDictionary?["FIFTY_CREDITS_PRODUCT_ID"] as! String
    
    @Published var firestoreMan: FirestoreManager = .init(folderViewModel: FolderViewModel.shared)
    @Published var products: [Product] = []
    
    func getProducts() {
        Task {
            do {
                let productIds = [ten_credits_product_id, fifty_credits_product_id]
                let newProducts = try await Product.products(for: productIds)
                self.products = newProducts
            } catch {
                Heap.track("getProducts - PaymentView error in retrieving products \(error)")
                print("PaymentView error in retrieving products \(error)")
            }
        }
    }
    
    
    func purchase(_ product: Product, onComplete: @escaping () -> Void) {
        Task {
            do {
                let result = try await product.purchase()
                await handlePurchaseResult(result, for: product)
                onComplete()
            } catch {
                Heap.track("purchase - PaymentView error in purchasing products \(error)")
                print("PaymentView error in purchasing products \(error)")
                onComplete()
            }
        }
    }
    
    private func handlePurchaseResult(_ result: Product.PurchaseResult, for product: Product) async {
        switch result {
        case let .success(.verified(transaction)):
            // Successful purhcase
            await transaction.finish()
            
            Heap.track("purchase - Payment is successful!", withProperties: ["product": product])
            print("Payment is successful")
            
            if product.displayPrice == "$0.99" {
                firestoreMan.incrementCredit(for: AuthManager.shared.userManager.user?.id as? String ?? nil, value: 10)
            } else if product.displayPrice == "$3.99" {
                firestoreMan.incrementCredit(for: AuthManager.shared.userManager.user?.id as? String ?? nil, value: 50)
            }
            
        case .success(.unverified(_, _)):
            // Successful purchase but transaction/receipt can't be verified
            // Could be a jailbroken phone
            Heap.track("purchase - Payment is successful, but unverified", withProperties: ["product": product])
            break
        case .pending:
            // Transaction waiting on SCA (Strong Customer Authentication) or
            // approval from Ask to Buy
            Heap.track("purchase - Payment is pending", withProperties: ["product": product])
            break
        case .userCancelled:
            Heap.track("purchase - Payment has been cancelled", withProperties: ["product": product])
            break
        @unknown default:
            break
        }
    }
}
