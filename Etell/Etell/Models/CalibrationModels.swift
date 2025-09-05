//
//  CalibrationModels.swift
//  Etell
//
//  Created by GitHub Copilot on 2025-09-05.
//

import Foundation
import CoreLocation

// MARK: - Shared Calibration Data Models

enum LocationType: String, CaseIterable {
    case room = "Room"
    case hallway = "Hallway"
    case staircase = "Staircase"
    
    var icon: String {
        switch self {
        case .room: return "house.fill"
        case .hallway: return "rectangle.split.3x1"
        case .staircase: return "stairs"
        }
    }
    
    var description: String {
        switch self {
        case .room: return "Living space or specific room"
        case .hallway: return "Corridor or passage"
        case .staircase: return "Stairway between floors"
        }
    }
}

struct CalibratedLocation {
    let id = UUID()
    let name: String
    let type: LocationType
    let floor: Int
    let signalStrength: Double
    let coordinates: CLLocationCoordinate2D?
    let timestamp: Date
    let recommendations: [String]
}
