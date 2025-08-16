//
//  DataPlan.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-16.
//

import Foundation

struct DataPlan: Codable, Identifiable {
    let id: String
    let name: String
    let provider: String
    let speed: String
    let dataLimit: String
    let price: Double
    let features: [String]
    let isPopular: Bool
    
    static let mockPlans: [DataPlan] = [
        DataPlan(id: "1", name: "Basic Plan", provider: "Etell", speed: "25 Mbps", dataLimit: "100 GB", price: 29.99, features: ["Unlimited calls", "Basic support"], isPopular: false),
        DataPlan(id: "2", name: "Premium Plan", provider: "Etell", speed: "100 Mbps", dataLimit: "500 GB", price: 59.99, features: ["Unlimited calls", "Priority support", "Free router"], isPopular: true),
        DataPlan(id: "3", name: "Ultimate Plan", provider: "Etell", speed: "1 Gbps", dataLimit: "Unlimited", price: 99.99, features: ["Unlimited everything", "24/7 support", "Free mesh system"], isPopular: false)
    ]
}
