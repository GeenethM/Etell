// Enhanced Product Model with more realistic data
import Foundation

struct Product: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let price: Double
    let originalPrice: Double? // For showing discounts
    let imageURL: String
    let category: ProductCategory
    let inStock: Bool
    let stockCount: Int
    let rating: Double
    let reviewCount: Int
    let specifications: [String: String]
    let brand: String
    let tags: [String]
    
    enum ProductCategory: String, CaseIterable, Codable {
        case router = "Router"
        case extender = "Extender" 
        case mesh = "Mesh System"
        case cable = "Cable"
        case accessory = "Accessory"
        case modem = "Modem"
        case antenna = "Antenna"
        
        var icon: String {
            switch self {
            case .router: return "wifi.router"
            case .extender: return "antenna.radiowaves.left.and.right"
            case .mesh: return "network"
            case .cable: return "cable.connector"
            case .accessory: return "gear"
            case .modem: return "externaldrive.connected.to.line.below"
            case .antenna: return "dot.radiowaves.up.forward"
            }
        }
    }
    
    static let realisticMockProducts: [Product] = [
        // Routers
        Product(
            id: "asus_ax6000",
            name: "ASUS AX6000 WiFi 6 Router",
            description: "Ultra-fast AX6000 WiFi 6 router with 8 Gigabit ports, AiMesh support, and advanced security features. Perfect for large homes and gaming.",
            price: 299.99,
            originalPrice: 349.99,
            imageURL: "https://m.media-amazon.com/images/I/61-qVKQg5YL._AC_SL1500_.jpg",
            category: .router,
            inStock: true,
            stockCount: 15,
            rating: 4.6,
            reviewCount: 234,
            specifications: [
                "WiFi Standard": "WiFi 6 (802.11ax)",
                "Speed": "AX6000 (4804 + 1148 Mbps)",
                "Coverage": "Up to 3,000 sq ft",
                "Ports": "1x WAN + 8x LAN Gigabit",
                "Antennas": "8 external antennas"
            ],
            brand: "ASUS",
            tags: ["gaming", "wifi6", "mesh-ready", "high-performance"]
        ),
        
        Product(
            id: "netgear_ax1800",
            name: "NETGEAR Nighthawk AX1800",
            description: "Affordable WiFi 6 router with excellent coverage for medium-sized homes. Features NETGEAR Armor security and Smart Connect.",
            price: 129.99,
            originalPrice: nil,
            imageURL: "https://m.media-amazon.com/images/I/51TQr1hBHkL._AC_SL1024_.jpg",
            category: .router,
            inStock: true,
            stockCount: 8,
            rating: 4.3,
            reviewCount: 156,
            specifications: [
                "WiFi Standard": "WiFi 6 (802.11ax)",
                "Speed": "AX1800 (1201 + 574 Mbps)",
                "Coverage": "Up to 1,500 sq ft",
                "Ports": "1x WAN + 4x LAN Gigabit",
                "Antennas": "4 external antennas"
            ],
            brand: "NETGEAR",
            tags: ["wifi6", "security", "smart-connect"]
        ),
        
        // Mesh Systems
        Product(
            id: "eero_pro6e",
            name: "eero Pro 6E Mesh System (3-pack)",
            description: "Tri-band WiFi 6E mesh system covering up to 6,000 sq ft. Easy setup with eero app and built-in Zigbee smart home hub.",
            price: 599.99,
            originalPrice: 699.99,
            imageURL: "https://m.media-amazon.com/images/I/31B-Q8sKQnL._AC_SL1000_.jpg",
            category: .mesh,
            inStock: true,
            stockCount: 5,
            rating: 4.7,
            reviewCount: 89,
            specifications: [
                "WiFi Standard": "WiFi 6E",
                "Speed": "Up to 2.3 Gbps",
                "Coverage": "Up to 6,000 sq ft",
                "Nodes": "3 eero Pro 6E units",
                "Ports": "2x Gigabit per node"
            ],
            brand: "eero",
            tags: ["mesh", "wifi6e", "smart-home", "easy-setup"]
        ),
        
        // Range Extenders
        Product(
            id: "tplink_re650",
            name: "TP-Link AC2600 WiFi Extender",
            description: "Powerful AC2600 dual-band WiFi extender with OneMesh compatibility. Extends WiFi coverage up to 14,000 sq ft.",
            price: 79.99,
            originalPrice: 99.99,
            imageURL: "https://m.media-amazon.com/images/I/51VXnI-k2xL._AC_SL1000_.jpg",
            category: .extender,
            inStock: true,
            stockCount: 12,
            rating: 4.2,
            reviewCount: 203,
            specifications: [
                "WiFi Standard": "AC2600 dual-band",
                "Speed": "800 Mbps (2.4GHz) + 1733 Mbps (5GHz)",
                "Coverage": "Up to 14,000 sq ft",
                "Ports": "1x Gigabit Ethernet",
                "Antennas": "4 external antennas"
            ],
            brand: "TP-Link",
            tags: ["extender", "onemesh", "dual-band", "gigabit"]
        ),
        
        // Cables & Accessories
        Product(
            id: "cat8_cable_25ft",
            name: "Cat 8 Ethernet Cable 25ft",
            description: "High-speed Cat 8 ethernet cable supporting up to 40Gbps. Perfect for gaming, streaming, and professional applications.",
            price: 24.99,
            originalPrice: nil,
            imageURL: "https://m.media-amazon.com/images/I/61TK8YfWbFL._AC_SL1500_.jpg",
            category: .cable,
            inStock: true,
            stockCount: 25,
            rating: 4.8,
            reviewCount: 67,
            specifications: [
                "Category": "Cat 8",
                "Speed": "Up to 40 Gbps",
                "Length": "25 feet",
                "Connector": "RJ45",
                "Shielding": "S/FTP"
            ],
            brand: "DbillionDa",
            tags: ["cat8", "high-speed", "gaming", "professional"]
        ),
        
        Product(
            id: "wall_mount_bracket",
            name: "Universal Router Wall Mount",
            description: "Adjustable wall mount bracket for routers and modems. Saves space and improves ventilation with cable management.",
            price: 15.99,
            originalPrice: nil,
            imageURL: "https://m.media-amazon.com/images/I/71yQXJd5jkL._AC_SL1500_.jpg",
            category: .accessory,
            inStock: true,
            stockCount: 18,
            rating: 4.4,
            reviewCount: 142,
            specifications: [
                "Material": "Heavy-duty steel",
                "Weight Capacity": "Up to 8 lbs",
                "Mounting": "Wall-mounted",
                "Compatibility": "Universal",
                "Cable Management": "Built-in clips"
            ],
            brand: "HumanCentric",
            tags: ["mount", "organization", "space-saving", "universal"]
        )
    ]
}
