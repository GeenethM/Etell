//
//  TelecomAPIService.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-17.
//

import Foundation
import Combine

// MARK: - API Response Models
struct TelecomAPIResponse: Codable {
    let products: [TelecomProduct]
    let pagination: Pagination?
}

struct TelecomProduct: Codable {
    let id: String
    let name: String
    let description: String
    let price: Double
    let originalPrice: Double?
    let imageURL: String
    let category: String
    let inStock: Bool
    let specifications: [String: String]
    let brand: String
    let modelNumber: String
    let rating: Double?
    let reviewCount: Int?
    
    // Convert to our app's Product model
    func toProduct() -> Product {
        return Product(
            id: id,
            name: name,
            description: description,
            price: price,
            originalPrice: originalPrice,
            imageURL: imageURL,
            category: mapCategory(category),
            inStock: inStock,
            stockCount: inStock ? Int.random(in: 1...20) : 0,
            rating: rating ?? 4.0,
            reviewCount: reviewCount ?? 0,
            specifications: specifications,
            brand: brand,
            tags: generateTags()
        )
    }
    
    private func mapCategory(_ apiCategory: String) -> Product.ProductCategory {
        switch apiCategory.lowercased() {
        case "router", "wireless router": return .router
        case "extender", "range extender": return .extender
        case "mesh", "mesh system": return .mesh
        case "cable", "ethernet cable": return .cable
        case "modem": return .modem
        case "antenna": return .antenna
        default: return .accessory
        }
    }
    
    private func generateTags() -> [String] {
        var tags: [String] = [brand.lowercased()]
        
        if name.lowercased().contains("wifi 6") || name.lowercased().contains("ax") {
            tags.append("wifi6")
        }
        if name.lowercased().contains("gaming") {
            tags.append("gaming")
        }
        if name.lowercased().contains("mesh") {
            tags.append("mesh")
        }
        if specifications["Speed"]?.contains("Gigabit") == true {
            tags.append("gigabit")
        }
        
        return tags
    }
}

struct Pagination: Codable {
    let currentPage: Int
    let totalPages: Int
    let totalItems: Int
}

// MARK: - Telecom API Service
@MainActor
class TelecomAPIService: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let session = URLSession.shared
    private var cancellables = Set<AnyCancellable>()
    
    // API Endpoints (These would be real endpoints in production)
    private let endpoints = TelecomEndpoints()
    
    func fetchAllProducts() async {
        isLoading = true
        errorMessage = nil
        
        // For demo purposes, use realistic mock data with working image URLs
        // In production, uncomment the API calls below:
        /*
        // Fetch from multiple suppliers concurrently
        async let asusProducts = fetchASUSProducts()
        async let netgearProducts = fetchNetgearProducts()
        async let tplinkProducts = fetchTPLinkProducts()
        async let ubiquitiProducts = fetchUbiquitiProducts()
        
        do {
            let (asus, netgear, tplink, ubiquiti) = try await (asusProducts, netgearProducts, tplinkProducts, ubiquitiProducts)
            
            // Combine all products
            var allProducts: [Product] = []
            allProducts.append(contentsOf: asus)
            allProducts.append(contentsOf: netgear)
            allProducts.append(contentsOf: tplink)
            allProducts.append(contentsOf: ubiquiti)
            
            // Sort by rating and filter out duplicates
            self.products = Array(Set(allProducts)).sorted { ($0.rating ?? 0) > ($1.rating ?? 0) }
            
        } catch {
            self.errorMessage = "Failed to fetch products: \(error.localizedDescription)"
            // Fallback to mock data with working image URLs
            self.products = Product.realisticMockProducts
        }
        */
        
        // Use realistic mock data with working Amazon image URLs
        self.products = Product.realisticMockProducts
        
        isLoading = false
    }
    
    func fetchProductsByCategory(_ category: Product.ProductCategory) async {
        await fetchAllProducts()
        products = products.filter { $0.category == category }
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

// MARK: - Individual Supplier Methods
extension TelecomAPIService {
    
    private func fetchASUSProducts() async throws -> [Product] {
        // ASUS Router API (simulated - in production this would be real API)
        let url = URL(string: endpoints.asusAPI)!
        
        // For demo purposes, return realistic ASUS products
        // In production, replace with actual API call:
        // let (data, _) = try await session.data(from: url)
        // let response = try JSONDecoder().decode(TelecomAPIResponse.self, from: data)
        // return response.products.map { $0.toProduct() }
        
        return [
            Product(
                id: "asus_ax6000_rt",
                name: "ASUS RT-AX88U AX6000",
                description: "Dual-band WiFi 6 gaming router with 8 Gigabit LAN ports, adaptive QoS, and AiMesh support",
                price: 349.99,
                originalPrice: 399.99,
                imageURL: "https://dlcdnwebimgs.asus.com/gain/47e3ab2c-82be-4aa9-b30b-1b8e9e0e8e6e/",
                category: .router,
                inStock: true,
                stockCount: 12,
                rating: 4.7,
                reviewCount: 156,
                specifications: [
                    "WiFi Standard": "802.11ax (WiFi 6)",
                    "Speed": "6000 Mbps (1148 + 4804 Mbps)",
                    "Ports": "8x Gigabit LAN, 1x WAN",
                    "CPU": "1.8GHz Quad-core",
                    "Memory": "1GB RAM, 256MB Flash"
                ],
                brand: "ASUS",
                tags: ["wifi6", "gaming", "aimesh", "high-performance"]
            ),
            Product(
                id: "asus_ax1800_rt",
                name: "ASUS RT-AX55 AX1800",
                description: "Affordable WiFi 6 router with OFDMA and MU-MIMO technology for efficient connectivity",
                price: 129.99,
                originalPrice: nil,
                imageURL: "https://dlcdnwebimgs.asus.com/gain/A90E2D1B-6B64-4C58-9D4A-F8F8F8F8F8F8/",
                category: .router,
                inStock: true,
                stockCount: 8,
                rating: 4.4,
                reviewCount: 89,
                specifications: [
                    "WiFi Standard": "802.11ax (WiFi 6)",
                    "Speed": "1800 Mbps (574 + 1201 Mbps)",
                    "Ports": "4x Gigabit LAN, 1x WAN",
                    "CPU": "1.5GHz Triple-core",
                    "Coverage": "Up to 3000 sq ft"
                ],
                brand: "ASUS",
                tags: ["wifi6", "affordable", "ofdma", "mu-mimo"]
            )
        ]
    }
    
    private func fetchNetgearProducts() async throws -> [Product] {
        return [
            Product(
                id: "netgear_ax12_nighthawk",
                name: "NETGEAR Nighthawk AX12",
                description: "12-stream WiFi 6 router with 10.8Gbps speed, Dynamic QoS, and NETGEAR Armor security",
                price: 499.99,
                originalPrice: 599.99,
                imageURL: "https://www.netgear.com/media/Nighthawk-AX12_Hero_tcm148-140842.png",
                category: .router,
                inStock: true,
                stockCount: 6,
                rating: 4.6,
                reviewCount: 203,
                specifications: [
                    "WiFi Standard": "802.11ax (WiFi 6)",
                    "Speed": "10.8 Gbps",
                    "Ports": "5x Gigabit LAN, 1x WAN",
                    "CPU": "1.8GHz Quad-core",
                    "Antennas": "12 high-performance antennas"
                ],
                brand: "NETGEAR",
                tags: ["wifi6", "nighthawk", "security", "high-speed"]
            ),
            Product(
                id: "netgear_ex7300_extender",
                name: "NETGEAR EX7300 WiFi Extender",
                description: "AC2200 tri-band WiFi extender with FastLane3 technology and one Gigabit port",
                price: 129.99,
                originalPrice: nil,
                imageURL: "https://www.netgear.com/media/EX7300_Hero_tcm148-95847.png",
                category: .extender,
                inStock: true,
                stockCount: 15,
                rating: 4.2,
                reviewCount: 124,
                specifications: [
                    "WiFi Standard": "802.11ac",
                    "Speed": "2.2 Gbps",
                    "Bands": "Tri-band (2.4GHz + 2x 5GHz)",
                    "Ports": "1x Gigabit Ethernet",
                    "Coverage": "Up to 2300 sq ft"
                ],
                brand: "NETGEAR",
                tags: ["extender", "tri-band", "fastlane3", "gigabit"]
            )
        ]
    }
    
    private func fetchTPLinkProducts() async throws -> [Product] {
        return [
            Product(
                id: "tplink_archer_ax73",
                name: "TP-Link Archer AX73 AX5400",
                description: "Dual-band WiFi 6 router with OneMesh support, advanced security, and VPN server",
                price: 179.99,
                originalPrice: 199.99,
                imageURL: "https://static.tp-link.com/upload/image-line/Archer%20AX73_1920.png",
                category: .router,
                inStock: true,
                stockCount: 10,
                rating: 4.5,
                reviewCount: 178,
                specifications: [
                    "WiFi Standard": "802.11ax (WiFi 6)",
                    "Speed": "5400 Mbps (574 + 4804 Mbps)",
                    "Ports": "4x Gigabit LAN, 1x WAN",
                    "CPU": "1.5GHz Triple-core",
                    "OneMesh": "Yes"
                ],
                brand: "TP-Link",
                tags: ["wifi6", "onemesh", "vpn", "security"]
            ),
            Product(
                id: "tplink_deco_x60",
                name: "TP-Link Deco X60 Mesh System",
                description: "AX3000 whole home mesh WiFi 6 system with AI-driven mesh and advanced security",
                price: 299.99,
                originalPrice: nil,
                imageURL: "https://static.tp-link.com/upload/image-line/Deco%20X60_1920.png",
                category: .mesh,
                inStock: true,
                stockCount: 7,
                rating: 4.8,
                reviewCount: 95,
                specifications: [
                    "WiFi Standard": "802.11ax (WiFi 6)",
                    "Speed": "3000 Mbps",
                    "Coverage": "Up to 5000 sq ft (2-pack)",
                    "Ports": "2x Gigabit per unit",
                    "AI Mesh": "Yes"
                ],
                brand: "TP-Link",
                tags: ["mesh", "wifi6", "ai-driven", "whole-home"]
            )
        ]
    }
    
    private func fetchUbiquitiProducts() async throws -> [Product] {
        return [
            Product(
                id: "ubiquiti_dream_machine",
                name: "Ubiquiti Dream Machine",
                description: "All-in-one enterprise router with WiFi 6, 8-port switch, and UniFi Network application",
                price: 449.99,
                originalPrice: nil,
                imageURL: "https://cdn.ecommercedns.uk/files/8/254788/1/27254561/udm-front-angle.png",
                category: .router,
                inStock: true,
                stockCount: 4,
                rating: 4.9,
                reviewCount: 67,
                specifications: [
                    "WiFi Standard": "802.11ax (WiFi 6)",
                    "Speed": "3.5 Gbps",
                    "Ports": "8x Gigabit LAN, 1x WAN",
                    "CPU": "1.7GHz Quad-core ARM",
                    "Management": "UniFi Network Controller"
                ],
                brand: "Ubiquiti",
                tags: ["enterprise", "unifi", "all-in-one", "prosumer"]
            ),
            Product(
                id: "ubiquiti_amplifi_alien",
                name: "Ubiquiti AmpliFi Alien",
                description: "Consumer WiFi 6 router with touchscreen display and exceptional range performance",
                price: 379.99,
                originalPrice: 429.99,
                imageURL: "https://cdn.ecommercedns.uk/files/8/254788/1/27254982/afi-a-us-front-angle.png",
                category: .router,
                inStock: false,
                stockCount: 0,
                rating: 4.7,
                reviewCount: 143,
                specifications: [
                    "WiFi Standard": "802.11ax (WiFi 6)",
                    "Speed": "5.25 Gbps",
                    "Display": "Color touchscreen",
                    "Ports": "4x Gigabit LAN, 1x WAN",
                    "Range": "Up to 15,000 sq ft"
                ],
                brand: "Ubiquiti",
                tags: ["consumer", "touchscreen", "long-range", "amplifi"]
            )
        ]
    }
}

// MARK: - API Endpoints Configuration
struct TelecomEndpoints {
    // In production, these would be real API endpoints
    let asusAPI = "https://api.asus.com/products/networking"
    let netgearAPI = "https://api.netgear.com/products"
    let tplinkAPI = "https://api.tp-link.com/products/networking"
    let ubiquitiAPI = "https://api.ubnt.com/products"
    
    // Authentication headers (would be real API keys)
    var headers: [String: String] {
        return [
            "Content-Type": "application/json",
            "X-API-Key": "your-api-key-here", // Replace with real API keys
            "User-Agent": "Etell-iOS-App/1.0"
        ]
    }
}
