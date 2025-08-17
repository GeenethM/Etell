//
//  SignalCalibrationService.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-16.
//

import Foundation
import CoreLocation
import CoreMotion
import MapKit

class SignalCalibrationService: NSObject, ObservableObject {
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var currentHeading: Double = 0
    @Published var calibrations: [RoomCalibration] = []
    @Published var towers: [Tower] = []
    
    private let locationManager = CLLocationManager()
    private let motionManager = CMMotionManager()
    
    override init() {
        super.init()
        setupLocationManager()
        setupMotionManager()
        generateMockTowers()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func setupMotionManager() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.1
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
                guard let motion = motion else { return }
                
                // Calculate heading from device motion
                let heading = atan2(motion.attitude.yaw, motion.attitude.pitch) * 180 / .pi
                self?.currentHeading = heading
            }
        }
    }
    
    private func generateMockTowers() {
        // Generate some mock cell towers around the user's location
        let mockTowerLocations = [
            CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // San Francisco
            CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094),
            CLLocationCoordinate2D(latitude: 37.7649, longitude: -122.4294),
            CLLocationCoordinate2D(latitude: 37.7549, longitude: -122.4394)
        ]
        
        towers = mockTowerLocations.enumerated().map { index, coordinate in
            Tower(
                name: "Tower \(index + 1)",
                coordinate: coordinate,
                signalStrength: Double.random(in: 0.3...1.0)
            )
        }
    }
    
    func startLocationUpdates() {
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    func calibrateSignalInRoom(roomName: String) {
        guard let location = userLocation else { return }
        
        // Mock signal strength calculation based on distance to towers
        let signalStrength = calculateMockSignalStrength(at: location)
        
        let calibration = RoomCalibration(
            roomName: roomName,
            location: location,
            signalStrength: signalStrength,
            orientation: currentHeading,
            timestamp: Date()
        )
        
        calibrations.append(calibration)
    }
    
    private func calculateMockSignalStrength(at location: CLLocationCoordinate2D) -> Double {
        // Mock calculation based on distance to nearest tower
        let nearestTower = towers.min { tower1, tower2 in
            let distance1 = CLLocation(latitude: location.latitude, longitude: location.longitude)
                .distance(from: CLLocation(latitude: tower1.coordinate.latitude, longitude: tower1.coordinate.longitude))
            let distance2 = CLLocation(latitude: location.latitude, longitude: location.longitude)
                .distance(from: CLLocation(latitude: tower2.coordinate.latitude, longitude: tower2.coordinate.longitude))
            return distance1 < distance2
        }
        
        guard let tower = nearestTower else { return 0.0 }
        
        let distance = CLLocation(latitude: location.latitude, longitude: location.longitude)
            .distance(from: CLLocation(latitude: tower.coordinate.latitude, longitude: tower.coordinate.longitude))
        
        // Mock signal strength: closer = stronger signal, with some randomness
        let baseStrength = max(0.1, 1.0 - (distance / 10000.0)) // Weaker with distance
        let randomFactor = Double.random(in: 0.8...1.2) // Add some variance
        
        return min(1.0, baseStrength * randomFactor)
    }
    
    func generateCalibrationResult() -> CalibrationResult {
        let averageSignal = calibrations.isEmpty ? 0.0 : calibrations.map(\.signalStrength).reduce(0, +) / Double(calibrations.count)
        let weakAreas = calibrations.filter { $0.signalStrength < 0.5 }
        
        // Suggest optimal router location (center of strong signal areas)
        let strongAreas = calibrations.filter { $0.signalStrength >= 0.5 }
        let optimalLocation = strongAreas.isEmpty ? nil : CLLocationCoordinate2D(
            latitude: strongAreas.map(\.location.latitude).reduce(0, +) / Double(strongAreas.count),
            longitude: strongAreas.map(\.location.longitude).reduce(0, +) / Double(strongAreas.count)
        )
        
        // Recommend products based on weak areas
        var recommendedProducts: [Product] = []
        if !weakAreas.isEmpty {
            if weakAreas.count <= 2 {
                recommendedProducts.append(contentsOf: Product.mockProducts.filter { $0.category == .extender })
            } else {
                recommendedProducts.append(contentsOf: Product.mockProducts.filter { $0.category == .mesh })
            }
        }
        
        return CalibrationResult(
            averageSignalStrength: averageSignal,
            weakAreas: weakAreas,
            optimalRouterLocation: optimalLocation,
            recommendedProducts: recommendedProducts
        )
    }
    
    func clearCalibrations() {
        calibrations.removeAll()
    }
    
    func addTower(_ tower: Tower) {
        towers.append(tower)
    }
    
    func removeTower(_ tower: Tower) {
        towers.removeAll { $0.id == tower.id }
    }
    
    func clearAllTowers() {
        towers.removeAll()
        generateMockTowers() // Regenerate default mock towers
    }
}

// MARK: - CLLocationManagerDelegate
extension SignalCalibrationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location.coordinate
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        case .denied, .restricted:
            print("Location access denied")
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
}
