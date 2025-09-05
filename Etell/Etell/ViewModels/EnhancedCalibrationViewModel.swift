//
//  EnhancedCalibrationFlow.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-23.
//

import SwiftUI
import AVFoundation
import CoreLocation

// MARK: - Calibration Step Enum

enum CalibrationStep {
    case instructions
    case calibrating
    case locationDetails
    case nextRoom
    case completed
}

// MARK: - Enhanced Calibration View Model
@MainActor
class EnhancedCalibrationViewModel: ObservableObject {
    @Published var currentStep: CalibrationStep = .instructions
    @Published var isCalibrating = false
    @Published var currentSignalStrength: Double = 0.0
    @Published var calibratedLocations: [CalibratedLocation] = []
    @Published var showingLocationDetails = false
    @Published var selectedLocationType: LocationType?
    @Published var selectedFloor: Int = 1
    @Published var customLocationName: String = ""
    @Published var calibrationProgress: Double = 0.0
    @Published var showingResults = false
    
    private let locationManager = CLLocationManager()
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    init() {
        requestLocationPermission()
    }
    
    private func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startCalibrationFlow() {
        currentStep = .instructions
        speak("Go to the room you want to calibrate")
    }
    
    func startRoomCalibration() {
        currentStep = .calibrating
        isCalibrating = true
        calibrationProgress = 0.0
        
        speak("Starting calibration. Please wait.")
        
        // Simulate calibration process with progress
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            self.calibrationProgress += 0.02
            self.currentSignalStrength = 0.3 + (Double.random(in: 0...0.7))
            
            if self.calibrationProgress >= 1.0 {
                timer.invalidate()
                self.completeCalibration()
            }
        }
    }
    
    private func completeCalibration() {
        isCalibrating = false
        currentStep = .locationDetails
        showingLocationDetails = true
        speak("Calibration complete. Please specify the location type.")
    }
    
    func saveCurrentLocation() {
        guard let locationType = selectedLocationType else { return }
        
        let locationName = customLocationName.isEmpty ? 
            "\(locationType.rawValue) \(calibratedLocations.count + 1)" : 
            customLocationName
        
        let recommendations = generateRecommendations(
            for: locationType, 
            signalStrength: currentSignalStrength,
            floor: selectedFloor
        )
        
        let location = CalibratedLocation(
            name: locationName,
            type: locationType,
            floor: selectedFloor,
            signalStrength: currentSignalStrength,
            coordinates: getCurrentCoordinates(),
            timestamp: Date(),
            recommendations: recommendations
        )
        
        calibratedLocations.append(location)
        
        // Reset for next room
        resetForNextRoom()
        currentStep = .nextRoom
        
        speak("Location saved. Move to the next room you want to calibrate.")
    }
    
    private func resetForNextRoom() {
        selectedLocationType = nil
        selectedFloor = 1
        customLocationName = ""
        currentSignalStrength = 0.0
        calibrationProgress = 0.0
        showingLocationDetails = false
    }
    
    func moveToNextRoom() {
        currentStep = .instructions
        speak("Go to the next room to calibrate")
    }
    
    func finishCalibration() {
        currentStep = .completed
        showingResults = true
        speak("Calibration complete. Generating recommendations.")
    }
    
    private func getCurrentCoordinates() -> CLLocationCoordinate2D? {
        // In a real app, you'd get actual coordinates
        return CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    }
    
    private func generateRecommendations(for type: LocationType, signalStrength: Double, floor: Int) -> [String] {
        var recommendations: [String] = []
        
        // Signal strength based recommendations
        switch signalStrength {
        case 0.0..<0.3:
            recommendations.append("Poor signal - Consider WiFi extender")
        case 0.3..<0.6:
            recommendations.append("Moderate signal - May need signal boost")
        case 0.6..<0.8:
            recommendations.append("Good signal strength")
        default:
            recommendations.append("Excellent signal strength")
        }
        
        // Location type based recommendations
        switch type {
        case .room:
            if signalStrength < 0.5 {
                recommendations.append("Consider mesh node in this room")
            }
        case .hallway:
            recommendations.append("Strategic location for WiFi extender")
        case .staircase:
            recommendations.append("Important transition point - consider coverage")
        }
        
        // Floor based recommendations
        if floor > 1 && signalStrength < 0.6 {
            recommendations.append("Upper floor may need dedicated access point")
        }
        
        return recommendations
    }
    
    private func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        speechSynthesizer.speak(utterance)
    }
    
    func generateFinalRecommendations() -> CalibrationSummary {
        let weakAreas = calibratedLocations.filter { $0.signalStrength < 0.5 }
        let strongAreas = calibratedLocations.filter { $0.signalStrength >= 0.7 }
        
        var routerRecommendations: [String] = []
        var extenderRecommendations: [ExtenderRecommendation] = []
        
        // Find optimal router location (highest average signal to all areas)
        if let bestLocation = findOptimalRouterLocation() {
            routerRecommendations.append("Place main router near \(bestLocation.name)")
        }
        
        // Generate extender recommendations
        for weakArea in weakAreas {
            let extender = ExtenderRecommendation(
                location: weakArea.name,
                floor: weakArea.floor,
                reason: "Signal strength only \(Int(weakArea.signalStrength * 100))%",
                type: weakArea.type == .hallway ? .hallwayExtender : .roomExtender
            )
            extenderRecommendations.append(extender)
        }
        
        return CalibrationSummary(
            totalLocations: calibratedLocations.count,
            weakAreas: weakAreas,
            strongAreas: strongAreas,
            routerRecommendations: routerRecommendations,
            extenderRecommendations: extenderRecommendations,
            averageSignalStrength: calibratedLocations.map { $0.signalStrength }.reduce(0, +) / Double(calibratedLocations.count)
        )
    }
    
    private func findOptimalRouterLocation() -> CalibratedLocation? {
        return calibratedLocations.max { location1, location2 in
            // Prefer central locations with good signal
            let score1 = location1.signalStrength * (location1.type == .room ? 1.2 : 1.0)
            let score2 = location2.signalStrength * (location2.type == .room ? 1.2 : 1.0)
            return score1 < score2
        }
    }
}

// MARK: - Supporting Data Models
struct CalibrationSummary {
    let totalLocations: Int
    let weakAreas: [CalibratedLocation]
    let strongAreas: [CalibratedLocation]
    let routerRecommendations: [String]
    let extenderRecommendations: [ExtenderRecommendation]
    let averageSignalStrength: Double
}

struct ExtenderRecommendation {
    let location: String
    let floor: Int
    let reason: String
    let type: ExtenderType
}

enum ExtenderType {
    case roomExtender
    case hallwayExtender
    
    var description: String {
        switch self {
        case .roomExtender: return "Room WiFi Extender"
        case .hallwayExtender: return "Hallway WiFi Extender"
        }
    }
}
