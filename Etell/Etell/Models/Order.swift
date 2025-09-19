//
//  Order.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-09-19.
//

import Foundation

struct Order: Codable, Identifiable {
    let id: String
    let userId: String
    let items: [OrderItem]
    let totalAmount: Double
    let status: OrderStatus
    let paymentMethod: String
    let billingInfo: BillingInfo
    let orderDate: Date
    let estimatedDelivery: Date?
    
    enum OrderStatus: String, CaseIterable, Codable {
        case pending = "Pending"
        case processing = "Processing"
        case shipped = "Shipped"
        case delivered = "Delivered"
        case cancelled = "Cancelled"
        
        var icon: String {
            switch self {
            case .pending: return "clock"
            case .processing: return "gear"
            case .shipped: return "shippingbox"
            case .delivered: return "checkmark.circle.fill"
            case .cancelled: return "xmark.circle.fill"
            }
        }
        
        var color: String {
            switch self {
            case .pending: return "orange"
            case .processing: return "blue"
            case .shipped: return "purple"
            case .delivered: return "green"
            case .cancelled: return "red"
            }
        }
    }
}

struct OrderItem: Codable, Identifiable {
    let id: String
    let productId: String
    let productName: String
    let productImageURL: String
    let price: Double
    let quantity: Int
    let category: String
    
    init(from product: Product, quantity: Int = 1) {
        self.id = UUID().uuidString
        self.productId = product.id
        self.productName = product.name
        self.productImageURL = product.imageURL
        self.price = product.price
        self.quantity = quantity
        self.category = product.category.rawValue
    }
}

struct BillingInfo: Codable {
    let fullName: String
    let email: String
    let address: String
    let city: String
    let zipCode: String
    
    var formattedAddress: String {
        return "\(address), \(city) \(zipCode)"
    }
}

extension Order {
    init(
        userId: String,
        items: [Product],
        paymentMethod: String,
        billingInfo: BillingInfo
    ) {
        self.id = UUID().uuidString
        self.userId = userId
        self.items = items.map { OrderItem(from: $0) }
        self.totalAmount = items.reduce(0) { $0 + $1.price }
        self.status = .pending
        self.paymentMethod = paymentMethod
        self.billingInfo = billingInfo
        self.orderDate = Date()
        self.estimatedDelivery = Calendar.current.date(byAdding: .day, value: 7, to: Date())
    }
    
    // Helper to convert to Firestore dictionary
    func toFirestoreData() -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        
        guard let data = try? encoder.encode(self),
              let dictionary = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        
        return dictionary
    }
    
    // Helper to create from Firestore data
    static func fromFirestoreData(_ data: [String: Any]) -> Order? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: data) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        
        return try? decoder.decode(Order.self, from: jsonData)
    }
}
