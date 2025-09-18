//
//  FakeStoreAPIService.swift
//  Etell
//
//  Created by GitHub Copilot on 2025-09-18.
//

import Foundation
import Combine

// MARK: - FakeStore API Models
struct FakeStoreProduct: Codable {
    let id: Int
    let title: String
    let price: Double
    let description: String
    let category: String
    let image: String
    let rating: FakeStoreRating
}

struct FakeStoreRating: Codable {
    let rate: Double
    let count: Int
}

// MARK: - FakeStore API Service
@MainActor
class FakeStoreAPIService: ObservableObject {
    @Published var products: [Product] = []
    @Published var categories: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let session = URLSession.shared
    private let baseURL = "https://fakestoreapi.com"
    
    // MARK: - Public Methods
    
    func fetchAllProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let url = URL(string: "\(baseURL)/products")!
            let (data, _) = try await session.data(from: url)
            let fakeStoreProducts = try JSONDecoder().decode([FakeStoreProduct].self, from: data)
            
            // Convert to our Product model
            self.products = fakeStoreProducts.map { fakeProduct in
                Product(
                    id: String(fakeProduct.id),
                    name: fakeProduct.title,
                    description: fakeProduct.description,
                    price: fakeProduct.price,
                    originalPrice: fakeProduct.price > 50 ? fakeProduct.price * 1.2 : nil, // Add some fake discounts
                    imageURL: fakeProduct.image,
                    category: mapToProductCategory(fakeProduct.category),
                    inStock: Bool.random(), // Random stock status
                    stockCount: Int.random(in: 0...25),
                    rating: fakeProduct.rating.rate,
                    reviewCount: fakeProduct.rating.count,
                    specifications: generateSpecifications(for: fakeProduct),
                    brand: extractBrand(from: fakeProduct.title),
                    tags: generateTags(for: fakeProduct)
                )
            }
            
        } catch {
            self.errorMessage = "Failed to fetch products: \(error.localizedDescription)"
            // Fallback to mock data
            self.products = Product.realisticMockProducts
        }
        
        isLoading = false
    }
    
    func fetchCategories() async {
        do {
            let url = URL(string: "\(baseURL)/products/categories")!
            let (data, _) = try await session.data(from: url)
            self.categories = try JSONDecoder().decode([String].self, from: data)
        } catch {
            print("Failed to fetch categories: \(error)")
            self.categories = ["electronics", "jewelery", "men's clothing", "women's clothing"]
        }
    }
    
    func fetchProductsByCategory(_ category: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let url = URL(string: "\(baseURL)/products/category/\(category)")!
            let (data, _) = try await session.data(from: url)
            let fakeStoreProducts = try JSONDecoder().decode([FakeStoreProduct].self, from: data)
            
            self.products = fakeStoreProducts.map { fakeProduct in
                Product(
                    id: String(fakeProduct.id),
                    name: fakeProduct.title,
                    description: fakeProduct.description,
                    price: fakeProduct.price,
                    originalPrice: fakeProduct.price > 50 ? fakeProduct.price * 1.2 : nil,
                    imageURL: fakeProduct.image,
                    category: mapToProductCategory(fakeProduct.category),
                    inStock: Bool.random(),
                    stockCount: Int.random(in: 0...25),
                    rating: fakeProduct.rating.rate,
                    reviewCount: fakeProduct.rating.count,
                    specifications: generateSpecifications(for: fakeProduct),
                    brand: extractBrand(from: fakeProduct.title),
                    tags: generateTags(for: fakeProduct)
                )
            }
            
        } catch {
            self.errorMessage = "Failed to fetch products: \(error.localizedDescription)"
            self.products = []
        }
        
        isLoading = false
    }
    
    func searchProducts(_ query: String) async {
        await fetchAllProducts()
        products = products.filter { product in
            product.name.localizedCaseInsensitiveContains(query) ||
            product.description.localizedCaseInsensitiveContains(query) ||
            (product.brand?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }
}

// MARK: - Helper Methods
extension FakeStoreAPIService {
    
    private func mapToProductCategory(_ category: String) -> Product.ProductCategory {
        switch category.lowercased() {
        case "electronics":
            return .router // Map electronics to routers for telecom theme
        case "jewelery", "jewelry":
            return .accessory
        case "men's clothing", "women's clothing":
            return .cable // Map clothing to cables for demo
        default:
            return .accessory
        }
    }
    
    private func extractBrand(from title: String) -> String {
        // Simple brand extraction logic
        let words = title.components(separatedBy: " ")
        return words.first ?? "Generic"
    }
    
    private func generateSpecifications(for product: FakeStoreProduct) -> [String: String] {
        var specs: [String: String] = [:]
        
        switch product.category.lowercased() {
        case "electronics":
            specs = [
                "Type": "Electronic Device",
                "Category": product.category.capitalized,
                "Rating": "\(product.rating.rate)/5.0",
                "Reviews": "\(product.rating.count) reviews"
            ]
        default:
            specs = [
                "Category": product.category.capitalized,
                "Price Range": product.price > 100 ? "Premium" : "Budget",
                "Rating": "\(product.rating.rate)/5.0"
            ]
        }
        
        return specs
    }
    
    private func generateTags(for product: FakeStoreProduct) -> [String] {
        var tags = [product.category]
        
        if product.price > 100 {
            tags.append("premium")
        } else {
            tags.append("budget")
        }
        
        if product.rating.rate >= 4.0 {
            tags.append("highly-rated")
        }
        
        return tags
    }
}
