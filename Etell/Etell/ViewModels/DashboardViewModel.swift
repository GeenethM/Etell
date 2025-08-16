//
//  DashboardViewModel.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-16.
//

import Foundation

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var currentDataUsage: Double = 0.0
    @Published var dataLimit: Double = 100.0
    @Published var currentSpeed: String = "0 Mbps"
    @Published var connectionStatus: ConnectionStatus = .connected
    @Published var recentActivities: [Activity] = []
    
    enum ConnectionStatus {
        case connected
        case disconnected
        case poor
        
        var displayText: String {
            switch self {
            case .connected: return "Connected"
            case .disconnected: return "Disconnected"
            case .poor: return "Poor Connection"
            }
        }
        
        var color: String {
            switch self {
            case .connected: return "green"
            case .disconnected: return "red"
            case .poor: return "orange"
            }
        }
    }
    
    struct Activity: Identifiable {
        let id = UUID()
        let title: String
        let description: String
        let timestamp: Date
        let type: ActivityType
        
        enum ActivityType {
            case speedTest
            case planChange
            case deviceConnected
            case calibration
        }
    }
    
    init() {
        loadDashboardData()
    }
    
    func loadDashboardData() {
        // Mock data loading
        currentDataUsage = Double.random(in: 20...80)
        currentSpeed = "\(Int.random(in: 25...100)) Mbps"
        connectionStatus = [.connected, .poor].randomElement() ?? .connected
        
        recentActivities = [
            Activity(title: "Speed Test Completed", description: "Download: 95 Mbps, Upload: 45 Mbps", timestamp: Date().addingTimeInterval(-3600), type: .speedTest),
            Activity(title: "Device Connected", description: "iPhone 15 Pro connected to network", timestamp: Date().addingTimeInterval(-7200), type: .deviceConnected),
            Activity(title: "Signal Calibration", description: "Living room calibrated - Good signal", timestamp: Date().addingTimeInterval(-86400), type: .calibration)
        ]
    }
    
    func refreshData() {
        loadDashboardData()
    }
    
    var dataUsagePercentage: Double {
        min(currentDataUsage / dataLimit, 1.0)
    }
    
    var dataUsageColor: String {
        switch dataUsagePercentage {
        case 0..<0.7: return "green"
        case 0.7..<0.9: return "orange"
        default: return "red"
        }
    }
}
