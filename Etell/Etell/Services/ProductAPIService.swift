//
//  ProductAPIService.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-09-18.
//

import Foundation
import Combine

// MARK: - Protocol for Product API Services
protocol ProductAPIService: ObservableObject {
    var products: [Product] { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    
    func fetchAllProducts() async
    func fetchProductsByCategory(_ category: String) async
    func searchProducts(_ query: String) async
}

// MARK: - Service Factory
class ProductAPIServiceFactory {
    
    enum ServiceType {
        case dummyJSON      // Best for e-commerce with real images
        case fakeStore      // Good for basic e-commerce
        case mock          // Original mock service
    }
    
    @MainActor
    static func createService(type: ServiceType) -> any ProductAPIService {
        switch type {
        case .dummyJSON:
            return DummyJSONAPIService()
        case .fakeStore:
            return FakeStoreAPIService()
        case .mock:
            return TelecomAPIService()
        }
    }
}

// MARK: - Make existing services conform to protocol
extension DummyJSONAPIService: ProductAPIService {}

extension FakeStoreAPIService: ProductAPIService {}

extension TelecomAPIService: ProductAPIService {
    func fetchProductsByCategory(_ categoryString: String) async {
        // Convert string to ProductCategory enum
        if let productCategory = Product.ProductCategory(rawValue: categoryString) {
            await fetchProductsByCategory(productCategory)
        } else {
            await fetchAllProducts()
        }
    }
}
