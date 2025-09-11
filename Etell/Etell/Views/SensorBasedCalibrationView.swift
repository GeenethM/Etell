import SwiftUI
import MapKit
import CoreLocation

struct SensorBasedCalibrationView: View {
    @StateObject private var sensorService = SensorCalibrationService()
    @State private var currentLocationName = ""
    @State private var showingLocationInput = false
    @State private var showingResults = false
    @State private var calibrationInstructions = true
    @State private var totalLocationsToCalibrate = 5
    @State private var showingOptimizationResults = false
    @State private var optimizationResults: WiFiOptimizationResult?
    @State private var showingRoom3DView = false
    
    let setupData: CalibrationSetupData
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.white]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        if calibrationInstructions {
                            InstructionsView(
                                setupData: setupData,
                                sensorService: sensorService,
                                onStartCalibration: startCalibration
                            )
                        } else {
                            CalibrationActiveView(
                                sensorService: sensorService,
                                currentLocationName: $currentLocationName,
                                showingLocationInput: $showingLocationInput,
                                totalLocations: totalLocationsToCalibrate,
                                onComplete: completeCalibration
                            )
                        }
                    }
                    .padding(.bottom, 20) // Extra bottom padding for scrolling
                }
            }
            .navigationTitle("WiFi Calibration")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        sensorService.endCurrentSession()
                        dismiss()
                    }
                }
                
                if !calibrationInstructions && (sensorService.currentSession?.points.count ?? 0) >= 3 {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            Button(action: {
                                showingRoom3DView = true
                            }) {
                                Image(systemName: "cube")
                            }
                            
                            Button("Analyze") {
                                analyzeResults()
                            }
                            .fontWeight(.semibold)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingLocationInput) {
                LocationInputSheet(
                    locationName: $currentLocationName,
                    onSave: captureCurrentLocation
                )
            }
            .sheet(isPresented: $showingOptimizationResults) {
                if let results = optimizationResults {
                    WiFiOptimizationResultsView(
                        results: results,
                        calibrationPoints: sensorService.currentSession?.points ?? []
                    )
                }
            }
            .sheet(isPresented: $showingRoom3DView) {
                Room3DVisualizationView(
                    calibratedLocations: sensorService.getCalibratedLocations(),
                    layoutData: nil
                )
            }
        }
    }
    
    private func startCalibration() {
        calibrationInstructions = false
        sensorService.startNewSession(setupData: setupData)
    }
    
    private func captureCurrentLocation() {
        let success = sensorService.captureCalibrationPoint(name: currentLocationName)
        if success {
            currentLocationName = ""
            
            // Provide haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
    }
    
    private func completeCalibration() {
        print("🔄 Complete Calibration button pressed")
        
        // End the current session
        sensorService.endCurrentSession()
        
        // Analyze results on main thread with error handling
        analyzeResults()
    }
    
    private func analyzeResults() {
        DispatchQueue.main.async {
            print("🔍 Starting analysis...")
            
            do {
                if let results = self.sensorService.analyzeOptimalPlacement() {
                    print("✅ Analysis successful, showing results")
                    self.optimizationResults = results
                    self.showingOptimizationResults = true
                } else {
                    print("❌ Failed to generate optimization results - need at least 3 calibration points")
                }
            } catch {
                print("💥 Error during analysis: \(error)")
            }
        }
    }
}

// MARK: - Instructions View
struct InstructionsView: View {
    let setupData: CalibrationSetupData
    @ObservedObject var sensorService: SensorCalibrationService
    let onStartCalibration: () -> Void
    
    private var locationPermissionStatus: String {
        switch sensorService.locationAuthorizationStatus {
        case .notDetermined:
            return "Not Requested"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorizedAlways:
            return "Authorized"
        case .authorizedWhenInUse:
            return "Authorized"
        @unknown default:
            return "Unknown"
        }
    }
    
    private var locationPermissionIcon: String {
        switch sensorService.locationAuthorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return "checkmark.circle.fill"
        case .denied, .restricted:
            return "xmark.circle.fill"
        case .notDetermined:
            return "questionmark.circle.fill"
        @unknown default:
            return "exclamationmark.circle.fill"
        }
    }
    
    private var locationPermissionColor: Color {
        switch sensorService.locationAuthorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return .green
        case .denied, .restricted:
            return .red
        case .notDetermined:
            return .orange
        @unknown default:
            return .gray
        }
    }
    
    private var locationPermissionBackgroundColor: Color {
        switch sensorService.locationAuthorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return Color.green.opacity(0.1)
        case .denied, .restricted:
            return Color.red.opacity(0.1)
        case .notDetermined:
            return Color.orange.opacity(0.1)
        @unknown default:
            return Color.gray.opacity(0.1)
        }
    }
    
    private var isCalibrationEnabled: Bool {
        sensorService.locationAuthorizationStatus == .authorizedWhenInUse || 
        sensorService.locationAuthorizationStatus == .authorizedAlways
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                VStack(spacing: 16) {
                    Image(systemName: "sensor.tag.radiowaves.forward")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Advanced WiFi Calibration")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Using iPhone sensors for precise measurements")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(alignment: .leading, spacing: 20) {
                    SensorFeatureRow(
                        icon: "barometer",
                        title: "Barometer/Altimeter",
                        description: "Measures height differences between locations"
                    )
                    
                    SensorFeatureRow(
                        icon: "gyroscope",
                        title: "Motion Sensors",
                        description: "Tracks movement and orientation changes"
                    )
                    
                    SensorFeatureRow(
                        icon: "location",
                        title: "GPS & Magnetometer",
                        description: "Precise positioning relative to signal towers"
                    )
                    
                    SensorFeatureRow(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "3D Visualization",
                        description: "Interactive 3D scatter plot analysis"
                    )
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .gray.opacity(0.1), radius: 10)
                
                VStack(spacing: 16) {
                    Text("Setup Configuration")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Label(setupData.environmentType?.rawValue ?? "Unknown", systemImage: setupData.environmentType?.icon ?? "house")
                        Spacer()
                        Label("\(setupData.numberOfFloors ?? 1) Floor\(setupData.numberOfFloors == 1 ? "" : "s")", systemImage: "building")
                        Spacer()
                        Label(setupData.hasHallways == true ? "Has Hallways" : "No Hallways", systemImage: "rectangle.split.3x1")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                
                // Location Permission Status
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: locationPermissionIcon)
                            .foregroundColor(locationPermissionColor)
                        Text("Location Permission")
                            .font(.headline)
                        Spacer()
                        Text(locationPermissionStatus)
                            .font(.caption)
                            .foregroundColor(locationPermissionColor)
                            .fontWeight(.medium)
                    }
                    
                    if sensorService.locationAuthorizationStatus != .authorizedWhenInUse && 
                       sensorService.locationAuthorizationStatus != .authorizedAlways {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Location access is required for:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("• Capturing precise calibration points")
                                Text("• Measuring distances between locations")
                                Text("• Creating accurate WiFi coverage maps")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                            
                            if sensorService.locationAuthorizationStatus == .denied {
                                Button("Open Settings") {
                                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(settingsUrl)
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding(.top, 4)
                            }
                        }
                    }
                    
                    if let error = sensorService.locationError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.top, 4)
                    }
                }
                .padding()
                .background(locationPermissionBackgroundColor)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(locationPermissionColor.opacity(0.3), lineWidth: 1)
                )
                
                Button(action: onStartCalibration) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Sensor Calibration")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isCalibrationEnabled ? Color.blue : Color.gray)
                    .cornerRadius(12)
                }
                .disabled(!isCalibrationEnabled)
                
                Spacer(minLength: 50)
            }
            .padding()
        }
    }
}

struct SensorFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Active Calibration View
struct CalibrationActiveView: View {
    @ObservedObject var sensorService: SensorCalibrationService
    @Binding var currentLocationName: String
    @Binding var showingLocationInput: Bool
    let totalLocations: Int
    let onComplete: () -> Void
    
    private var completedPoints: Int {
        sensorService.currentSession?.points.count ?? 0
    }
    
    private var progress: Double {
        Double(completedPoints) / Double(totalLocations)
    }
    
    private var canCaptureLocation: Bool {
        sensorService.locationAuthorizationStatus == .authorizedWhenInUse ||
        sensorService.locationAuthorizationStatus == .authorizedAlways
    }
    
    var body: some View {
        LazyVStack(spacing: 20) {
            // Progress Section
            VStack(spacing: 12) {
                HStack {
                    Text("Calibration Progress")
                        .font(.headline)
                    Spacer()
                    Text("\(completedPoints)/\(totalLocations)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: progress)
                    .scaleEffect(y: 2)
                    .tint(.blue)
                
                Text(completedPoints == 0 ? "Go to your first WiFi location" : 
                     completedPoints < totalLocations ? "Move to next WiFi location" : "All locations captured!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .gray.opacity(0.1), radius: 5)
            
            // Location Status Alert
            if sensorService.locationAuthorizationStatus != .authorizedWhenInUse &&
               sensorService.locationAuthorizationStatus != .authorizedAlways {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "location.slash")
                            .foregroundColor(.red)
                        Text("Location Access Required")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    
                    Text("Enable location services to capture calibration points")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if sensorService.locationAuthorizationStatus == .denied {
                        Button("Open Settings") {
                            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsUrl)
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
            }
            
            // Location Error Alert
            if let error = sensorService.locationError {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text("Location Error")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
            }
            
            // Real-time Sensor Data
            SensorDataDisplay(sensorData: sensorService.sensorData)
            
            // Calibrated Points List with improved layout
            if !(sensorService.currentSession?.points.isEmpty ?? true) {
                CalibratedPointsList(points: sensorService.currentSession?.points ?? [])
            }
            
            // Action Buttons - Fixed at bottom
            VStack(spacing: 12) {
                if completedPoints < totalLocations {
                    Button(action: {
                        showingLocationInput = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Capture This Location")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canCaptureLocation ? Color.blue : Color.gray)
                        .cornerRadius(12)
                    }
                    .disabled(!canCaptureLocation)
                }
                
                if completedPoints >= 3 {
                    Button(action: onComplete) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Complete Calibration")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.top, 10)
        }
        .padding(.horizontal)
    }
}

// MARK: - Sensor Data Display
struct SensorDataDisplay: View {
    let sensorData: SensorRealtimeData
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Live Sensor Readings")
                .font(.headline)
            
            // WiFi Network Info
            if !sensorData.wifiSSID.isEmpty {
                HStack {
                    Image(systemName: "wifi")
                        .foregroundColor(.blue)
                    Text("Connected to: \(sensorData.wifiSSID)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                SensorReadingCard(
                    icon: "barometer",
                    title: "Altitude",
                    value: String(format: "%.2f m", sensorData.relativeAltitude),
                    color: .blue
                )
                
                SensorReadingCard(
                    icon: "location",
                    title: "Heading",
                    value: String(format: "%.0f°", sensorData.magneticHeading),
                    color: .green
                )
                
                SensorReadingCard(
                    icon: "speedometer",
                    title: "Pressure",
                    value: String(format: "%.1f kPa", sensorData.pressure),
                    color: .orange
                )
                
                SensorReadingCard(
                    icon: "figure.walk",
                    title: "Steps",
                    value: "\(sensorData.stepCount)",
                    color: .purple
                )
                
                SensorReadingCard(
                    icon: "wifi",
                    title: "WiFi Signal",
                    value: String(format: "%.0f%%", sensorData.wifiSignalStrength * 100),
                    color: wifiSignalColor(sensorData.wifiSignalStrength)
                )
                
                SensorReadingCard(
                    icon: "antenna.radiowaves.left.and.right",
                    title: "RSSI",
                    value: "\(sensorData.wifiRSSI) dBm",
                    color: .indigo
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.1), radius: 5)
    }
    
    private func wifiSignalColor(_ strength: Double) -> Color {
        switch strength {
        case 0.8...1.0:
            return .green
        case 0.6..<0.8:
            return .yellow
        case 0.4..<0.6:
            return .orange
        case 0.2..<0.4:
            return .red
        default:
            return .gray
        }
    }
}

struct SensorReadingCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Location Input Sheet
struct LocationInputSheet: View {
    @Binding var locationName: String
    let onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Name This Location")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Give this WiFi location a descriptive name")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Location Name")
                        .font(.headline)
                    
                    TextField("e.g. Living Room, Kitchen, Bedroom", text: $locationName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .submitLabel(.done)
                        .onSubmit {
                            if !locationName.isEmpty {
                                saveLocation()
                            }
                        }
                    
                    Text("Choose a name that describes where you want WiFi coverage")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Quick selection buttons
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Options")
                        .font(.headline)
                    
                    let commonLocations = ["Living Room", "Kitchen", "Bedroom", "Office", "Bathroom", "Hallway"]
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        ForEach(commonLocations, id: \.self) { location in
                            Button(action: {
                                locationName = location
                            }) {
                                Text(location)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
                Spacer()
                
                Button(action: saveLocation) {
                    Text("Capture Location")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(locationName.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(12)
                }
                .disabled(locationName.isEmpty)
            }
            .padding()
            .navigationTitle("Add Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveLocation() {
        onSave()
        dismiss()
    }
}

// MARK: - Calibrated Points List
struct CalibratedPointsList: View {
    let points: [SensorCalibrationPoint]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Calibrated Locations")
                    .font(.headline)
                Spacer()
                Text("(\(points.count))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(points, id: \.id) { point in
                    CalibratedPointRow(point: point)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.1), radius: 5)
    }
}

struct CalibratedPointRow: View {
    let point: SensorCalibrationPoint
    
    var body: some View {
        VStack(spacing: 8) {
            // Top row with name and status
            HStack(spacing: 12) {
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(point.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text("Captured at \(DateFormatter.timeFormatter.string(from: point.timestamp))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Signal indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(signalColor(point.signalStrength))
                        .frame(width: 10, height: 10)
                    Text("\(Int(point.signalStrength * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Bottom row with metrics
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.circle")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text("\(String(format: "%.1f m", point.relativeHeight))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "wifi")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("Signal Strength")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.leading, 32) // Align with text above
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
    
    private func signalColor(_ strength: Double) -> Color {
        if strength >= 0.7 { return .green }
        else if strength >= 0.4 { return .orange }
        else { return .red }
    }
}

// MARK: - Extensions
extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    SensorBasedCalibrationView(setupData: CalibrationSetupData(
        environmentType: .house,
        numberOfFloors: 2,
        hasHallways: true
    ))
}
