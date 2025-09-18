import SwiftUI
import SceneKit
import MapKit
import CoreLocation

// MARK: - UIColor Extension
extension UIColor {
    static let gold = UIColor(red: 1.0, green: 0.843, blue: 0.0, alpha: 1.0)
}

struct WiFiOptimizationResultsView: View {
    let results: WiFiOptimizationResult
    let calibrationPoints: [SensorCalibrationPoint]
    @Environment(\.dismiss) var dismiss
    @State private var showingRecommendations = true
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Selector
                Picker("View", selection: $selectedTab) {
                    Text("Recommendations").tag(0)
                    Text("3D Analysis").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if selectedTab == 0 {
                    // Recommendations View
                    ScrollView {
                        VStack(spacing: 20) {
                            // Overall Coverage Summary
                            CoverageSummaryCard(results: results, points: calibrationPoints)
                            
                            // Optimal Router Location
                            OptimalRouterCard(results: results)
                            
                            // Extender Recommendations
                            ExtenderRecommendationsCard(results: results)
                            
                            // Detailed Location Analysis
                            LocationAnalysisCard(points: calibrationPoints)
                            
                            // Performance Insights
                            PerformanceInsightsCard(results: results, points: calibrationPoints)
                        }
                        .padding()
                    }
                } else {
                    // 3D Visualization View
                    let calibratedLocations = calibrationPoints.map { point in
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
                    
                    Room3DVisualizationView(
                        calibratedLocations: calibratedLocations,
                        layoutData: nil,
                        environmentType: nil
                    )
                }
            }
            .navigationTitle("WiFi Optimization")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Share") {
                        shareResults()
                    }
                }
            }
        }
    }
    
    private func shareResults() {
        // TODO: Implement sharing functionality
        print("Sharing WiFi optimization results")
    }
}

// MARK: - Coverage Summary Card
struct CoverageSummaryCard: View {
    let results: WiFiOptimizationResult
    let points: [SensorCalibrationPoint]
    
    private var averageSignalStrength: Double {
        points.isEmpty ? 0.0 : points.map { $0.signalStrength }.reduce(0, +) / Double(points.count)
    }
    
    private var coverageQuality: String {
        let avg = averageSignalStrength
        if avg >= 0.8 { return "Excellent" }
        else if avg >= 0.6 { return "Good" }
        else if avg >= 0.4 { return "Fair" }
        else { return "Poor" }
    }
    
    private var coverageColor: Color {
        let avg = averageSignalStrength
        if avg >= 0.8 { return .green }
        else if avg >= 0.6 { return .blue }
        else if avg >= 0.4 { return .orange }
        else { return .red }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "wifi.circle.fill")
                    .foregroundColor(coverageColor)
                    .font(.title2)
                Text("WiFi Coverage Analysis")
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: 20) {
                VStack {
                    Text("\(Int(averageSignalStrength * 100))%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(coverageColor)
                    Text("Average Signal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text(coverageQuality)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(coverageColor)
                    Text("Overall Quality")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(points.count)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Locations Tested")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.1), radius: 5)
    }
}

// MARK: - Optimal Router Card
struct OptimalRouterCard: View {
    let results: WiFiOptimizationResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "router.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text("Optimal Router Location")
                    .font(.headline)
                Spacer()
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("📍 Recommended Location:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(results.optimalRouterLocation.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    HStack {
                        Label("Height: \(String(format: "%.1f m", results.optimalRouterLocation.relativeHeight))", systemImage: "arrow.up.circle")
                        Spacer()
                        Label("Signal: \(Int(results.optimalRouterLocation.signalStrength * 100))%", systemImage: "wifi")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("💡 Why this location?")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        RecommendationBullet(text: "Central position provides optimal coverage distribution")
                        RecommendationBullet(text: "Good height for signal propagation")
                        RecommendationBullet(text: "Minimal interference from walls and obstacles")
                        RecommendationBullet(text: "Easy access for setup and maintenance")
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.1), radius: 5)
    }
}
// MARK: - Extender Recommendations Card
struct ExtenderRecommendationsCard: View {
    let results: WiFiOptimizationResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundColor(.orange)
                    .font(.title2)
                Text("WiFi Extender Recommendations")
                    .font(.headline)
                Spacer()
            }
            
            if results.recommendedExtenders.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title)
                    Text("No extenders needed!")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    Text("Your current router placement provides excellent coverage throughout the tested areas.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("We recommend \(results.recommendedExtenders.count) extender(s) for optimal coverage:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ForEach(Array(results.recommendedExtenders.enumerated()), id: \.offset) { index, extender in
                        ExtenderRecommendationRow(extender: extender, index: index + 1)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.1), radius: 5)
    }
}
struct ExtenderRecommendationRow: View {
    let extender: SensorExtenderRecommendation
    let index: Int
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 30, height: 30)
                Text("\(index)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(extender.location)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text("Floor: \(extender.floor)")
                    Text("•")
                    Text("Type: \(extender.type == .roomExtender ? "Room" : "Hallway")")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                Text(extender.reason)
                    .font(.caption)
                    .foregroundColor(.orange)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.05))
        .cornerRadius(10)
    }
}

// MARK: - Location Analysis Card
struct LocationAnalysisCard: View {
    let points: [SensorCalibrationPoint]
    
    private var sortedPoints: [SensorCalibrationPoint] {
        points.sorted { $0.signalStrength > $1.signalStrength }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "location.circle.fill")
                    .foregroundColor(.purple)
                    .font(.title2)
                Text("Location-by-Location Analysis")
                    .font(.headline)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(sortedPoints, id: \.id) { point in
                    LocationAnalysisRow(point: point)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.1), radius: 5)
    }
}

struct LocationAnalysisRow: View {
    let point: SensorCalibrationPoint
    
    private var signalQuality: String {
        if point.signalStrength >= 0.8 { return "Excellent" }
        else if point.signalStrength >= 0.6 { return "Good" }
        else if point.signalStrength >= 0.4 { return "Fair" }
        else { return "Poor" }
    }
            
            private var signalColor: Color {
                if point.signalStrength >= 0.8 { return .green }
                else if point.signalStrength >= 0.6 { return .blue }
                else if point.signalStrength >= 0.4 { return .orange }
                else { return .red }
            }
            
            private var recommendations: [String] {
                var recs: [String] = []
                if point.signalStrength < 0.3 {
                    recs.append("WiFi extender highly recommended")
                    recs.append("Check for physical obstacles")
                } else if point.signalStrength < 0.5 {
                    recs.append("Consider repositioning router closer")
                    recs.append("WiFi extender could help")
                } else if point.signalStrength < 0.7 {
                    recs.append("Signal is adequate for basic use")
                    recs.append("May struggle with 4K streaming")
                } else {
                    recs.append("Perfect for high-bandwidth activities")
                    recs.append("Suitable for work-from-home setup")
                }
                return recs
            }
            
            var body: some View {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(point.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Height: \(String(format: "%.1f m", point.relativeHeight))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            HStack(spacing: 4) {
                                Text("\(Int(point.signalStrength * 100))%")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(signalColor)
                                Circle()
                                    .fill(signalColor)
                                    .frame(width: 8, height: 8)
                            }
                            Text(signalQuality)
                                .font(.caption)
                                .foregroundColor(signalColor)
                                .fontWeight(.medium)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(recommendations, id: \.self) { rec in
                            RecommendationBullet(text: rec)
                        }
                    }
                }
                .padding()
                .background(signalColor.opacity(0.05))
                .cornerRadius(10)
            }
        }
        
// MARK: - Performance Insights Card
struct PerformanceInsightsCard: View {
    let results: WiFiOptimizationResult
    let points: [SensorCalibrationPoint]
    
    private var strongSignalAreas: Int {
        points.filter { $0.signalStrength >= 0.7 }.count
    }
    
    private var weakSignalAreas: Int {
        points.filter { $0.signalStrength < 0.4 }.count
            }
            
            private var estimatedImprovement: String {
                if results.recommendedExtenders.isEmpty {
                    return "Current setup is optimal"
                } else {
                    return "Up to \(results.recommendedExtenders.count * 25)% coverage improvement possible"
                }
            }
            
            var body: some View {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                        Text("Performance Insights")
                            .font(.headline)
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Coverage Statistics
                        HStack(spacing: 20) {
                            VStack {
                                Text("\(strongSignalAreas)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                                Text("Strong Areas")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text("\(weakSignalAreas)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                                Text("Weak Areas")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        Divider()
                        
                        // Recommendations Summary
                        VStack(alignment: .leading, spacing: 8) {
                            Text("📊 Key Insights:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                RecommendationBullet(text: estimatedImprovement)
                                
                                if weakSignalAreas > 0 {
                                    RecommendationBullet(text: "\(weakSignalAreas) area(s) need attention for optimal performance")
                                }
                                
                                if strongSignalAreas > points.count / 2 {
                                    RecommendationBullet(text: "Good overall coverage foundation established")
                                }
                                
                                RecommendationBullet(text: "Router placement at '\(results.optimalRouterLocation.name)' is recommended")
                            }
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .gray.opacity(0.1), radius: 5)
            }
        }
        
        // MARK: - Helper Views
// MARK: - Helper Views
struct RecommendationBullet: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
                .foregroundColor(.blue)
                .fontWeight(.bold)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - 3D Visualization View
struct WiFi3DVisualizationView: View {
    let results: WiFiOptimizationResult
        let calibrationPoints: [SensorCalibrationPoint]
        @State private var selectedPoint: SensorCalibrationPoint?
        @State private var showSignalLines = true
        @State private var showRecommendations = true
        
        var body: some View {
            VStack(spacing: 0) {
                // Controls
                VStack(spacing: 12) {
                    HStack {
                        Text("3D WiFi Coverage Analysis")
                            .font(.headline)
                        Spacer()
                    }
                    
                    HStack(spacing: 20) {
                        Toggle("Signal Lines", isOn: $showSignalLines)
                        Toggle("Recommendations", isOn: $showRecommendations)
                        Spacer()
                    }
                    .font(.caption)
                }
                .padding()
                .background(Color(.systemGray6))
                
                // 3D Scene
                WiFi3DSceneView(
                    calibrationPoints: calibrationPoints,
                    optimalLocation: results.optimalRouterLocation,
                    extenderRecommendations: showRecommendations ? results.recommendedExtenders : [],
                    showSignalLines: showSignalLines,
                    selectedPoint: $selectedPoint
                )
                
                // Selected Point Info
                if let selectedPoint = selectedPoint {
                    SelectedPointInfoView(point: selectedPoint)
                        .padding()
                        .background(Color.white)
                        .shadow(color: .gray.opacity(0.2), radius: 5)
                }
            }
        }
    }
    
// MARK: - 3D Scene View
struct WiFi3DSceneView: UIViewRepresentable {
    let calibrationPoints: [SensorCalibrationPoint]
    let optimalLocation: SensorCalibrationPoint
    let extenderRecommendations: [SensorExtenderRecommendation]
    let showSignalLines: Bool
    @Binding var selectedPoint: SensorCalibrationPoint?
    
    func makeUIView(context: UIViewRepresentableContext<WiFi3DSceneView>) -> SCNView {
        let sceneView = SCNView()
        sceneView.scene = createScene()
            sceneView.allowsCameraControl = true
            sceneView.autoenablesDefaultLighting = true
            sceneView.backgroundColor = UIColor.black
            
            // Add tap gesture
            let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
            sceneView.addGestureRecognizer(tapGesture)
            
            return sceneView
        }
        
        func updateUIView(_ uiView: SCNView, context: UIViewRepresentableContext<WiFi3DSceneView>) {
            uiView.scene = createScene()
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
        
        private func createScene() -> SCNScene {
            let scene = SCNScene()
            
            // Create floor reference plane
            createFloorPlane(in: scene)
            
            // Add calibration points
            for point in calibrationPoints {
                let node = createPointNode(for: point, isOptimal: point.id == optimalLocation.id)
                scene.rootNode.addChildNode(node)
            }
            
            // Add signal lines if enabled
            if showSignalLines {
                addSignalLines(to: scene)
            }
            
            // Add extender recommendations
            for recommendation in extenderRecommendations {
                let node = createExtenderNode(for: recommendation)
                scene.rootNode.addChildNode(node)
            }
            
            // Add lighting
            addLighting(to: scene)
            
            return scene
        }
        
        private func createFloorPlane(in scene: SCNScene) {
            let plane = SCNPlane(width: 20, height: 20)
            plane.firstMaterial?.diffuse.contents = UIColor.gray.withAlphaComponent(0.1)
            plane.firstMaterial?.isDoubleSided = true
            
            let planeNode = SCNNode(geometry: plane)
            planeNode.eulerAngles = SCNVector3(-Float.pi/2, 0, 0)
            planeNode.position = SCNVector3(0, -1, 0)
            
            scene.rootNode.addChildNode(planeNode)
        }
        
        private func createPointNode(for point: SensorCalibrationPoint, isOptimal: Bool) -> SCNNode {
            // Position in 3D space
            let position = convertToScenePosition(point: point)
            
            // Create sphere with size based on signal strength
            let radius = 0.2 + (point.signalStrength * 0.3)
            let sphere = SCNSphere(radius: CGFloat(radius))
            
            // Color based on signal strength and type
            let color = isOptimal ? UIColor.gold : signalStrengthColor(point.signalStrength)
            sphere.firstMaterial?.diffuse.contents = color
            sphere.firstMaterial?.emission.contents = color.withAlphaComponent(0.3)
            sphere.firstMaterial?.specular.contents = UIColor.white
            
            let pointNode = SCNNode(geometry: sphere)
            pointNode.position = position
            pointNode.name = point.id.uuidString
            
            // Add glow effect for optimal location
            if isOptimal {
                addGlowEffect(to: pointNode, color: UIColor.gold)
            }
            
            // Add height indicator line
            addHeightIndicator(to: pointNode, height: Float(point.relativeHeight))
            
            // Add text label
            addTextLabel(to: pointNode, text: point.name, point: point)
            
            return pointNode
        }
        
        private func createExtenderNode(for recommendation: SensorExtenderRecommendation) -> SCNNode {
            // Create a simple default position for extenders
            let position = SCNVector3(x: Float.random(in: -2...2), y: 0.5, z: Float.random(in: -2...2))
            
            // Create extender symbol (pyramid)
            let pyramid = SCNPyramid(width: 0.3, height: 0.4, length: 0.3)
            let color = recommendation.type == .roomExtender ? UIColor.red : UIColor.orange
            
            pyramid.firstMaterial?.diffuse.contents = color
            pyramid.firstMaterial?.emission.contents = color.withAlphaComponent(0.2)
            
            let extenderNode = SCNNode(geometry: pyramid)
            extenderNode.position = position
            extenderNode.name = "extender_\(recommendation.location)_\(recommendation.floor)"
            
            // Add pulsing animation
            let scaleAnimation = SCNAction.sequence([
                SCNAction.scale(to: 1.2, duration: 1.0),
                SCNAction.scale(to: 1.0, duration: 1.0)
            ])
            extenderNode.runAction(SCNAction.repeatForever(scaleAnimation))
            
            return extenderNode
        }
        
        private func convertToScenePosition(point: SensorCalibrationPoint) -> SCNVector3 {
            // Convert GPS coordinates and height to 3D scene coordinates
            // This is a simplified conversion - in a real app you'd use proper coordinate transformation
            
            let x = Float((point.location.longitude + 122.4194) * 1000) // Normalize longitude
            let z = Float((point.location.latitude - 37.7749) * 1000)   // Normalize latitude
            let y = Float(point.relativeHeight)                         // Use actual height
            
            return SCNVector3(x, y, z)
        }
        
        private func signalStrengthColor(_ strength: Double) -> UIColor {
            if strength >= 0.7 { return UIColor.systemGreen }
            else if strength >= 0.4 { return UIColor.systemOrange }
            else { return UIColor.systemRed }
        }
        
        private func addGlowEffect(to node: SCNNode, color: UIColor) {
            let glowGeometry = node.geometry?.copy() as? SCNGeometry
            glowGeometry?.firstMaterial?.emission.contents = color
            glowGeometry?.firstMaterial?.diffuse.contents = UIColor.clear
            
            let glowNode = SCNNode(geometry: glowGeometry)
            glowNode.scale = SCNVector3(1.2, 1.2, 1.2)
            node.addChildNode(glowNode)
        }
        
        private func addHeightIndicator(to node: SCNNode, height: Float) {
            if abs(height) > 0.1 { // Only show if significant height difference
                let lineGeometry = SCNCylinder(radius: 0.01, height: CGFloat(abs(height)))
                lineGeometry.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.6)
                
                let lineNode = SCNNode(geometry: lineGeometry)
                lineNode.position = SCNVector3(0, -height/2, 0)
                node.addChildNode(lineNode)
            }
        }
        
        private func addTextLabel(to node: SCNNode, text: String, point: SensorCalibrationPoint) {
            let textGeometry = SCNText(string: text, extrusionDepth: 0.02)
            textGeometry.firstMaterial?.diffuse.contents = UIColor.white
            textGeometry.font = UIFont.systemFont(ofSize: 0.1)
            
            let textNode = SCNNode(geometry: textGeometry)
            textNode.position = SCNVector3(0, 0.4, 0)
            textNode.constraints = [SCNBillboardConstraint()]
            
            node.addChildNode(textNode)
            
            // Add signal percentage
            let signalText = SCNText(string: "\(Int(point.signalStrength * 100))%", extrusionDepth: 0.02)
            signalText.firstMaterial?.diffuse.contents = UIColor.yellow
            signalText.font = UIFont.boldSystemFont(ofSize: 0.08)
            
            let signalNode = SCNNode(geometry: signalText)
            signalNode.position = SCNVector3(0, 0.6, 0)
            signalNode.constraints = [SCNBillboardConstraint()]
            
            node.addChildNode(signalNode)
        }
        
        private func addSignalLines(to scene: SCNScene) {
            // Connect points with lines showing signal relationships
            for i in 0..<calibrationPoints.count {
                for j in (i+1)..<calibrationPoints.count {
                    let point1 = calibrationPoints[i]
                    let point2 = calibrationPoints[j]
                    
                    let pos1 = convertToScenePosition(point: point1)
                    let pos2 = convertToScenePosition(point: point2)
                    
                    let line = createLineBetween(from: pos1, to: pos2, strength: min(point1.signalStrength, point2.signalStrength))
                    scene.rootNode.addChildNode(line)
                }
            }
        }
        
        private func createLineBetween(from: SCNVector3, to: SCNVector3, strength: Double) -> SCNNode {
            let distance = sqrt(pow(to.x - from.x, 2) + pow(to.y - from.y, 2) + pow(to.z - from.z, 2))
            
            let cylinder = SCNCylinder(radius: 0.005, height: CGFloat(distance))
            cylinder.firstMaterial?.diffuse.contents = signalStrengthColor(strength).withAlphaComponent(0.6)
            
            let lineNode = SCNNode(geometry: cylinder)
            lineNode.position = SCNVector3(
                (from.x + to.x) / 2,
                (from.y + to.y) / 2,
                (from.z + to.z) / 2
            )
            
            // Rotate to align with the line direction
            let direction = SCNVector3(to.x - from.x, to.y - from.y, to.z - from.z)
            lineNode.look(at: SCNVector3(from.x + direction.x, from.y + direction.y, from.z + direction.z))
            
            return lineNode
        }
        
        private func addLighting(to scene: SCNScene) {
            // Ambient light
            let ambientLight = SCNLight()
            ambientLight.type = .ambient
            ambientLight.color = UIColor.white.withAlphaComponent(0.4)
            let ambientNode = SCNNode()
            ambientNode.light = ambientLight
            scene.rootNode.addChildNode(ambientNode)
            
            // Directional light
            let directionalLight = SCNLight()
            directionalLight.type = .directional
            directionalLight.color = UIColor.white
            directionalLight.intensity = 1000
            let directionalNode = SCNNode()
            directionalNode.light = directionalLight
            directionalNode.position = SCNVector3(0, 10, 10)
            directionalNode.eulerAngles = SCNVector3(-Float.pi/4, 0, 0)
            scene.rootNode.addChildNode(directionalNode)
        }
        
        class Coordinator: NSObject {
            let parent: WiFi3DSceneView
            
            init(_ parent: WiFi3DSceneView) {
                self.parent = parent
            }
            
            @objc func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
                let sceneView = gestureRecognizer.view as! SCNView
                let location = gestureRecognizer.location(in: sceneView)
                
                let hitResults = sceneView.hitTest(location, options: [SCNHitTestOption: Any]())
                
                if let hitResult = hitResults.first,
                   let nodeName = hitResult.node.name,
                   let pointId = UUID(uuidString: nodeName) {
                    
                    if let point = parent.calibrationPoints.first(where: { $0.id == pointId }) {
                        parent.selectedPoint = point
                    }
                } else {
                    parent.selectedPoint = nil
                }
            }
    }
}

// MARK: - Selected Point Info View
struct SelectedPointInfoView: View {
    let point: SensorCalibrationPoint
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(point.name)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                    
                    Circle()
                        .fill(signalColor(point.signalStrength))
                        .frame(width: 16, height: 16)
                    
                    Text("\(Int(point.signalStrength * 100))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Height")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f m", point.relativeHeight))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Heading")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.0f°", point.magneticHeading))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Steps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(point.stepCount)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                }
            }
        }
        
        private func signalColor(_ strength: Double) -> Color {
            if strength >= 0.7 { return .green }
            else if strength >= 0.4 { return .orange }
            else { return .red }
        }
    }
    
// MARK: - Map Visualization View
struct WiFiMapVisualizationView: View {
    let results: WiFiOptimizationResult
    let calibrationPoints: [SensorCalibrationPoint]
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Signal Coverage Map")
                .font(.headline)
                .padding()
                    .background(Color(.systemGray6))
                
                Map(position: $cameraPosition) {
                    // Calibration points
                    ForEach(calibrationPoints, id: \.id) { point in
                        Annotation(point.name, coordinate: point.location) {
                            ZStack {
                                Circle()
                                    .fill(mapSignalColor(point.signalStrength))
                                    .frame(width: 30, height: 30)
                                
                                if point.id == results.optimalRouterLocation.id {
                                    Image(systemName: "wifi")
                                        .foregroundColor(.white)
                                        .font(.caption)
                                } else {
                                    Text("\(Int(point.signalStrength * 100))")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                    
                    // Extender recommendations
                    ForEach(Array(results.recommendedExtenders.enumerated()), id: \.offset) { index, extender in
                        Annotation("Extender", coordinate: results.optimalRouterLocation.location) {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .foregroundColor(.red)
                                .font(.title2)
                        }
                    }
                }
                .onAppear {
                    updateCameraPosition()
                }
            }
        }
        
        private func updateCameraPosition() {
            if !calibrationPoints.isEmpty {
                let coordinates = calibrationPoints.map { $0.location }
                let region = calculateRegion(for: coordinates)
                cameraPosition = .region(region)
            }
        }
        
        private func calculateRegion(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
            let lats = coordinates.map { $0.latitude }
            let longs = coordinates.map { $0.longitude }
            
            let maxLat = lats.max() ?? 0
            let minLat = lats.min() ?? 0
            let maxLong = longs.max() ?? 0
            let minLong = longs.min() ?? 0
            
            let center = CLLocationCoordinate2D(
                latitude: (maxLat + minLat) / 2,
                longitude: (maxLong + minLong) / 2
            )
            
            let span = MKCoordinateSpan(
                latitudeDelta: (maxLat - minLat) * 1.5,
                longitudeDelta: (maxLong - minLong) * 1.5
            )
            
            return MKCoordinateRegion(center: center, span: span)
        }
        
        private func mapSignalColor(_ strength: Double) -> Color {
            if strength >= 0.7 { return .green }
            else if strength >= 0.4 { return .orange }
            else { return .red }
    }
}

// MARK: - Analysis View
struct WiFiAnalysisView: View {
    let results: WiFiOptimizationResult
    let calibrationPoints: [SensorCalibrationPoint]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Coverage Summary
                CoverageAnalysisCard(coverage: results.coverageAnalysis)
                
                // Optimal Router Location
                OptimalLocationCard(location: results.optimalRouterLocation)
                    
                    // Signal Distribution Chart
                    SignalDistributionChart(points: calibrationPoints)
                    
                    // Height Analysis
                    HeightAnalysisCard(points: calibrationPoints)
                }
                .padding()
            }
    }
}

struct CoverageAnalysisCard: View {
    let coverage: SensorCoverageAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Coverage Summary")
                .font(.headline)
            
            HStack(spacing: 20) {
                VStack {
                    Text(String(format: "%.0f%%", coverage.coveragePercentage))
                        .font(.title)
                        .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        Text("Coverage")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        Text("\(coverage.weakAreas)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                        
                        Text("Weak Areas")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        Text("\(coverage.totalRooms - coverage.wellCoveredRooms)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                        
                        Text("Poor Rooms")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .gray.opacity(0.1), radius: 5)
        }
    }
    
struct OptimalLocationCard: View {
    let location: SensorCalibrationPoint
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "wifi")
                    .foregroundColor(.blue)
                
                Text("Optimal Router Location")
                    .font(.headline)
                
                Spacer()
            }
            
            Text(location.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Signal Strength:")
                        Spacer()
                        Text("\(Int(location.signalStrength * 100))%")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Height:")
                        Spacer()
                        Text(String(format: "%.1f m", location.relativeHeight))
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Optimal Score:")
                        Spacer()
                        Text("⭐⭐⭐⭐⭐")
                    }
                }
                .font(.subheadline)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }

struct SignalDistributionChart: View {
    let points: [SensorCalibrationPoint]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Signal Distribution")
                .font(.headline)
            
            // Simple bar chart representation
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(points.indices, id: \.self) { index in
                    let point = points[index]
                    VStack {
                        Rectangle()
                            .fill(signalColor(point.signalStrength))
                            .frame(width: 30, height: CGFloat(point.signalStrength * 100))
                        
                        Text(String(point.name.prefix(3)))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 120)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 5)
    }
    
    private func signalColor(_ strength: Double) -> Color {
        if strength >= 0.7 { return .green }
        else if strength >= 0.4 { return .orange }
        else { return .red }
    }
}

struct HeightAnalysisCard: View {
    let points: [SensorCalibrationPoint]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Height Analysis")
                .font(.headline)
            
            let heights = points.map { $0.relativeHeight }
            let avgHeight = heights.reduce(0, +) / Double(heights.count)
            let maxHeight = heights.max() ?? 0
            let minHeight = heights.min() ?? 0
            
            VStack(spacing: 8) {
                HStack {
                    Text("Average Height:")
                    Spacer()
                    Text(String(format: "%.1f m", avgHeight))
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Height Range:")
                    Spacer()
                    Text(String(format: "%.1f - %.1f m", minHeight, maxHeight))
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Height Variation:")
                    Spacer()
                    Text(String(format: "%.1f m", maxHeight - minHeight))
                        .fontWeight(.semibold)
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 5)
    }
}
#Preview {
    WiFiOptimizationResultsView(
        results: WiFiOptimizationResult(
            optimalRouterLocation: SensorCalibrationPoint(
                name: "Living Room",
                location: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                altitude: 10.0,
                relativeHeight: 1.2,
                magneticHeading: 45.0,
                trueHeading: 50.0,
                accelerometerData: nil,
                gyroscopeData: nil,
                magnetometerData: nil,
                signalStrength: 0.9,
                timestamp: Date(),
                distanceFromPrevious: 0.0,
                stepCount: 0
            ),
            recommendedExtenders: [],
            coverageAnalysis: SensorCoverageAnalysis(
                totalRooms: 10,
                wellCoveredRooms: 8,
                weakAreas: 2,
                coveragePercentage: 85.0
            ),
            signalPrediction: SignalPredictionMap(predictions: [:], resolution: 1.0)
        ),
        calibrationPoints: []
    )
}
