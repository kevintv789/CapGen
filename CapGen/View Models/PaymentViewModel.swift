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
    
    init() {
        _ = listenForTransactions()
    }
    
    func restorePurchases(onComplete: @escaping (String?) -> Void) {
        Task {
            do {
                try await AppStore.sync()
                onComplete(nil)
            } catch {
                Heap.track("restorePurchases - There was an error restoring purchases \(error)")
                print("restorePurchases - There was an error restoring purchases \(error)")
                onComplete(error.localizedDescription)
            }
        }
    }
    
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
    
    func purchase(_ product: Product, onComplete: @escaping (String?) -> Void) {
        Task {
            do {
                let result = try await product.purchase()
                let errorMessage = await handlePurchaseResult(result, for: product)
                
                if let error = errorMessage {
                    onComplete(error)
                } else {
                    onComplete(nil)
                }
            } catch {
                let errorMessage: String
                switch error {
                case SKError.paymentInvalid:
                    errorMessage = "Purchase failed: Invalid payment."
                case SKError.paymentNotAllowed:
                    errorMessage = "Purchase failed: Payment not allowed."
                default:
                    errorMessage = "Purchase failed: Unknown error. Please contact our support team at contact@CapGen.app for further assistance."
                }
                Heap.track("purchase - PaymentView error in purchasing products \(error)")
                print("PaymentView error in purchasing products \(error)")
                onComplete(errorMessage)
                
            }
        }
    }
    
    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            // Iterate through any transactions that don't come from a direct call to `purchase()`.
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)

                    // Always finish a transaction.
                    await transaction.finish()
                } catch {
                    // StoreKit has a transaction that fails verification. Don't deliver content to the user.
                    print("Transaction failed verification")
                }
            }
        }
    }
    
    func checkVerified(_ result: StoreKit.VerificationResult<StoreKit.Transaction>) throws -> Transaction {
        switch result {
        case let .verified(transaction):
            return transaction
        case .unverified(_, let error):
            throw error
        }
    }
    
    private func handlePurchaseResult(_ result: Product.PurchaseResult, for product: Product) async -> String? {
        switch result {
        case let .success(.verified(transaction)):
            // Successful purhcase
            await transaction.finish()
            
            Heap.track("purchase - Payment is successful!", withProperties: ["product": product])
            print("Payment is successful")
            
            if product.id == ten_credits_product_id {
                firestoreMan.incrementCredit(for: AuthManager.shared.userManager.user?.id as? String ?? nil, value: 10)
            } else if product.id == fifty_credits_product_id {
                firestoreMan.incrementCredit(for: AuthManager.shared.userManager.user?.id as? String ?? nil, value: 50)
            }
            
            return nil
        case .success(.unverified(_, _)):
            // Successful purchase but transaction/receipt can't be verified
            // Could be a jailbroken phone
            Heap.track("purchase - Payment is successful, but unverified", withProperties: ["product": product])
            return "Your payment is unverified. Please try again with a different transaction method."
        case .pending:
            // Transaction waiting on SCA (Strong Customer Authentication) or
            // approval from Ask to Buy
            Heap.track("purchase - Payment is pending", withProperties: ["product": product])
            return "Your payment is pending for approval from your banking institution."
        case .userCancelled:
            Heap.track("purchase - Payment has been cancelled", withProperties: ["product": product])
            return nil
        @unknown default:
            Heap.track("purchase - Payment has failed with unknown error", withProperties: ["product": product])
            return "Your payment has failed with an unknown error. Please contact our support team at contact@CapGen.app for further assistance."
        }
    }
}
