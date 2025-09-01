//
//  SensorCalibrationService.swift
//  Etell
//
//  Created by GitHub Copilot on 2025-09-01.
//

import Foundation
import CoreLocation
#if !os(macOS)
import CoreMotion
#endif
import Combine

// MARK: - Data Models
struct SensorCalibrationPoint {
    let id = UUID()
    let name: String
    let location: CLLocationCoordinate2D
    let altitude: Double // From barometer
    let relativeHeight: Double // Height from reference point
    let magneticHeading: Double
    let trueHeading: Double
    #if !os(macOS)
    let accelerometerData: CMAccelerometerData?
    let gyroscopeData: CMGyroData?
    let magnetometerData: CMMagnetometerData?
    #endif
    let signalStrength: Double
    let timestamp: Date
    let distanceFromPrevious: Double // Calculated distance
    let stepCount: Int // Estimated steps taken
}

struct CalibrationSession {
    let id = UUID()
    let startTime: Date
    var endTime: Date?
    var points: [SensorCalibrationPoint] = []
    var referencePoint: SensorCalibrationPoint?
    var setupData: CalibrationSetupData?
}

struct WiFiOptimizationResult {
    let optimalRouterLocation: SensorCalibrationPoint
    let recommendedExtenders: [ExtenderRecommendation]
    let coverageAnalysis: CoverageAnalysis
    let signalPrediction: SignalPredictionMap
}

struct SignalPredictionMap {
    let predictions: [String: Double] // Using string key instead of CLLocationCoordinate2D
    let resolution: Double // meters per grid point
}

// MARK: - Sensor Calibration Service
class SensorCalibrationService: NSObject, ObservableObject {
    @Published var currentSession: CalibrationSession?
    @Published var isCalibrating = false
    @Published var currentPoint: SensorCalibrationPoint?
    @Published var sensorData: SensorRealtimeData = SensorRealtimeData()
    @Published var calibrationProgress: Double = 0.0
    @Published var locationAuthorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: String?
    
    // Sensor managers
    private let locationManager = CLLocationManager()
    #if !os(macOS)
    private let motionManager = CMMotionManager()
    private let altimeter = CMAltimeter()
    private let pedometer = CMPedometer()
    #endif
    
    // Current sensor readings
    private var lastLocation: CLLocation?
    private var referenceAltitude: Double?
    private var stepsSinceLastPoint: Int = 0
    
    override init() {
        super.init()
        setupSensors()
    }
    
    // MARK: - Sensor Setup
    private func setupSensors() {
        setupLocationManager()
        setupMotionManager()
        setupAltimeter()
        setupPedometer()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // Update initial authorization status
        locationAuthorizationStatus = locationManager.authorizationStatus
        
        // Request authorization if not determined
        if locationAuthorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    private func setupMotionManager() {
        #if !os(macOS)
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.1
            motionManager.showsDeviceMovementDisplay = true
        }
        #endif
    }
    
    private func setupAltimeter() {
        #if !os(macOS)
        if CMAltimeter.isRelativeAltitudeAvailable() {
            altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, error in
                if let data = data {
                    DispatchQueue.main.async {
                        self?.sensorData.relativeAltitude = data.relativeAltitude.doubleValue
                        self?.sensorData.pressure = data.pressure.doubleValue
                    }
                }
            }
        }
        #endif
    }
    
    private func setupPedometer() {
        #if !os(macOS)
        if CMPedometer.isStepCountingAvailable() {
            // Will be used for distance estimation between points
        }
        #endif
    }
    
    // MARK: - Calibration Session Management
    func startNewSession(setupData: CalibrationSetupData) {
        currentSession = CalibrationSession(
            startTime: Date(),
            setupData: setupData
        )
        isCalibrating = true
        startSensorUpdates()
    }
    
    func endCurrentSession() {
        currentSession?.endTime = Date()
        isCalibrating = false
        stopSensorUpdates()
    }
    
    private func startSensorUpdates() {
        // Only start location updates if authorized
        if locationAuthorizationStatus == .authorizedWhenInUse || locationAuthorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
            print("✅ Started location and heading updates")
        } else {
            print("⚠️ Location not authorized, requesting permission...")
            locationManager.requestWhenInUseAuthorization()
        }
        
        #if !os(macOS)
        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
                if let motion = motion {
                    DispatchQueue.main.async {
                        self?.updateSensorData(with: motion)
                    }
                }
            }
        }
        
        // Start step counting from now
        if CMPedometer.isStepCountingAvailable() {
            pedometer.startUpdates(from: Date()) { [weak self] data, error in
                if let data = data {
                    DispatchQueue.main.async {
                        self?.sensorData.stepCount = data.numberOfSteps.intValue
                    }
                }
            }
        }
        #endif
    }
    
    private func stopSensorUpdates() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        #if !os(macOS)
        motionManager.stopDeviceMotionUpdates()
        altimeter.stopRelativeAltitudeUpdates()
        pedometer.stopUpdates()
        #endif
    }
    
    #if !os(macOS)
    private func updateSensorData(with motion: CMDeviceMotion) {
        sensorData.acceleration = motion.userAcceleration
        sensorData.rotation = motion.rotationRate
            sensorData.magneticField = motion.magneticField
        sensorData.attitude = motion.attitude
    }
    #endif
    
    // MARK: - Calibration Point Capture
    func captureCalibrationPoint(name: String) -> Bool {
        // Check location authorization first
        guard locationAuthorizationStatus == .authorizedWhenInUse || locationAuthorizationStatus == .authorizedAlways else {
            let errorMessage = "Location access required to capture calibration points. Current status: \(locationAuthorizationStatus.description)"
            DispatchQueue.main.async {
                self.locationError = errorMessage
            }
            print("❌ \(errorMessage)")
            return false
        }
        
        guard let session = currentSession,
              let location = lastLocation else {
            let errorMessage = "Cannot capture point: No active session or location"
            DispatchQueue.main.async {
                self.locationError = errorMessage
            }
            print("❌ \(errorMessage)")
            return false
        }
        
        print("📍 Capturing calibration point: \(name)")
        
        // Calculate distance from previous point
        let distanceFromPrevious = calculateDistanceFromPrevious(location: location)
        
        // Get current signal strength (simulated for now)
        let signalStrength = simulateSignalStrength(at: location.coordinate)
        
        // Set reference altitude if this is the first point
        if session.points.isEmpty {
            referenceAltitude = sensorData.relativeAltitude
        }
        
        let relativeHeight = sensorData.relativeAltitude - (referenceAltitude ?? 0)
        
#if !os(macOS)
        let calibrationPoint = SensorCalibrationPoint(
            name: name,
            location: location.coordinate,
            altitude: location.altitude,
            relativeHeight: relativeHeight,
            magneticHeading: sensorData.magneticHeading,
            trueHeading: sensorData.trueHeading,
            accelerometerData: nil, // Can be added if needed
            gyroscopeData: nil,
            magnetometerData: nil,
            signalStrength: signalStrength,
            timestamp: Date(),
            distanceFromPrevious: distanceFromPrevious,
            stepCount: sensorData.stepCount
        )
#else
        let calibrationPoint = SensorCalibrationPoint(
            name: name,
            location: location.coordinate,
            altitude: location.altitude,
            relativeHeight: relativeHeight,
            magneticHeading: sensorData.magneticHeading,
            trueHeading: sensorData.trueHeading,
            accelerometerData: nil,
            gyroscopeData: nil,
            magnetometerData: nil,
            signalStrength: signalStrength,
            timestamp: Date(),
            distanceFromPrevious: distanceFromPrevious,
            stepCount: 0
        )
#endif
        
        // Add to session
        currentSession?.points.append(calibrationPoint)
        
        // Set as reference point if it's the first one
        if session.points.count == 1 {
            currentSession?.referencePoint = calibrationPoint
        }
        
        currentPoint = calibrationPoint
        print("✅ Point captured successfully")
        return true
    }
    
    private func calculateDistanceFromPrevious(location: CLLocation) -> Double {
        guard let session = currentSession,
              let lastPoint = session.points.last else {
            return 0.0
        }
        
        let lastLocation = CLLocation(
            latitude: lastPoint.location.latitude,
            longitude: lastPoint.location.longitude
        )
        
        return location.distance(from: lastLocation)
    }
    
    private func simulateSignalStrength(at coordinate: CLLocationCoordinate2D) -> Double {
        // This would normally measure actual WiFi signal strength
        // For demo purposes, we'll simulate based on distance from a central point
        let routerLocation = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let distance = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            .distance(from: CLLocation(latitude: routerLocation.latitude, longitude: routerLocation.longitude))
        
        // Simulate signal degradation with distance
        let maxDistance = 50.0 // meters
        let signalStrength = max(0.1, 1.0 - (distance / maxDistance))
        return min(1.0, signalStrength + Double.random(in: -0.1...0.1))
    }
    
    // MARK: - WiFi Optimization Analysis
    func analyzeOptimalPlacement() -> WiFiOptimizationResult? {
        guard let session = currentSession,
              session.points.count >= 3 else {
            print("❌ Need at least 3 calibration points for analysis")
            return nil
        }
        
        let points = session.points
        
        // Find optimal router location (center of mass weighted by desired coverage)
        let optimalLocation = findOptimalRouterLocation(points: points)
        
        // Find weak spots that need extenders
        let weakSpots = points.filter { $0.signalStrength < 0.4 }
        let extenderRecommendations = generateExtenderRecommendations(for: weakSpots, points: points)
        
        // Coverage analysis
        let coverage = analyzeCoverage(points: points)
        
        // Signal prediction map
        let signalMap = generateSignalPrediction(points: points, routerLocation: optimalLocation)
        
        return WiFiOptimizationResult(
            optimalRouterLocation: optimalLocation,
            recommendedExtenders: extenderRecommendations,
            coverageAnalysis: coverage,
            signalPrediction: signalMap
        )
    }
    
    private func findOptimalRouterLocation(points: [SensorCalibrationPoint]) -> SensorCalibrationPoint {
        // Find the point with best overall coverage potential
        var bestPoint = points[0]
        var bestScore = 0.0
        
        for point in points {
            let score = calculateLocationScore(point: point, allPoints: points)
            if score > bestScore {
                bestScore = score
                bestPoint = point
            }
        }
        
        return bestPoint
    }
    
    private func calculateLocationScore(point: SensorCalibrationPoint, allPoints: [SensorCalibrationPoint]) -> Double {
        // Score based on centrality and height
        let centralityScore = calculateCentralityScore(point: point, allPoints: allPoints)
        let heightScore = calculateHeightScore(point: point, allPoints: allPoints)
        let signalScore = point.signalStrength
        
        return (centralityScore * 0.4) + (heightScore * 0.3) + (signalScore * 0.3)
    }
    
    private func calculateCentralityScore(point: SensorCalibrationPoint, allPoints: [SensorCalibrationPoint]) -> Double {
        let distances = allPoints.map { otherPoint in
            CLLocation(latitude: point.location.latitude, longitude: point.location.longitude)
                .distance(from: CLLocation(latitude: otherPoint.location.latitude, longitude: otherPoint.location.longitude))
        }
        
        let avgDistance = distances.reduce(0, +) / Double(distances.count)
        let maxDistance = distances.max() ?? 1.0
        
        // Lower average distance = more central = better score
        return 1.0 - (avgDistance / maxDistance)
    }
    
    private func calculateHeightScore(point: SensorCalibrationPoint, allPoints: [SensorCalibrationPoint]) -> Double {
        let heights = allPoints.map { $0.relativeHeight }
        let avgHeight = heights.reduce(0, +) / Double(heights.count)
        
        // Prefer slightly above average height
        let idealHeight = avgHeight + 0.5 // 50cm above average
        let heightDifference = abs(point.relativeHeight - idealHeight)
        
        return max(0.0, 1.0 - (heightDifference / 3.0)) // Penalize if more than 3m different
    }
    
    private func generateExtenderRecommendations(for weakSpots: [SensorCalibrationPoint], points: [SensorCalibrationPoint]) -> [ExtenderRecommendation] {
        var recommendations: [ExtenderRecommendation] = []
        
        for weakSpot in weakSpots {
            let nearestStrongPoint = points
                .filter { $0.signalStrength > 0.7 }
                .min { point1, point2 in
                    let distance1 = CLLocation(latitude: weakSpot.location.latitude, longitude: weakSpot.location.longitude)
                        .distance(from: CLLocation(latitude: point1.location.latitude, longitude: point1.location.longitude))
                    let distance2 = CLLocation(latitude: weakSpot.location.latitude, longitude: weakSpot.location.longitude)
                        .distance(from: CLLocation(latitude: point2.location.latitude, longitude: point2.location.longitude))
                    return distance1 < distance2
                }
            
            if let strongPoint = nearestStrongPoint {
                let improvement = (0.8 - weakSpot.signalStrength) // Expected improvement
                
                let recommendation = ExtenderRecommendation(
                    location: weakSpot.name,
                    floor: 1, // Default floor
                    reason: "Weak signal (\(Int(weakSpot.signalStrength * 100))%) detected at \(weakSpot.name)",
                    type: improvement > 0.4 ? .roomExtender : .hallwayExtender
                )
                
                recommendations.append(recommendation)
            }
        }
        
        return recommendations
    }
    
    private func analyzeCoverage(points: [SensorCalibrationPoint]) -> CoverageAnalysis {
        let weakSpots = points.filter { $0.signalStrength < 0.5 }
        let strongSpots = points.filter { $0.signalStrength >= 0.7 }
        
        let coveragePercentage = Double(strongSpots.count) / Double(points.count) * 100
        
        return CoverageAnalysis(
            totalRooms: points.count,
            wellCoveredRooms: strongSpots.count,
            weakAreas: weakSpots.count,
            coveragePercentage: coveragePercentage
        )
    }
    
    private func estimateArea(points: [SensorCalibrationPoint]) -> Double {
        // Simple area estimation using distance between points
        if points.count < 3 { return 0.0 }
        
        let distances = points.enumerated().compactMap { index, point in
            let nextIndex = (index + 1) % points.count
            let nextPoint = points[nextIndex]
            
            return CLLocation(latitude: point.location.latitude, longitude: point.location.longitude)
                .distance(from: CLLocation(latitude: nextPoint.location.latitude, longitude: nextPoint.location.longitude))
        }
        
        let perimeter = distances.reduce(0, +)
        // Rough area estimation (assuming roughly rectangular space)
        return (perimeter / 4) * (perimeter / 4)
    }
    
    private func generateSignalPrediction(points: [SensorCalibrationPoint], routerLocation: SensorCalibrationPoint) -> SignalPredictionMap {
        // Create a prediction map based on calibrated points
        var predictions: [String: Double] = [:]
        
        // For demo purposes, predict signal strength based on distance from router
        for point in points {
            let distance = CLLocation(latitude: routerLocation.location.latitude, longitude: routerLocation.location.longitude)
                .distance(from: CLLocation(latitude: point.location.latitude, longitude: point.location.longitude))
            
            // Simple distance-based prediction model
            let predictedSignal = max(0.1, 1.0 - (distance / 50.0))
            let key = "\(point.location.latitude),\(point.location.longitude)"
            predictions[key] = predictedSignal
        }
        
        return SignalPredictionMap(predictions: predictions, resolution: 1.0)
    }
}

// MARK: - Real-time Sensor Data
struct SensorRealtimeData {
    var relativeAltitude: Double = 0.0
    var pressure: Double = 0.0
    #if !os(macOS)
    var acceleration: CMAcceleration = CMAcceleration()
    var rotation: CMRotationRate = CMRotationRate()
    var magneticField: CMCalibratedMagneticField = CMCalibratedMagneticField()
    var attitude: CMAttitude?
    #endif
    var magneticHeading: Double = 0.0
    var trueHeading: Double = 0.0
    var stepCount: Int = 0
}

// MARK: - Location Manager Delegate
extension SensorCalibrationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        sensorData.magneticHeading = newHeading.magneticHeading
        sensorData.trueHeading = newHeading.trueHeading
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.locationAuthorizationStatus = status
            self.locationError = nil
        }
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ Location authorization granted")
            if isCalibrating {
                locationManager.startUpdatingLocation()
                locationManager.startUpdatingHeading()
            }
        case .denied:
            DispatchQueue.main.async {
                self.locationError = "Location access is required for WiFi calibration. Please enable location services in Settings."
            }
            print("❌ Location access denied")
        case .restricted:
            DispatchQueue.main.async {
                self.locationError = "Location access is restricted on this device."
            }
            print("❌ Location access restricted")
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            print("⚠️ Unknown location authorization status")
        }
    }
}

// MARK: - CLAuthorizationStatus Extension
extension CLAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined:
            return "not determined"
        case .restricted:
            return "restricted"
        case .denied:
            return "denied"
        case .authorizedAlways:
            return "authorized always"
        case .authorizedWhenInUse:
            return "authorized when in use"
        @unknown default:
            return "unknown"
        }
    }
}
