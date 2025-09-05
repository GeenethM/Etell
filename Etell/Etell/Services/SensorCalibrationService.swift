import Foundation
import CoreLocation
import Network
import SystemConfiguration.CaptiveNetwork
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
    
    // WiFi monitoring
    private var wifiMonitor: NWPathMonitor?
    private let wifiQueue = DispatchQueue(label: "WiFiMonitor")
    private var wifiTimer: Timer?
    
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
        
        // Start barometer/altimeter for height measurement
        setupAltimeter()
        
        // Start WiFi signal strength monitoring
        startWiFiMonitoring()
        
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
        stopWiFiMonitoring()
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
        
        // Get current signal strength from real WiFi monitoring
        let signalStrength = sensorData.wifiSignalStrength
        
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
    
    // MARK: - WiFi Signal Strength Monitoring
    private func startWiFiMonitoring() {
        // Start network path monitoring
        wifiMonitor = NWPathMonitor(requiredInterfaceType: .wifi)
        wifiMonitor?.start(queue: wifiQueue)
        
        wifiMonitor?.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.updateWiFiStatus(path: path)
            }
        }
        
        // Start periodic WiFi signal strength updates
        wifiTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateWiFiSignalStrength()
        }
    }
    
    private func stopWiFiMonitoring() {
        wifiMonitor?.cancel()
        wifiMonitor = nil
        wifiTimer?.invalidate()
        wifiTimer = nil
    }
    
    private func updateWiFiStatus(path: NWPath) {
        if path.status == .satisfied && path.usesInterfaceType(.wifi) {
            // WiFi is available
            updateWiFiSignalStrength()
        } else {
            // No WiFi connection
            sensorData.wifiSignalStrength = 0.0
            sensorData.wifiRSSI = -100
            sensorData.wifiSSID = ""
        }
    }
    
    private func updateWiFiSignalStrength() {
        // Get current WiFi information
        if let wifiInfo = getCurrentWiFiInfo() {
            sensorData.wifiSSID = wifiInfo.ssid
            sensorData.wifiRSSI = wifiInfo.rssi
            
            // Convert RSSI to normalized signal strength (0.0 to 1.0)
            // RSSI typically ranges from -30 (excellent) to -90 (poor)
            let clampedRSSI = max(-90, min(-30, wifiInfo.rssi))
            sensorData.wifiSignalStrength = Double(clampedRSSI + 90) / 60.0
        } else {
            // Fallback: simulate signal strength for demo purposes
            sensorData.wifiSignalStrength = simulateSignalStrengthFallback()
            let signalRange = 60 * (1.0 - sensorData.wifiSignalStrength)
            sensorData.wifiRSSI = Int(-30 - signalRange)
            sensorData.wifiSSID = "WiFi Network"
        }
    }
    
    private func getCurrentWiFiInfo() -> (ssid: String, rssi: Int)? {
        #if targetEnvironment(simulator)
        // Simulator doesn't have real WiFi access
        return nil
        #else
        // Get WiFi SSID using CNCopyCurrentNetworkInfo (requires specific entitlements)
        guard let interfaces = CNCopySupportedInterfaces() as? [String] else { return nil }
        
        for interface in interfaces {
            if let interfaceInfo = CNCopyCurrentNetworkInfo(interface as CFString) as? [String: Any],
               let ssid = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String {
                
                // Note: Getting actual RSSI requires private APIs or additional permissions
                // For now, we'll estimate based on network reachability
                let estimatedRSSI = estimateRSSI()
                return (ssid: ssid, rssi: estimatedRSSI)
            }
        }
        return nil
        #endif
    }
    
    private func estimateRSSI() -> Int {
        // This is a simplified estimation since iOS doesn't provide direct RSSI access
        // In a real implementation, you might use Core Location's beacons or other methods
        return Int.random(in: -70 ... -40) // Simulate reasonable WiFi signal strength
    }
    
    private func simulateSignalStrengthFallback() -> Double {
        // Fallback simulation for when real WiFi data isn't available
        return Double.random(in: 0.3...0.9)
    }
    
    // MARK: - Data Conversion
    func getCalibratedLocations() -> [CalibratedLocation] {
        guard let session = currentSession else { return [] }
        
        return session.points.map { point in
            // Determine location type based on name patterns
            let locationType: LocationType
            let lowercaseName = point.name.lowercased()
            if lowercaseName.contains("hallway") || lowercaseName.contains("corridor") || lowercaseName.contains("hall") {
                locationType = .hallway
            } else if lowercaseName.contains("stair") || lowercaseName.contains("step") {
                locationType = .staircase
            } else {
                locationType = .room
            }
            
            // Determine floor based on height (simple estimation)
            let floor = max(1, Int((point.relativeHeight / 3.0).rounded()) + 1)
            
            // Generate basic recommendations
            let recommendations = generateBasicRecommendations(for: point)
            
            return CalibratedLocation(
                name: point.name,
                type: locationType,
                floor: floor,
                signalStrength: point.signalStrength,
                coordinates: point.location,
                timestamp: point.timestamp,
                recommendations: recommendations
            )
        }
    }
    
    private func generateBasicRecommendations(for point: SensorCalibrationPoint) -> [String] {
        var recommendations: [String] = []
        
        if point.signalStrength < 0.3 {
            recommendations.append("Consider WiFi extender placement")
            recommendations.append("Check for interference sources")
        } else if point.signalStrength < 0.5 {
            recommendations.append("Signal could be improved")
            recommendations.append("Consider router repositioning")
        } else if point.signalStrength > 0.8 {
            recommendations.append("Excellent signal strength")
            recommendations.append("Suitable for high-bandwidth devices")
        }
        
        return recommendations
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
    var wifiSignalStrength: Double = 0.0 // RSSI-based signal strength (0.0 to 1.0)
    var wifiRSSI: Int = -100 // Raw RSSI value in dBm
    var wifiSSID: String = "" // Current WiFi network name
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
