import SwiftUI
import SceneKit
import UIKit
import CoreLocation

struct Room3DVisualizationView: View {
    let calibratedLocations: [CalibratedLocation]
    let layoutData: RoomLayoutData?
    @Environment(\.dismiss) var dismiss
    @State private var selectedRoom: CalibratedLocation?
    @State private var showingControls = true
    @State private var filterFloor: Int? = nil
    @State private var showSignalLines = true
    @State private var cameraMode: CameraMode = .overview
    
    enum CameraMode: String, CaseIterable {
        case overview = "Overview"
        case floor = "Floor View"
        case signal = "Signal View"
        case router = "Router View"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 3D Scene
                Room3DSceneView(
                    calibratedLocations: calibratedLocations,
                    layoutData: layoutData,
                    selectedRoom: $selectedRoom,
                    showSignalLines: showSignalLines,
                    filterFloor: filterFloor,
                    cameraMode: cameraMode
                )
                .ignoresSafeArea()
                
                // Overlay Controls
                VStack {
                    // Top Controls
                    if showingControls {
                        HStack {
                            // Floor Filter
                            Picker("Floor", selection: $filterFloor) {
                                Text("All Floors").tag(nil as Int?)
                                ForEach(1...3, id: \.self) { floor in
                                    Text("Floor \(floor)").tag(floor as Int?)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(maxWidth: 200)
                            
                            Spacer()
                            
                            // Camera Mode
                            Picker("View", selection: $cameraMode) {
                                ForEach(CameraMode.allCases, id: \.self) { mode in
                                    Text(mode.rawValue).tag(mode)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
                        .padding()
                    }
                    
                    Spacer()
                    
                    // Bottom Info Panel
                    if let selectedRoom = selectedRoom {
                        RoomInfoPanel(room: selectedRoom)
                            .padding()
                    } else if showingControls {
                        ControlsPanel(
                            showSignalLines: $showSignalLines,
                            totalRooms: calibratedLocations.count
                        )
                        .padding()
                    }
                }
                
                // Toggle Controls Button
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingControls.toggle()
                            }
                        }) {
                            Image(systemName: showingControls ? "eye.slash" : "eye")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.7))
                                .clipShape(Circle())
                        }
                        .padding()
                    }
                    Spacer()
                }
            }
            .navigationTitle("3D Room Visualization")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("2D View") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - 3D Scene View
struct Room3DSceneView: UIViewRepresentable {
    let calibratedLocations: [CalibratedLocation]
    let layoutData: RoomLayoutData?
    @Binding var selectedRoom: CalibratedLocation?
    let showSignalLines: Bool
    let filterFloor: Int?
    let cameraMode: Room3DVisualizationView.CameraMode
    
    func makeUIView(context: UIViewRepresentableContext<Room3DSceneView>) -> SCNView {
        print("🚀 Creating SCNView for Room3DVisualizationView")
        let sceneView = SCNView()
        sceneView.scene = createScene()
        sceneView.allowsCameraControl = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.backgroundColor = UIColor.black
        
        // Enhanced camera controls for better interaction
        sceneView.defaultCameraController.inertiaEnabled = true
        sceneView.defaultCameraController.maximumVerticalAngle = 90
        sceneView.defaultCameraController.minimumVerticalAngle = -90
        sceneView.defaultCameraController.maximumHorizontalAngle = 180
        sceneView.defaultCameraController.minimumHorizontalAngle = -180
        
        // Force render to see if we have any content at all
        sceneView.rendersContinuously = false
        sceneView.preferredFramesPerSecond = 60
        
        // Set initial camera position only once
        setupInitialCamera(sceneView)
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: UIViewRepresentableContext<Room3DSceneView>) {
        // Only update scene content, not camera position to preserve user interaction
        if let scene = uiView.scene {
            updateSceneContent(scene)
        } else {
            uiView.scene = createScene()
            setupInitialCamera(uiView)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func createScene() -> SCNScene {
        let scene = SCNScene()
        
        // Filter locations by floor if needed
        let locations = filterFloor.map { floor in
            calibratedLocations.filter { $0.floor == floor }
        } ?? calibratedLocations
        
        // Create floor planes
        createFloorPlanes(in: scene)
        
        // Create room nodes
        for location in locations {
            let roomNode = createRoomNode(for: location)
            scene.rootNode.addChildNode(roomNode)
        }
        
        // Add signal lines if enabled
        if showSignalLines {
            addSignalLines(to: scene, for: locations)
        }
        
        // Add lighting
        addLighting(to: scene)
        
        // Add a test sphere if no rooms exist
        if locations.isEmpty {
            print("⚠️ No rooms to display, adding test sphere")
            let testSphere = SCNSphere(radius: 1.0)
            testSphere.firstMaterial?.diffuse.contents = UIColor.red
            let testNode = SCNNode(geometry: testSphere)
            testNode.position = SCNVector3(0, 0, 0)
            scene.rootNode.addChildNode(testNode)
        }
        
        print("✅ Scene creation completed")
        return scene
    }
    
    private func createFloorPlanes(in scene: SCNScene) {
        let floors = Set(calibratedLocations.map { $0.floor }).sorted()
        print("🏢 Creating floor planes for floors: \(floors)")
        
        // If no floors from calibrated locations, create at least floor 1
        let floorsToCreate = floors.isEmpty ? [1] : floors
        
        for floor in floorsToCreate {
            if let filterFloor = filterFloor, floor != filterFloor {
                continue
            }
            
            let plane = SCNPlane(width: 10, height: 10)
            plane.firstMaterial?.diffuse.contents = UIColor.gray.withAlphaComponent(0.1)
            plane.firstMaterial?.isDoubleSided = true
            
            let floorNode = SCNNode(geometry: plane)
            floorNode.position = SCNVector3(0, Float(floor - 1) * 3.0, 0)
            floorNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
            floorNode.name = "floor_\(floor)"
            
            scene.rootNode.addChildNode(floorNode)
            print("✅ Added floor plane for floor \(floor)")
            
            // Add floor label
            let text = SCNText(string: "Floor \(floor)", extrusionDepth: 0.05)
            text.firstMaterial?.diffuse.contents = UIColor.white
            text.font = UIFont.systemFont(ofSize: 0.5)
            
            let textNode = SCNNode(geometry: text)
            textNode.position = SCNVector3(-4, Float(floor - 1) * 3.0 + 0.1, -4)
            textNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
            
            scene.rootNode.addChildNode(textNode)
        }
    }
    
    private func createRoomNode(for location: CalibratedLocation) -> SCNNode {
        // Get position from layout data if available, otherwise use default
        let position = getRoomPosition(for: location)
        
        // Create room geometry based on signal strength
        let radius = 0.3 + (location.signalStrength * 0.4) // Size based on signal
        let sphere = SCNSphere(radius: CGFloat(radius))
        
        // Color based on signal strength
        let color = colorForSignalStrength(location.signalStrength)
        sphere.firstMaterial?.diffuse.contents = color
        sphere.firstMaterial?.emission.contents = color.withAlphaComponent(0.3)
        sphere.firstMaterial?.specular.contents = UIColor.white
        
        let roomNode = SCNNode(geometry: sphere)
        roomNode.position = position
        roomNode.name = location.id.uuidString
        
        // Add room label
        let text = SCNText(string: location.name, extrusionDepth: 0.02)
        text.firstMaterial?.diffuse.contents = UIColor.white
        text.font = UIFont.systemFont(ofSize: 0.2)
        
        let textNode = SCNNode(geometry: text)
        textNode.position = SCNVector3(0, radius + 0.3, 0)
        textNode.constraints = [SCNBillboardConstraint()]
        
        roomNode.addChildNode(textNode)
        
        // Add signal strength indicator
        let signalText = SCNText(string: "\(Int(location.signalStrength * 100))%", extrusionDepth: 0.02)
        signalText.firstMaterial?.diffuse.contents = UIColor.yellow
        signalText.font = UIFont.boldSystemFont(ofSize: 0.15)
        
        let signalNode = SCNNode(geometry: signalText)
        signalNode.position = SCNVector3(0, radius + 0.6, 0)
        signalNode.constraints = [SCNBillboardConstraint()]
        
        roomNode.addChildNode(signalNode)
        
        // Add selection highlight
        if selectedRoom?.id == location.id {
            addSelectionHighlight(to: roomNode, radius: Float(radius))
        }
        
        return roomNode
    }
    
    private func getRoomPosition(for location: CalibratedLocation) -> SCNVector3 {
        if let layoutData = layoutData,
           let room = layoutData.rooms.first(where: { $0.calibratedLocation.id == location.id }) {
            // Convert 2D layout position to 3D
            let x = (room.position.x - 150) / 30 // Scale and center
            let z = (room.position.y - 200) / 30 // Scale and center
            let y = Float(location.floor - 1) * 3.0
            return SCNVector3(Float(x), y, Float(z))
        } else {
            // Default positioning based on hash for consistency
            let hash = location.name.hash
            let x = Float((hash % 1000) - 500) / 100
            let z = Float(((hash / 1000) % 1000) - 500) / 100
            let y = Float(location.floor - 1) * 3.0
            return SCNVector3(x, y, z)
        }
    }
    
    private func colorForSignalStrength(_ strength: Double) -> UIColor {
        if strength >= 0.7 {
            return UIColor.systemGreen
        } else if strength >= 0.4 {
            return UIColor.systemOrange
        } else {
            return UIColor.systemRed
        }
    }
    
    private func addSelectionHighlight(to node: SCNNode, radius: Float) {
        let ring = SCNTorus(ringRadius: CGFloat(radius + 0.2), pipeRadius: 0.05)
        ring.firstMaterial?.diffuse.contents = UIColor.cyan
        ring.firstMaterial?.emission.contents = UIColor.cyan
        
        let ringNode = SCNNode(geometry: ring)
        ringNode.name = "selection_highlight"
        
        // Animate the ring
        let rotation = SCNAction.rotateBy(x: 0, y: CGFloat(2 * Float.pi), z: 0, duration: 2)
        let repeatRotation = SCNAction.repeatForever(rotation)
        ringNode.runAction(repeatRotation)
        
        node.addChildNode(ringNode)
    }
    
    private func addSignalLines(to scene: SCNScene, for locations: [CalibratedLocation]) {
        // Connect rooms with signal lines based on signal strength
        for (i, location1) in locations.enumerated() {
            for j in (i+1)..<locations.count {
                let location2 = locations[j]
                
                // Only connect rooms on the same floor or adjacent floors
                if abs(location1.floor - location2.floor) <= 1 {
                    let pos1 = getRoomPosition(for: location1)
                    let pos2 = getRoomPosition(for: location2)
                    
                    let distance = simd_distance(simd_float3(pos1), simd_float3(pos2))
                    let signalAverage = (location1.signalStrength + location2.signalStrength) / 2
                    
                    // Create line if rooms are close and have decent signal
                    if distance < 3.0 && signalAverage > 0.3 {
                        let line = createSignalLine(from: pos1, to: pos2, strength: signalAverage)
                        scene.rootNode.addChildNode(line)
                    }
                }
            }
        }
    }
    
    private func createSignalLine(from start: SCNVector3, to end: SCNVector3, strength: Double) -> SCNNode {
        let vector = SCNVector3(end.x - start.x, end.y - start.y, end.z - start.z)
        let distance = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
        
        let cylinder = SCNCylinder(radius: 0.02, height: CGFloat(distance))
        cylinder.firstMaterial?.diffuse.contents = colorForSignalStrength(strength).withAlphaComponent(0.6)
        
        let lineNode = SCNNode(geometry: cylinder)
        lineNode.position = SCNVector3((start.x + end.x) / 2, (start.y + end.y) / 2, (start.z + end.z) / 2)
        
        // Orient the cylinder
        let up = SCNVector3(0, 1, 0)
        let cross = SCNVector3(
            up.y * vector.z - up.z * vector.y,
            up.z * vector.x - up.x * vector.z,
            up.x * vector.y - up.y * vector.x
        )
        let dot = up.x * vector.x + up.y * vector.y + up.z * vector.z
        let angle = acos(dot / distance)
        
        if distance > 0 {
            lineNode.rotation = SCNVector4(cross.x, cross.y, cross.z, angle)
        }
        
        return lineNode
    }
    
    private func addLighting(to scene: SCNScene) {
        print("💡 Adding lighting to scene")
        
        // Ambient light
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = UIColor.white.withAlphaComponent(0.4)
        ambientLight.intensity = 500
        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        scene.rootNode.addChildNode(ambientNode)
        
        // Directional light
        let directionalLight = SCNLight()
        directionalLight.type = .directional
        directionalLight.color = UIColor.white
        directionalLight.intensity = 1500
        directionalLight.castsShadow = true
        let directionalNode = SCNNode()
        directionalNode.light = directionalLight
        directionalNode.position = SCNVector3(5, 10, 5)
        directionalNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(directionalNode)
        
        // Additional omni light for better visibility
        let omniLight = SCNLight()
        omniLight.type = .omni
        omniLight.color = UIColor.white
        omniLight.intensity = 800
        let omniNode = SCNNode()
        omniNode.light = omniLight
        omniNode.position = SCNVector3(0, 5, 0)
        scene.rootNode.addChildNode(omniNode)
        
        print("✅ Added ambient, directional, and omni lighting")
    }
    
    // Set initial camera position only once
    private func setupInitialCamera(_ sceneView: SCNView) {
        guard let camera = sceneView.pointOfView else { return }
        
        // Set a good default overview position
        camera.position = SCNVector3(8, 8, 8)
        camera.look(at: SCNVector3(0, 2, 0))
        
        print("📹 Initial camera position set to overview")
    }
    
    // Update scene content without affecting camera
    private func updateSceneContent(_ scene: SCNScene) {
        // Remove existing content nodes (keep camera and lights)
        scene.rootNode.childNodes.forEach { node in
            if node.name != "camera" && node.name?.contains("light") != true {
                node.removeFromParentNode()
            }
        }
        
        // Filter locations by floor if needed
        let locations = filterFloor.map { floor in
            calibratedLocations.filter { $0.floor == floor }
        } ?? calibratedLocations
        
        // Create floor planes
        createFloorPlanes(in: scene)
        
        // Create room nodes
        for location in locations {
            let roomNode = createRoomNode(for: location)
            scene.rootNode.addChildNode(roomNode)
        }
        
        // Add signal lines if enabled
        if showSignalLines {
            addSignalLines(to: scene, for: locations)
        }
        
        // Add lighting
        addLighting(to: scene)
        
        // Add a test sphere if no rooms exist
        if locations.isEmpty {
            print("⚠️ No rooms to display, adding test sphere")
            let testSphere = SCNSphere(radius: 1.0)
            testSphere.firstMaterial?.diffuse.contents = UIColor.red
            let testNode = SCNNode(geometry: testSphere)
            testNode.position = SCNVector3(0, 0, 0)
            scene.rootNode.addChildNode(testNode)
        }
        
        print("🔄 Scene content updated")
    }
    
    private func updateCamera(_ sceneView: SCNView) {
        guard let camera = sceneView.pointOfView else { return }
        
        switch cameraMode {
        case .overview:
            camera.position = SCNVector3(8, 8, 8)
            camera.look(at: SCNVector3(0, 2, 0))
        case .floor:
            let currentFloor = filterFloor ?? 1
            camera.position = SCNVector3(0, Float(currentFloor - 1) * 3.0 + 5, 5)
            camera.look(at: SCNVector3(0, Float(currentFloor - 1) * 3.0, 0))
        case .signal:
            camera.position = SCNVector3(10, 5, 0)
            camera.look(at: SCNVector3(0, 2, 0))
        case .router:
            camera.position = SCNVector3(0, 10, 0)
            camera.look(at: SCNVector3(0, 0, 0))
        }
    }
    
    class Coordinator: NSObject {
        var parent: Room3DSceneView
        
        init(_ parent: Room3DSceneView) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
            let sceneView = gestureRecognizer.view as! SCNView
            let location = gestureRecognizer.location(in: sceneView)
            
            let hitResults = sceneView.hitTest(location, options: [SCNHitTestOption: Any]())
            
            if let hitResult = hitResults.first,
               let nodeName = hitResult.node.name,
               let roomId = UUID(uuidString: nodeName) {
                
                if let room = parent.calibratedLocations.first(where: { $0.id == roomId }) {
                    parent.selectedRoom = room
                }
            } else {
                parent.selectedRoom = nil
            }
        }
    }
}

// MARK: - Supporting Views
struct RoomInfoPanel: View {
    let room: CalibratedLocation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: room.type.icon)
                    .foregroundColor(.blue)
                Text(room.name)
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text("Floor \(room.floor)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Signal Strength")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(room.signalStrength * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(colorForSignal(room.signalStrength))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Recommendations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(room.recommendations.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(12)
    }
    
    private func colorForSignal(_ strength: Double) -> Color {
        if strength >= 0.7 {
            return .green
        } else if strength >= 0.4 {
            return .orange
        } else {
            return .red
        }
    }
}

struct ControlsPanel: View {
    @Binding var showSignalLines: Bool
    let totalRooms: Int
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("3D WiFi Visualization")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("\(totalRooms) rooms")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            HStack {
                Toggle("Signal Lines", isOn: $showSignalLines)
                    .toggleStyle(SwitchToggleStyle())
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Circle().fill(Color.green).frame(width: 8, height: 8)
                        Text("Strong").font(.caption2)
                    }
                    HStack(spacing: 4) {
                        Circle().fill(Color.orange).frame(width: 8, height: 8)
                        Text("Medium").font(.caption2)
                    }
                    HStack(spacing: 4) {
                        Circle().fill(Color.red).frame(width: 8, height: 8)
                        Text("Weak").font(.caption2)
                    }
                }
                .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(12)
    }
}

#Preview {
    Room3DVisualizationView(
        calibratedLocations: [
            CalibratedLocation(
                name: "Living Room",
                type: .room,
                floor: 1,
                signalStrength: 0.8,
                coordinates: Optional<CLLocationCoordinate2D>.none,
                timestamp: Date(),
                recommendations: []
            ),
            CalibratedLocation(
                name: "Kitchen",
                type: .room,
                floor: 1,
                signalStrength: 0.6,
                coordinates: Optional<CLLocationCoordinate2D>.none,
                timestamp: Date(),
                recommendations: []
            ),
            CalibratedLocation(
                name: "Bedroom",
                type: .room,
                floor: 2,
                signalStrength: 0.4,
                coordinates: Optional<CLLocationCoordinate2D>.none,
                timestamp: Date(),
                recommendations: []
            )
        ],
        layoutData: Optional<RoomLayoutData>.none
    )
}
