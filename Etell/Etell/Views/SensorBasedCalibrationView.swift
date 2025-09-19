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
    @State private var currentFloor = 1
    @State private var showingOptimizationResults = false
    @State private var optimizationResults: WiFiOptimizationResult?
    @State private var showingRoom3DView = false
    
    let setupData: CalibrationSetupData
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
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
                            
                            // Cellular Tower Information
                            if !sensorService.nearbyTowers.isEmpty {
                                CellularTowerOverlayView(towers: sensorService.nearbyTowers)
                            }
                        }
                    }
                    .padding(.bottom, 34)
                }
            }
            .navigationTitle("WiFi Calibration")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        sensorService.endCurrentSession()
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
                
                if !calibrationInstructions && (sensorService.currentSession?.points.count ?? 0) >= 3 {
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: 16) {
                            Button(action: {
                                showingRoom3DView = true
                            }) {
                                Image(systemName: "cube")
                                    .font(.title3)
                                    .foregroundStyle(.blue)
                            }
                            
                            Button("Analyze") {
                                analyzeResults()
                            }
                            .fontWeight(.medium)
                            .foregroundStyle(.blue)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingLocationInput) {
                LocationInputSheet(
                    locationName: $currentLocationName,
                    setupData: setupData,
                    currentFloor: currentFloor,
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
                    layoutData: nil,
                    environmentType: setupData.environmentType
                )
            }
        }
    }
    
    private func startCalibration() {
        calibrationInstructions = false
        sensorService.startNewSession()
    }
    
    private func captureCurrentLocation() {
        let success = sensorService.captureCalibrationPoint(name: currentLocationName)
        if success {
            currentLocationName = ""
            
            // Check if we should advance to next floor
            advanceFloorIfNeeded()
            
            // Provide haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
    }
    
    private func advanceFloorIfNeeded() {
        guard let totalFloors = setupData.numberOfFloors,
              totalFloors > 1,
              let currentSession = sensorService.currentSession else { return }
        
        let pointsPerFloor = max(1, totalLocationsToCalibrate / totalFloors)
        let currentFloorPoints = currentSession.points.filter { point in
            point.name.contains("Floor \(currentFloor)") || 
            (currentFloor == 1 && !point.name.contains("Floor"))
        }
        
        // Advance to next floor when enough points are captured for current floor
        if currentFloorPoints.count >= pointsPerFloor && currentFloor < totalFloors {
            currentFloor += 1
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
            VStack(spacing: 32) {
                VStack(spacing: 20) {
                    Image(systemName: "sensor.tag.radiowaves.forward")
                        .font(.system(size: 64))
                        .foregroundStyle(.blue.gradient)
                        .symbolRenderingMode(.hierarchical)
                    
                    VStack(spacing: 8) {
                        Text("Advanced WiFi Calibration")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                        
                        Text("Using iPhone sensors for precise measurements")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
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
                .background(Color(UIColor.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
                
                VStack(spacing: 16) {
                    Text("Setup Configuration")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    HStack {
                        Label(setupData.environmentType?.rawValue ?? "Unknown", systemImage: setupData.environmentType?.icon ?? "house")
                        Spacer()
                        Label("\(setupData.numberOfFloors ?? 1) Floor\(setupData.numberOfFloors == 1 ? "" : "s")", systemImage: "building")
                        Spacer()
                        Label(setupData.hasHallways == true ? "Has Hallways" : "No Hallways", systemImage: "rectangle.split.3x1")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                
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
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(locationPermissionColor.opacity(0.3), lineWidth: 1)
                )
                
                Button(action: onStartCalibration) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Start Sensor Calibration")
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(isCalibrationEnabled ? Color.blue : Color(UIColor.systemGray4))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
        LazyVStack(spacing: 24) {
            // Progress Section
            VStack(spacing: 16) {
                HStack {
                    Text("Calibration Progress")
                        .font(.headline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(completedPoints)/\(totalLocations)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fontWeight(.medium)
                }
                
                ProgressView(value: progress)
                    .scaleEffect(y: 3)
                    .tint(.blue)
                    .background(Color(UIColor.systemGray5))
                    .clipShape(Capsule())
                
                Text(completedPoints == 0 ? "Go to your first WiFi location" : 
                     completedPoints < totalLocations ? "Move to next WiFi location" : "All locations captured!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            
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
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                            Text("Capture This Location")
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(canCaptureLocation ? Color.blue : Color(UIColor.systemGray4))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .disabled(!canCaptureLocation)
                }
                
                if completedPoints >= 3 {
                    Button(action: onComplete) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Complete Calibration")
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.blue, lineWidth: 1.5)
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
        VStack(spacing: 20) {
            Text("Live Sensor Readings")
                .font(.headline)
                .fontWeight(.medium)
            
            // WiFi Network Info
            if !sensorData.wifiSSID.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "wifi")
                        .foregroundStyle(.blue)
                        .symbolRenderingMode(.hierarchical)
                    Text("Connected to: \(sensorData.wifiSSID)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.blue.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 16) {
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
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
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
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color.gradient)
                .symbolRenderingMode(.hierarchical)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fontWeight(.medium)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .padding()
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Location Input Sheet
struct LocationInputSheet: View {
    @Binding var locationName: String
    let setupData: CalibrationSetupData
    let currentFloor: Int
    let onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedFloor: Int
    
    init(locationName: Binding<String>, setupData: CalibrationSetupData, currentFloor: Int, onSave: @escaping () -> Void) {
        self._locationName = locationName
        self.setupData = setupData
        self.currentFloor = currentFloor
        self.onSave = onSave
        self._selectedFloor = State(initialValue: currentFloor)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                VStack(spacing: 20) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 56))
                        .foregroundStyle(.blue.gradient)
                        .symbolRenderingMode(.hierarchical)
                    
                    VStack(spacing: 8) {
                        Text("Name This Location")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 6) {
                            Text("Give this WiFi location a descriptive name")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            
                            // Floor information
                            if let totalFloors = setupData.numberOfFloors, totalFloors > 1 {
                                HStack(spacing: 8) {
                                    Image(systemName: "building")
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                    
                                    Text("Currently calibrating: Floor \(currentFloor) of \(totalFloors)")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.blue)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.blue.opacity(0.08))
                                .clipShape(Capsule())
                            }
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Location Name")
                        .font(.headline)
                    
                    TextField(floorBasedPlaceholder, text: $locationName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .submitLabel(.done)
                        .onSubmit {
                            if !locationName.isEmpty {
                                saveLocation()
                            }
                        }
                    
                    Text(floorBasedHelperText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Floor Selection (only show if multi-floor building)
                if let totalFloors = setupData.numberOfFloors, totalFloors > 1 {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "stairs")
                                .font(.headline)
                                .foregroundColor(.blue)
                            
                            Text("Select Floor")
                                .font(.headline)
                        }
                        
                        HStack(spacing: 12) {
                            ForEach(1...totalFloors, id: \.self) { floor in
                                FloorSelectionButton(
                                    floor: floor,
                                    isSelected: selectedFloor == floor,
                                    action: { selectedFloor = floor }
                                )
                            }
                            Spacer()
                        }
                        
                        Text("Choose which floor this room is located on")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Quick selection buttons
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Options")
                        .font(.headline)
                    
                    let commonLocations = floorBasedQuickOptions
                    
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
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(locationName.isEmpty ? Color(UIColor.systemGray4) : Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .disabled(locationName.isEmpty)
            }
            .padding()
            .navigationTitle("Add Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // Computed properties for floor-based content
    private var floorBasedPlaceholder: String {
        if let totalFloors = setupData.numberOfFloors, totalFloors > 1 {
            return "e.g. Living Room, Kitchen Floor \(selectedFloor)"
        } else {
            return "e.g. Living Room, Kitchen, Bedroom"
        }
    }
    
    private var floorBasedHelperText: String {
        if let totalFloors = setupData.numberOfFloors, totalFloors > 1 {
            return "Name the room/area on Floor \(selectedFloor) where you want WiFi coverage"
        } else {
            return "Choose a name that describes where you want WiFi coverage"
        }
    }
    
    private var floorBasedQuickOptions: [String] {
        let baseLocations: [String]
        
        // Different suggestions based on environment type
        switch setupData.environmentType {
        case .office:
            baseLocations = ["Conference Room", "Office", "Reception", "Break Room", "Storage", "Hallway"]
        case .house, .apartment, .none:
            baseLocations = ["Living Room", "Kitchen", "Bedroom", "Office", "Bathroom", "Hallway"]
        }
        
        // Add floor suffix if multi-floor building
        if let totalFloors = setupData.numberOfFloors, totalFloors > 1 {
            return baseLocations.map { "\($0) - Floor \(selectedFloor)" }
        } else {
            return baseLocations
        }
    }
    
    private func saveLocation() {
        // Update location name to include floor if multi-floor building and not already specified
        if let totalFloors = setupData.numberOfFloors, 
           totalFloors > 1, 
           !locationName.contains("Floor") {
            locationName = "\(locationName) - Floor \(selectedFloor)"
        }
        
        onSave()
        dismiss()
    }
}

// MARK: - Floor Selection Button
struct FloorSelectionButton: View {
    let floor: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(floor)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text("Floor")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .frame(width: 60, height: 60)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.blue.gradient)
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.clear)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.clear : Color(UIColor.quaternaryLabel), lineWidth: 1.5)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
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

// MARK: - Cellular Tower Overlay View
struct CellularTowerOverlayView: View {
    let towers: [CellularTower]
    @State private var selectedTower: CellularTower?
    @State private var showingTowerDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundColor(.blue)
                Text("Nearby Cellular Towers")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: {
                    showingTowerDetails = true
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                }
            }
            
            if let nearestTower = towers.first {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(nearestTower.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("\(nearestTower.provider) • \(nearestTower.technology)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            HStack {
                                Circle()
                                    .fill(signalColor(for: nearestTower.signalStrength))
                                    .frame(width: 8, height: 8)
                                Text("\(Int(nearestTower.signalStrength * 100))%")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            Text("Signal")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Distance:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(nearestTower.range))m range")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .onTapGesture {
                    selectedTower = nearestTower
                    showingTowerDetails = true
                }
            }
            
            Text("\(towers.count) towers detected")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .sheet(isPresented: $showingTowerDetails) {
            CellularTowerDetailsView(towers: towers, selectedTower: selectedTower)
        }
    }
    
    private func signalColor(for strength: Double) -> Color {
        if strength > 0.7 {
            return .green
        } else if strength > 0.4 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Cellular Tower Details View
struct CellularTowerDetailsView: View {
    let towers: [CellularTower]
    let selectedTower: CellularTower?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if let selected = selectedTower {
                        TowerDetailCard(tower: selected, isSelected: true)
                    }
                    
                    ForEach(towers.filter { $0.name != selectedTower?.name }, id: \.name) { tower in
                        TowerDetailCard(tower: tower, isSelected: false)
                    }
                }
                .padding()
            }
            .navigationTitle("Cellular Towers")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TowerDetailCard: View {
    let tower: CellularTower
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(tower.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text(tower.address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Provider")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(tower.provider)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                VStack(alignment: .leading) {
                    Text("Technology")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(tower.technology)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                VStack(alignment: .leading) {
                    Text("Signal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack {
                        Circle()
                            .fill(signalColor(for: tower.signalStrength))
                            .frame(width: 8, height: 8)
                        Text("\(Int(tower.signalStrength * 100))%")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                
                Spacer()
            }
            
            HStack {
                Text("Range: \(Int(tower.range))m")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Lat: \(String(format: "%.4f", tower.coordinate.latitude)), Lng: \(String(format: "%.4f", tower.coordinate.longitude))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
    
    private func signalColor(for strength: Double) -> Color {
        if strength > 0.7 {
            return .green
        } else if strength > 0.4 {
            return .orange
        } else {
            return .red
        }
    }
}

#Preview {
    SensorBasedCalibrationView(setupData: CalibrationSetupData(
        environmentType: .house,
        numberOfFloors: 2,
        hasHallways: true
    ))
}
