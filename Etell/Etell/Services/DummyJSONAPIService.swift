//
//  DummyJSONAPIService.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-09-18.
//

import Foundation
import Combine

// MARK: - DummyJSON API Models
struct DummyJSONResponse: Codable {
    let products: [DummyJSONProduct]
    let total: Int
    let skip: Int
    let limit: Int
}

struct DummyJSONProduct: Codable {
    let id: Int
    let title: String
    let description: String
    let price: Double
    let discountPercentage: Double
    let rating: Double
    let stock: Int
    let brand: String
    let category: String
    let thumbnail: String
    let images: [String]
}

// MARK: - DummyJSON API Service
@MainActor
class DummyJSONAPIService: ObservableObject {
    @Published var products: [Product] = []
    @Published var categories: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let session = URLSession.shared
    private let baseURL = "https://dummyjson.com"
    
    // MARK: - Public Methods
    
    func fetchAllProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let url = URL(string: "\(baseURL)/products?limit=100")!
            let (data, _) = try await session.data(from: url)
            let response = try JSONDecoder().decode(DummyJSONResponse.self, from: data)
            
            // Convert to our Product model
            self.products = response.products.map { dummyProduct in
                let originalPrice = dummyProduct.price / (1.0 - dummyProduct.discountPercentage / 100.0)
                
                return Product(
                    id: String(dummyProduct.id),
                    name: dummyProduct.title,
                    description: dummyProduct.description,
                    price: dummyProduct.price,
                    originalPrice: dummyProduct.discountPercentage > 0 ? originalPrice : nil,
                    imageURL: dummyProduct.thumbnail,
                    category: mapToProductCategory(dummyProduct.category),
                    inStock: dummyProduct.stock > 0,
                    stockCount: dummyProduct.stock,
                    rating: dummyProduct.rating,
                    reviewCount: Int.random(in: 10...200), // Generate random review count
                    specifications: generateSpecifications(for: dummyProduct),
                    brand: dummyProduct.brand,
                    tags: generateTags(for: dummyProduct)
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
            // Default categories from DummyJSON
            self.categories = ["smartphones", "laptops", "fragrances", "skincare", "groceries", "home-decoration"]
        }
    }
    
    func fetchProductsByCategory(_ category: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let url = URL(string: "\(baseURL)/products/category/\(category)")!
            let (data, _) = try await session.data(from: url)
            let response = try JSONDecoder().decode(DummyJSONResponse.self, from: data)
            
            self.products = response.products.map { dummyProduct in
                let originalPrice = dummyProduct.price / (1.0 - dummyProduct.discountPercentage / 100.0)
                
                return Product(
                    id: String(dummyProduct.id),
                    name: dummyProduct.title,
                    description: dummyProduct.description,
                    price: dummyProduct.price,
                    originalPrice: dummyProduct.discountPercentage > 0 ? originalPrice : nil,
                    imageURL: dummyProduct.thumbnail,
                    category: mapToProductCategory(dummyProduct.category),
                    inStock: dummyProduct.stock > 0,
                    stockCount: dummyProduct.stock,
                    rating: dummyProduct.rating,
                    reviewCount: Int.random(in: 10...200),
                    specifications: generateSpecifications(for: dummyProduct),
                    brand: dummyProduct.brand,
                    tags: generateTags(for: dummyProduct)
                )
            }
            
        } catch {
            self.errorMessage = "Failed to fetch products: \(error.localizedDescription)"
            self.products = []
        }
        
        isLoading = false
    }
    
    func searchProducts(_ query: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
            let url = URL(string: "\(baseURL)/products/search?q=\(encodedQuery)")!
            let (data, _) = try await session.data(from: url)
            let response = try JSONDecoder().decode(DummyJSONResponse.self, from: data)
            
            self.products = response.products.map { dummyProduct in
                let originalPrice = dummyProduct.price / (1.0 - dummyProduct.discountPercentage / 100.0)
                
                return Product(
                    id: String(dummyProduct.id),
                    name: dummyProduct.title,
                    description: dummyProduct.description,
                    price: dummyProduct.price,
                    originalPrice: dummyProduct.discountPercentage > 0 ? originalPrice : nil,
                    imageURL: dummyProduct.thumbnail,
                    category: mapToProductCategory(dummyProduct.category),
                    inStock: dummyProduct.stock > 0,
                    stockCount: dummyProduct.stock,
                    rating: dummyProduct.rating,
                    reviewCount: Int.random(in: 10...200),
                    specifications: generateSpecifications(for: dummyProduct),
                    brand: dummyProduct.brand,
                    tags: generateTags(for: dummyProduct)
                )
            }
            
        } catch {
            self.errorMessage = "Failed to fetch products: \(error.localizedDescription)"
            self.products = []
        }
        
        isLoading = false
    }
}

// MARK: - Helper Methods
extension DummyJSONAPIService {
    
    private func mapToProductCategory(_ category: String) -> Product.ProductCategory {
        switch category.lowercased() {
        case "smartphones", "laptops":
            return .router // Map tech products to routers
        case "home-decoration":
            return .antenna
        case "fragrances", "skincare", "groceries":
            return .accessory
        case "automotive":
            return .cable
        default:
            return .accessory
        }
    }
    
    private func generateSpecifications(for product: DummyJSONProduct) -> [String: String] {
        var specs: [String: String] = [
            "Brand": product.brand,
            "Category": product.category.capitalized,
            "Stock": "\(product.stock) units",
            "Rating": "\(product.rating)/5.0"
        ]
        
        if product.discountPercentage > 0 {
            specs["Discount"] = "\(Int(product.discountPercentage))% off"
        }
        
        return specs
    }
    
    private func generateTags(for product: DummyJSONProduct) -> [String] {
        var tags = [product.category, product.brand.lowercased()]
        
        if product.discountPercentage > 0 {
            tags.append("on-sale")
        }
        
        if product.rating >= 4.0 {
            tags.append("highly-rated")
        }
        
        if product.stock < 10 {
            tags.append("limited-stock")
        }
        
        return tags
    }
}
