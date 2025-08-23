//
//  CalibrationSetupService.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-23.
//

import Foundation
import Combine

@MainActor
class CalibrationSetupService: ObservableObject {
    @Published var currentSetup: CalibrationSetupData?
    
    static let shared = CalibrationSetupService()
    
    private init() {}
    
    func saveSetupData(_ setup: CalibrationSetupData) {
        currentSetup = setup
        
        // You can also persist this data for future use
        if let data = try? JSONEncoder().encode(setup) {
            UserDefaults.standard.set(data, forKey: "calibration_setup_data")
        }
    }
    
    func loadSetupData() -> CalibrationSetupData? {
        if let data = UserDefaults.standard.data(forKey: "calibration_setup_data"),
           let setup = try? JSONDecoder().decode(CalibrationSetupData.self, from: data) {
            currentSetup = setup
            return setup
        }
        return nil
    }
    
    func clearSetupData() {
        currentSetup = nil
        UserDefaults.standard.removeObject(forKey: "calibration_setup_data")
    }
    
    func getRecommendations() -> [String] {
        guard let setup = currentSetup else { return [] }
        
        var recommendations: [String] = []
        
        // Environment-based recommendations
        switch setup.environmentType {
        case .house:
            recommendations.append("Place router on the main floor for best coverage")
            if setup.numberOfFloors ?? 0 > 1 {
                recommendations.append("Consider a mesh system for multi-floor coverage")
            }
        case .apartment:
            recommendations.append("Central placement works best in apartments")
            recommendations.append("Avoid placing router near neighboring units")
        case .office:
            recommendations.append("Position router away from conference rooms")
            recommendations.append("Consider business-grade equipment for offices")
        case .none:
            break
        }
        
        // Floor-based recommendations
        if let floors = setup.numberOfFloors {
            if floors > 2 {
                recommendations.append("Three-floor setup may need signal boosters")
            }
        }
        
        // Hallway-based recommendations
        if let hasHallways = setup.hasHallways {
            if hasHallways {
                recommendations.append("Place router with clear line-of-sight to hallways")
                recommendations.append("Avoid corners and closed spaces")
            } else {
                recommendations.append("Open floor plan allows flexible router placement")
            }
        }
        
        return recommendations
    }
}

// Make CalibrationSetupData Codable for persistence
extension CalibrationSetupData: Codable {
    enum CodingKeys: String, CodingKey {
        case environmentType
        case numberOfFloors
        case hasHallways
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(environmentType, forKey: .environmentType)
        try container.encodeIfPresent(numberOfFloors, forKey: .numberOfFloors)
        try container.encodeIfPresent(hasHallways, forKey: .hasHallways)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        environmentType = try container.decodeIfPresent(EnvironmentType.self, forKey: .environmentType)
        numberOfFloors = try container.decodeIfPresent(Int.self, forKey: .numberOfFloors)
        hasHallways = try container.decodeIfPresent(Bool.self, forKey: .hasHallways)
    }
}

extension EnvironmentType: Codable {}
