//
//  Product.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-16.
//

import Foundation

struct Product: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let price: Double
    let imageURL: String
    let category: ProductCategory
    let inStock: Bool
    
    enum ProductCategory: String, CaseIterable, Codable {
        case router = "Router"
        case extender = "Extender"
        case mesh = "Mesh System"
        case cable = "Cable"
        case accessory = "Accessory"
    }
    
    static let mockProducts: [Product] = [
        Product(id: "1", name: "WiFi 6 Router", description: "High-speed wireless router with WiFi 6 technology", price: 199.99, imageURL: "router1", category: .router, inStock: true),
        Product(id: "2", name: "Range Extender Pro", description: "Extend your WiFi coverage to every corner", price: 89.99, imageURL: "extender1", category: .extender, inStock: true),
        Product(id: "3", name: "Mesh System 3-Pack", description: "Complete mesh network for large homes", price: 399.99, imageURL: "mesh1", category: .mesh, inStock: false),
        Product(id: "4", name: "Ethernet Cable 50ft", description: "Cat 6 ethernet cable for stable connections", price: 29.99, imageURL: "cable1", category: .cable, inStock: true)
    ]
}
