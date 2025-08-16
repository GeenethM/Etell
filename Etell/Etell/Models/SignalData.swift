//
//  SignalData.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-16.
//

import Foundation
import CoreLocation

struct Tower: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let signalStrength: Double // 0.0 to 1.0
}

struct RoomCalibration: Identifiable {
    let id = UUID()
    let roomName: String
    let location: CLLocationCoordinate2D
    let signalStrength: Double
    let orientation: Double // compass heading
    let timestamp: Date
}

struct CalibrationResult {
    let averageSignalStrength: Double
    let weakAreas: [RoomCalibration]
    let optimalRouterLocation: CLLocationCoordinate2D?
    let recommendedProducts: [Product]
}

struct SpeedTestResult: Identifiable {
    let id = UUID()
    let downloadSpeed: Double // Mbps
    let uploadSpeed: Double // Mbps
    let ping: Double // ms
    let timestamp: Date
    let location: String?
}
