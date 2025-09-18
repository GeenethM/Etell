import SwiftUI
import SceneKit
import UIKit
import CoreLocation

struct Room3DVisualizationView: View {
    let calibratedLocations: [CalibratedLocation]
    let layoutData: RoomLayoutData?
    let environmentType: EnvironmentType?
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
                    environmentType: environmentType,
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
    let environmentType: EnvironmentType?
    @Binding var selectedRoom: CalibratedLocation?
    let showSignalLines: Bool
    let filterFloor: Int?
    let cameraMode: Room3DVisualizationView.CameraMode
    
    func makeUIView(context: UIViewRepresentableContext<Room3DSceneView>) -> SCNView {
        print("🚀 Creating enhanced SCNView for Room3DVisualizationView")
        let sceneView = SCNView()
        sceneView.scene = createScene()
        sceneView.allowsCameraControl = true
        sceneView.autoenablesDefaultLighting = false // Using custom lighting
        sceneView.backgroundColor = UIColor.black
        
        // Enhanced camera controls
        sceneView.defaultCameraController.inertiaEnabled = true
        sceneView.defaultCameraController.interactionMode = .orbitTurntable
        sceneView.defaultCameraController.maximumVerticalAngle = 89
        sceneView.defaultCameraController.minimumVerticalAngle = -89
        sceneView.defaultCameraController.maximumHorizontalAngle = 180
        sceneView.defaultCameraController.minimumHorizontalAngle = -180
        
        // Enhanced rendering settings
        sceneView.antialiasingMode = .multisampling4X
        sceneView.preferredFramesPerSecond = 60
        sceneView.rendersContinuously = true
        
        // Enable HDR and tone mapping for better visuals
        if #available(iOS 13.0, *) {
            sceneView.technique = createEnhancedRenderingTechnique()
        }
        
        // Set initial camera position
        setupEnhancedCamera(sceneView)
        
        // Add gesture recognizers
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        
        return sceneView
    }
    
    private func createEnhancedRenderingTechnique() -> SCNTechnique? {
        // Enhanced rendering with post-processing effects
        guard let path = Bundle.main.path(forResource: "enhanced_rendering", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            return nil
        }
        return SCNTechnique(dictionary: dict)
    }
    
    private func setupEnhancedCamera(_ sceneView: SCNView) {
        guard let camera = sceneView.pointOfView else { return }
        
        // Enhanced camera settings
        camera.camera?.fieldOfView = 65
        camera.camera?.zNear = 0.1
        camera.camera?.zFar = 100
        
        // HDR settings for better lighting
        camera.camera?.exposureAdaptationBrighteningSpeedFactor = 0.6
        camera.camera?.exposureAdaptationDarkeningSpeedFactor = 0.6
        camera.camera?.minimumExposure = -5
        camera.camera?.maximumExposure = 8
        
        // Set initial position based on building height
        let floors = Set(calibratedLocations.map { $0.floor }).sorted()
        let maxFloor = floors.max() ?? 1
        let buildingHeight = Float(maxFloor - 1) * Float(4.0)
        let centerHeight = buildingHeight / Float(2.0) + Float(2.0)
        
        if maxFloor > 1 {
            // Multi-floor building: position camera higher and further back for better overview
            camera.position = SCNVector3(20, centerHeight + 8, 20)
            camera.look(at: SCNVector3(0, centerHeight, 0))
            print("📹 Multi-floor camera positioned at (20, \(centerHeight + 8), 20) looking at (0, \(centerHeight), 0)")
        } else {
            // Single floor: use original positioning
            camera.position = SCNVector3(10, 10, 10)
            camera.look(at: SCNVector3(0, 3, 0))
        }
        
        print("📹 Enhanced camera configuration complete for \(maxFloor) floor(s)")
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
        
        // Set environment-specific background
        scene.background.contents = createEnvironmentBackground()
        
        // For multi-floor buildings, always show all rooms; for single floor, respect filter
        let allFloors = Set(calibratedLocations.map { $0.floor }).sorted()
        let locations: [CalibratedLocation]
        
        print("🏢 All floors detected: \(allFloors)")
        print("🏢 Current filterFloor: \(filterFloor?.description ?? "nil")")
        
        // Always show all rooms for multi-floor buildings unless specifically filtering
        locations = calibratedLocations
        
        // Create enhanced floor planes with grid
        createEnhancedFloorPlanes(in: scene)
        
        // Add transparent house structure based on environment type
        addTransparentHouseStructure(to: scene, floors: allFloors, environmentType: environmentType)
        
        // Create enhanced room nodes for all locations
        for location in locations {
            let roomNode = createEnhancedRoomNode(for: location)
            scene.rootNode.addChildNode(roomNode)
        }
        
        // Add enhanced signal lines if enabled (connect all rooms in multi-floor)
        if showSignalLines {
            addEnhancedSignalLines(to: scene, for: locations)
        }
        
        // Add enhanced lighting
        addEnhancedLighting(to: scene)
        
        // Add particle systems for ambiance
        addAmbientParticles(to: scene)
        
        print("✅ Enhanced scene creation completed")
        return scene
    }
    
    private func createEnvironmentBackground() -> [UIColor] {
        switch environmentType {
        case .house:
            // Warm home environment - cozy warm tones
            return [
                UIColor(red: 0.15, green: 0.10, blue: 0.05, alpha: 1.0), // Warm dark brown
                UIColor(red: 0.25, green: 0.15, blue: 0.10, alpha: 1.0), // Medium warm brown
                UIColor(red: 0.20, green: 0.12, blue: 0.08, alpha: 1.0), // Cozy brown
                UIColor(red: 0.30, green: 0.20, blue: 0.15, alpha: 1.0)  // Lighter warm tone
            ]
        case .office:
            // Professional office environment - cool, clean tones
            return [
                UIColor(red: 0.05, green: 0.08, blue: 0.12, alpha: 1.0), // Cool dark blue
                UIColor(red: 0.08, green: 0.12, blue: 0.18, alpha: 1.0), // Professional blue
                UIColor(red: 0.06, green: 0.10, blue: 0.15, alpha: 1.0), // Deep corporate blue
                UIColor(red: 0.10, green: 0.15, blue: 0.22, alpha: 1.0)  // Modern blue-gray
            ]
        case .apartment:
            // Modern apartment - neutral urban tones
            return [
                UIColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1.0), // Urban gray
                UIColor(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0), // Modern gray
                UIColor(red: 0.10, green: 0.10, blue: 0.13, alpha: 1.0), // Sleek gray
                UIColor(red: 0.15, green: 0.15, blue: 0.18, alpha: 1.0)  // Contemporary gray
            ]
        case .none:
            // Default background - original dark gradient
            return [
                UIColor.black,
                UIColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1.0),
                UIColor.black,
                UIColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1.0)
            ]
        }
    }
    
    private func createEnhancedFloorPlanes(in scene: SCNScene) {
        let floors = Set(calibratedLocations.map { $0.floor }).sorted()
        print("🏢 Creating enhanced floor planes for floors: \(floors)")
        print("🏢 Filter floor is: \(filterFloor?.description ?? "nil")")
        
        let floorsToCreate = floors.isEmpty ? [1] : floors
        
        for floor in floorsToCreate {
            // Show floor if:
            // 1. No filter is set (filterFloor is nil), OR
            // 2. Filter is set and this floor matches it
            let shouldShowFloor = filterFloor == nil || filterFloor == floor
            
            if !shouldShowFloor {
                print("🏢 Skipping floor \(floor) due to filter (showing only floor \(filterFloor!))")
                continue
            }
            
            print("🏢 Creating floor plane for floor \(floor)")
            
            // Create main floor plane with continuous heatmap
            let plane = SCNPlane(width: 15, height: 15) // Larger for better coverage
            
            // Create continuous heatmap texture based on signal strength distribution
            let heatmapImage = createContinuousHeatmapTexture(for: floor)
            plane.firstMaterial?.diffuse.contents = heatmapImage
            plane.firstMaterial?.transparency = 0.4 // More transparent for layering
            plane.firstMaterial?.isDoubleSided = true
            plane.firstMaterial?.writesToDepthBuffer = false // For proper layering
            
            // Add subtle emission for depth
            let floorColor = floorColorForLevel(floor)
            plane.firstMaterial?.emission.contents = floorColor.withAlphaComponent(0.05)
            
            let floorNode = SCNNode(geometry: plane)
            // Position floors vertically stacked - each floor 4 units apart
            let floorHeight = Float(floor - 1) * Float(4.0)
            floorNode.position = SCNVector3(0, floorHeight - Float(0.1), 0) // Slightly below room level
            floorNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
            floorNode.name = "heatmap_floor_\(floor)"
            
            scene.rootNode.addChildNode(floorNode)
            
            // Add a thick solid floor platform for better visual definition
            let floorPlatform = SCNBox(width: 18, height: 0.3, length: 18, chamferRadius: 0.1)
            floorPlatform.firstMaterial?.diffuse.contents = floorColor.withAlphaComponent(0.6)
            floorPlatform.firstMaterial?.specular.contents = UIColor.white.withAlphaComponent(0.2)
            floorPlatform.firstMaterial?.roughness.contents = 0.3
            
            let floorPlatformNode = SCNNode(geometry: floorPlatform)
            floorPlatformNode.position = SCNVector3(0, floorHeight - Float(0.3), 0) // Platform below heatmap
            floorPlatformNode.name = "floor_platform_\(floor)"
            
            scene.rootNode.addChildNode(floorPlatformNode)
            
            // Add large central floor number for clear identification
            let floorNumberGeometry = SCNText(string: "FLOOR \(floor)", extrusionDepth: 0.2)
            floorNumberGeometry.font = UIFont.boldSystemFont(ofSize: 2.0)
            floorNumberGeometry.firstMaterial?.diffuse.contents = UIColor.white
            floorNumberGeometry.firstMaterial?.emission.contents = floorColor.withAlphaComponent(0.8)
            floorNumberGeometry.firstMaterial?.specular.contents = UIColor.white.withAlphaComponent(0.5)
            
            let floorNumberNode = SCNNode(geometry: floorNumberGeometry)
            // Center the text
            let textBounds = floorNumberGeometry.boundingBox
            let textWidth = textBounds.max.x - textBounds.min.x
            let textHeight = textBounds.max.y - textBounds.min.y
            floorNumberNode.position = SCNVector3(-textWidth/2, floorHeight + Float(0.2), -textHeight/2)
            floorNumberNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0) // Lay flat on floor
            floorNumberNode.name = "floor_number_\(floor)"
            
            scene.rootNode.addChildNode(floorNumberNode)
            
            // Add subtle grid overlay for reference
            let gridPlane = SCNPlane(width: 15, height: 15)
            let gridImage = createSubtleGridTexture()
            gridPlane.firstMaterial?.diffuse.contents = gridImage
            gridPlane.firstMaterial?.transparency = 0.8
            gridPlane.firstMaterial?.isDoubleSided = true
            
            let gridNode = SCNNode(geometry: gridPlane)
            gridNode.position = SCNVector3(0, floorHeight - 0.05, 0) // Slightly above heatmap
            gridNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
            gridNode.name = "grid_floor_\(floor)"
            
            scene.rootNode.addChildNode(gridNode)
            
            // Add floating floor label with improved design
            createPolishedFloorLabel(for: floor, in: scene)
            
            // Add room boundary outlines if layout data is available
            if let layoutData = layoutData {
                addSubtleRoomOutlines(for: floor, layoutData: layoutData, in: scene)
            }
            
            // Add floor structure visualization for multi-floor buildings
            if floors.count > 1 {
                addFloorStructureElements(for: floor, totalFloors: floors.count, in: scene)
            }
            
            print("✅ Added enhanced layered floor plane for floor \(floor) at height \(floorHeight)")
        }
    }
    
    private func addFloorStructureElements(for floor: Int, totalFloors: Int, in scene: SCNScene) {
        let floorHeight = Float(floor - 1) * Float(4.0)
        
        // Add ceiling/platform above this floor (except for top floor)
        if floor < totalFloors {
            let ceilingGeometry = SCNBox(width: 18, height: 0.2, length: 18, chamferRadius: 0.05)
            ceilingGeometry.firstMaterial?.diffuse.contents = UIColor.darkGray.withAlphaComponent(0.4)
            ceilingGeometry.firstMaterial?.specular.contents = UIColor.white.withAlphaComponent(0.3)
            ceilingGeometry.firstMaterial?.roughness.contents = 0.2
            
            let ceilingNode = SCNNode(geometry: ceilingGeometry)
            ceilingNode.position = SCNVector3(0, floorHeight + Float(3.8), 0) // Near top of this floor
            ceilingNode.name = "ceiling_\(floor)"
            
            scene.rootNode.addChildNode(ceilingNode)
        }
        
        // Add structural pillars at corners for visual support
        let pillarPositions = [
            SCNVector3(-6, floorHeight + Float(2.0), -6),
            SCNVector3(-6, floorHeight + Float(2.0), 6),
            SCNVector3(6, floorHeight + Float(2.0), -6),
            SCNVector3(6, floorHeight + Float(2.0), 6)
        ]
        
        for position in pillarPositions {
            let pillar = SCNCylinder(radius: 0.15, height: 4.0)
            let floorColor = floorColorForLevel(floor)
            pillar.firstMaterial?.diffuse.contents = floorColor.withAlphaComponent(0.3)
            pillar.firstMaterial?.emission.contents = floorColor.withAlphaComponent(0.1)
            pillar.firstMaterial?.transparency = 0.6
            
            let pillarNode = SCNNode(geometry: pillar)
            pillarNode.position = position
            pillarNode.name = "pillar_floor_\(floor)"
            
            scene.rootNode.addChildNode(pillarNode)
        }
        
        // Add floor edge indicators for better depth perception
        if floor > 1 {
            let edgeGeometry = SCNBox(width: 15.5, height: 0.1, length: 15.5, chamferRadius: 0.05)
            let floorColor = floorColorForLevel(floor)
            edgeGeometry.firstMaterial?.diffuse.contents = floorColor.withAlphaComponent(0.4)
            edgeGeometry.firstMaterial?.emission.contents = floorColor.withAlphaComponent(0.2)
            
            let edgeNode = SCNNode(geometry: edgeGeometry)
            edgeNode.position = SCNVector3(0, floorHeight - 0.2, 0)
            edgeNode.name = "edge_floor_\(floor)"
            
            scene.rootNode.addChildNode(edgeNode)
        }
        
        // Add vertical connection indicators between floors
        if floor < totalFloors {
            let connectionHeight = Float(4.0)
            let connectionGeometry = SCNCylinder(radius: 0.05, height: CGFloat(connectionHeight))
            let connectionColor = floorColorForLevel(floor)
            connectionGeometry.firstMaterial?.diffuse.contents = connectionColor.withAlphaComponent(0.5)
            connectionGeometry.firstMaterial?.emission.contents = connectionColor.withAlphaComponent(0.3)
            
            // Add connections at multiple points for better visual continuity
            let connectionPositions = [
                SCNVector3(0, floorHeight + connectionHeight / Float(2.0), 0),
                SCNVector3(-4, floorHeight + connectionHeight / Float(2.0), 0),
                SCNVector3(4, floorHeight + connectionHeight / Float(2.0), 0),
                SCNVector3(0, floorHeight + connectionHeight / Float(2.0), -4),
                SCNVector3(0, floorHeight + connectionHeight / Float(2.0), 4)
            ]
            
            for position in connectionPositions {
                let connectionNode = SCNNode(geometry: connectionGeometry)
                connectionNode.position = position
                connectionNode.name = "connection_floor_\(floor)_to_\(floor + 1)"
                
                scene.rootNode.addChildNode(connectionNode)
            }
        }
    }
    
    private func createContinuousHeatmapTexture(for floor: Int) -> UIImage {
        let size = CGSize(width: 512, height: 512)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Dark base
            cgContext.setFillColor(UIColor.black.withAlphaComponent(0.05).cgColor)
            cgContext.fill(CGRect(origin: .zero, size: size))
            
            // Get locations for this floor
            let floorLocations = calibratedLocations.filter { $0.floor == floor }
            
            // Create smooth heatmap by blending multiple gradients
            for location in floorLocations {
                let position = getRoomPosition(for: location)
                let centerX = (CGFloat(position.x) + 7.5) / 15.0 * size.width // Normalize to texture space
                let centerY = (CGFloat(position.z) + 7.5) / 15.0 * size.height
                let center = CGPoint(x: centerX, y: centerY)
                
                // Radius based on signal strength
                let maxRadius = 150.0 * location.signalStrength + 50.0
                
                let colors = gradientColorsForSignal(location.signalStrength)
                let colorSpace = CGColorSpaceCreateDeviceRGB()
                let gradientColors = [
                    colors.primary.withAlphaComponent(0.6).cgColor,
                    colors.primary.withAlphaComponent(0.3).cgColor,
                    colors.primary.withAlphaComponent(0.1).cgColor,
                    UIColor.clear.cgColor
                ] as CFArray
                
                let locations: [CGFloat] = [0.0, 0.4, 0.7, 1.0]
                
                if let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors, locations: locations) {
                    cgContext.drawRadialGradient(
                        gradient,
                        startCenter: center,
                        startRadius: 0,
                        endCenter: center,
                        endRadius: maxRadius,
                        options: []
                    )
                }
            }
        }
    }
    
    private func createSubtleGridTexture() -> UIImage {
        let size = CGSize(width: 512, height: 512)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Very subtle grid lines
            cgContext.setStrokeColor(UIColor.white.withAlphaComponent(0.1).cgColor)
            cgContext.setLineWidth(0.5)
            
            let gridSpacing: CGFloat = 64
            
            // Vertical lines
            for x in stride(from: 0, through: size.width, by: gridSpacing) {
                cgContext.move(to: CGPoint(x: x, y: 0))
                cgContext.addLine(to: CGPoint(x: x, y: size.height))
            }
            
            // Horizontal lines
            for y in stride(from: 0, through: size.height, by: gridSpacing) {
                cgContext.move(to: CGPoint(x: 0, y: y))
                cgContext.addLine(to: CGPoint(x: size.width, y: y))
            }
            
            cgContext.strokePath()
        }
    }
    
    private func createGridTexture() -> UIImage {
        let size = CGSize(width: 512, height: 512)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Dark background
            cgContext.setFillColor(UIColor.black.withAlphaComponent(0.1).cgColor)
            cgContext.fill(CGRect(origin: .zero, size: size))
            
            // Grid lines
            cgContext.setStrokeColor(UIColor.cyan.withAlphaComponent(0.3).cgColor)
            cgContext.setLineWidth(1.0)
            
            let gridSpacing: CGFloat = 32
            
            // Vertical lines
            for x in stride(from: 0, through: size.width, by: gridSpacing) {
                cgContext.move(to: CGPoint(x: x, y: 0))
                cgContext.addLine(to: CGPoint(x: x, y: size.height))
            }
            
            // Horizontal lines
            for y in stride(from: 0, through: size.height, by: gridSpacing) {
                cgContext.move(to: CGPoint(x: 0, y: y))
                cgContext.addLine(to: CGPoint(x: size.width, y: y))
            }
            
            cgContext.strokePath()
        }
    }
    
    private func floorColorForLevel(_ floor: Int) -> UIColor {
        let colors: [UIColor] = [
            UIColor.systemBlue.withAlphaComponent(0.8),     // Floor 1 - Blue
            UIColor.systemGreen.withAlphaComponent(0.8),    // Floor 2 - Green
            UIColor.systemPurple.withAlphaComponent(0.8),   // Floor 3 - Purple
            UIColor.systemOrange.withAlphaComponent(0.8),   // Floor 4+ - Orange
        ]
        return colors[min(floor - 1, colors.count - 1)]
    }
    
    private func createPolishedFloorLabel(for floor: Int, in scene: SCNScene) {
        // Create modern glass-style background card
        let cardGeometry = SCNPlane(width: 3.0, height: 1.0)
        cardGeometry.firstMaterial?.diffuse.contents = createGlassBackgroundTexture()
        cardGeometry.firstMaterial?.transparency = 0.2
        
        let cardNode = SCNNode(geometry: cardGeometry)
        cardNode.position = SCNVector3(-6, Float(floor - 1) * Float(4.0) + Float(0.8), -6)
        cardNode.constraints = [SCNBillboardConstraint()]
        
        // Add subtle border glow
        let borderGeometry = SCNPlane(width: 3.1, height: 1.1)
        borderGeometry.firstMaterial?.diffuse.contents = floorColorForLevel(floor).withAlphaComponent(0.3)
        borderGeometry.firstMaterial?.transparency = 0.7
        
        let borderNode = SCNNode(geometry: borderGeometry)
        borderNode.position = SCNVector3(0, 0, -0.001)
        cardNode.addChildNode(borderNode)
        
        // Floor number with SF Symbol style
        let floorText = SCNText(string: "🏢 Floor \(floor)", extrusionDepth: 0.03)
        floorText.firstMaterial?.diffuse.contents = UIColor.white
        floorText.firstMaterial?.emission.contents = floorColorForLevel(floor).withAlphaComponent(0.4)
        floorText.font = UIFont.systemFont(ofSize: 0.35, weight: .bold)
        
        let textNode = SCNNode(geometry: floorText)
        textNode.position = SCNVector3(-1.2, -0.1, 0.002)
        
        cardNode.addChildNode(textNode)
        scene.rootNode.addChildNode(cardNode)
    }
    
    private func addSubtleRoomOutlines(for floor: Int, layoutData: RoomLayoutData, in scene: SCNScene) {
        let roomsOnFloor = layoutData.rooms.filter { $0.floor == floor }
        
        for room in roomsOnFloor {
            // Create very subtle outline boxes
            let outline = SCNBox(width: CGFloat(room.size.width / 30), 
                               height: 0.05, // Much thinner
                               length: CGFloat(room.size.height / 30), 
                               chamferRadius: 0.02)
            
            outline.firstMaterial?.diffuse.contents = UIColor.clear
            outline.firstMaterial?.specular.contents = floorColorForLevel(floor).withAlphaComponent(0.3)
            outline.firstMaterial?.emission.contents = floorColorForLevel(floor).withAlphaComponent(0.1)
            outline.firstMaterial?.transparency = 0.7
            
            let outlineNode = SCNNode(geometry: outline)
            let roomPos = getRoomPosition(for: room.calibratedLocation)
            outlineNode.position = SCNVector3(roomPos.x, roomPos.y - 0.1, roomPos.z) // Slightly below room level
            
            scene.rootNode.addChildNode(outlineNode)
        }
    }
    
    private func createEnhancedRoomNode(for location: CalibratedLocation) -> SCNNode {
        let position = getRoomPosition(for: location)
        
        // Create main sphere with smooth gradient materials
        let radius = 0.3 + (location.signalStrength * 0.4) // Reduced size for subtlety
        let sphere = SCNSphere(radius: CGFloat(radius))
        
        // Enhanced smooth gradient materials
        let colors = gradientColorsForSignal(location.signalStrength)
        sphere.firstMaterial?.diffuse.contents = createSmoothGradientTexture(for: location.signalStrength)
        sphere.firstMaterial?.emission.contents = colors.emission
        sphere.firstMaterial?.specular.contents = UIColor.white.withAlphaComponent(0.6)
        sphere.firstMaterial?.shininess = 80
        
        // Enhanced material properties for smooth appearance
        sphere.firstMaterial?.metalness.contents = 0.2
        sphere.firstMaterial?.roughness.contents = 0.1
        sphere.firstMaterial?.transparency = 0.85 // More transparent for subtlety
        
        let roomNode = SCNNode(geometry: sphere)
        roomNode.position = position
        roomNode.name = location.id.uuidString
        
        // Add subtle glow effect (reduced intensity)
        addSubtleGlowEffect(to: roomNode, radius: Float(radius), strength: location.signalStrength)
        
        // Add gentle pulsing animation for weak signals
        if location.signalStrength < 0.5 {
            addGentlePulsingAnimation(to: roomNode)
        } else if location.signalStrength > 0.8 {
            // Strong signals get subtle rotation
            addSubtleSignalAnimation(to: roomNode)
        }
        
        // Add refined particle effects (much more subtle)
        addRefinedSignalParticles(to: roomNode, strength: location.signalStrength)
        
        // Add enhanced floating label with improved visibility
        addPolishedRoomLabel(to: roomNode, location: location, radius: Float(radius))
        
        // Add selection highlight if selected
        if selectedRoom?.id == location.id {
            addEnhancedSelectionHighlight(to: roomNode, radius: Float(radius))
        }
        
        return roomNode
    }
    
    private func gradientColorsForSignal(_ strength: Double) -> (primary: UIColor, emission: UIColor) {
        switch strength {
        case 0.8...1.0:
            // Strong: Bright green with blue hints
            return (
                UIColor(red: 0.2, green: 0.9, blue: 0.3, alpha: 1.0),
                UIColor(red: 0.1, green: 0.8, blue: 0.2, alpha: 0.6)
            )
        case 0.6..<0.8:
            // Good: Green-yellow gradient
            return (
                UIColor(red: 0.7, green: 0.9, blue: 0.2, alpha: 1.0),
                UIColor(red: 0.6, green: 0.8, blue: 0.1, alpha: 0.5)
            )
        case 0.4..<0.6:
            // Medium: Yellow-orange gradient
            return (
                UIColor(red: 1.0, green: 0.7, blue: 0.2, alpha: 1.0),
                UIColor(red: 0.9, green: 0.6, blue: 0.1, alpha: 0.4)
            )
        case 0.2..<0.4:
            // Weak: Orange-red gradient
            return (
                UIColor(red: 1.0, green: 0.4, blue: 0.2, alpha: 1.0),
                UIColor(red: 0.9, green: 0.3, blue: 0.1, alpha: 0.3)
            )
        default:
            // Very weak: Deep red
            return (
                UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0),
                UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 0.2)
            )
        }
    }
    
    private func createSmoothGradientTexture(for strength: Double) -> UIImage {
        let size = CGSize(width: 256, height: 256)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            let colors = gradientColorsForSignal(strength)
            
            // Create radial gradient from center to edge
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2
            
            // Create gradient colors array
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradientColors = [
                colors.primary.cgColor,
                colors.primary.withAlphaComponent(0.8).cgColor,
                colors.primary.withAlphaComponent(0.4).cgColor,
                colors.primary.withAlphaComponent(0.1).cgColor
            ] as CFArray
            
            let locations: [CGFloat] = [0.0, 0.3, 0.7, 1.0]
            
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors, locations: locations) {
                cgContext.drawRadialGradient(
                    gradient,
                    startCenter: center,
                    startRadius: 0,
                    endCenter: center,
                    endRadius: radius,
                    options: []
                )
            }
        }
    }
    
    private func addSubtleGlowEffect(to node: SCNNode, radius: Float, strength: Double) {
        // Much more subtle outer glow
        let glowRadius = radius + Float(0.1)
        let glowSphere = SCNSphere(radius: CGFloat(glowRadius))
        
        let colors = gradientColorsForSignal(strength)
        glowSphere.firstMaterial?.diffuse.contents = colors.emission.withAlphaComponent(0.15)
        glowSphere.firstMaterial?.emission.contents = colors.emission.withAlphaComponent(0.2)
        glowSphere.firstMaterial?.transparency = 0.8
        glowSphere.firstMaterial?.writesToDepthBuffer = false
        
        let glowNode = SCNNode(geometry: glowSphere)
        glowNode.name = "glow_effect"
        
        // Very gentle breathing animation
        let breathe = SCNAction.sequence([
            SCNAction.scale(to: 1.05, duration: 3.0),
            SCNAction.scale(to: 0.95, duration: 3.0)
        ])
        let repeatBreathe = SCNAction.repeatForever(breathe)
        glowNode.runAction(repeatBreathe)
        
        node.addChildNode(glowNode)
    }
    
    private func addGentlePulsingAnimation(to node: SCNNode) {
        let fade = SCNAction.sequence([
            SCNAction.fadeOpacity(to: 0.6, duration: 2.0),
            SCNAction.fadeOpacity(to: 1.0, duration: 2.0)
        ])
        let repeatFade = SCNAction.repeatForever(fade)
        node.runAction(repeatFade, forKey: "gentle_pulse")
    }
    
    private func addSubtleSignalAnimation(to node: SCNNode) {
        // Very slow, subtle rotation
        let rotation = SCNAction.rotateBy(x: 0, y: CGFloat(2 * Float.pi), z: 0, duration: 12.0)
        let repeatRotation = SCNAction.repeatForever(rotation)
        node.runAction(repeatRotation, forKey: "subtle_rotation")
        
        // Enhanced but subtle glow pulse
        if let glowNode = node.childNode(withName: "glow_effect", recursively: false) {
            let gentlePulse = SCNAction.sequence([
                SCNAction.fadeOpacity(to: 0.6, duration: 1.5),
                SCNAction.fadeOpacity(to: 0.3, duration: 1.5)
            ])
            let repeatPulse = SCNAction.repeatForever(gentlePulse)
            glowNode.runAction(repeatPulse, forKey: "gentle_glow_pulse")
        }
    }
    
    private func addRefinedSignalParticles(to node: SCNNode, strength: Double) {
        // Much more refined and subtle particle system
        let particleSystem = SCNParticleSystem()
        particleSystem.birthRate = 3 * strength // Greatly reduced
        particleSystem.particleLifeSpan = 4.0
        particleSystem.particleSize = 0.02 // Much smaller
        particleSystem.particleVelocity = 0.8 // Slower movement
        particleSystem.particleVelocityVariation = 0.4
        particleSystem.emissionDuration = 0
        
        // Soft, subtle colors
        let colors = gradientColorsForSignal(strength)
        particleSystem.particleColor = colors.emission.withAlphaComponent(0.4) // More transparent
        particleSystem.particleColorVariation = SCNVector4(0.1, 0.1, 0.1, 0.0)
        
        // Gentle upward flow like signal waves
        particleSystem.emittingDirection = SCNVector3(0, 1, 0)
        particleSystem.spreadingAngle = 25 // More focused
        
        // Use circular/soft particles
        let particleImage = createSoftParticleTexture()
        particleSystem.particleImage = particleImage
        
        // Attach to node at a higher position to avoid covering labels
        let particleNode = SCNNode()
        particleNode.position = SCNVector3(0, 0.2, 0) // Offset upward
        particleNode.addParticleSystem(particleSystem)
        
        node.addChildNode(particleNode)
    }
    
    private func createSoftParticleTexture() -> UIImage {
        let size = CGSize(width: 32, height: 32)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Create soft circular gradient
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2
            
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [
                UIColor.white.cgColor,
                UIColor.white.withAlphaComponent(0.8).cgColor,
                UIColor.white.withAlphaComponent(0.2).cgColor,
                UIColor.clear.cgColor
            ] as CFArray
            
            let locations: [CGFloat] = [0.0, 0.3, 0.7, 1.0]
            
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
                cgContext.drawRadialGradient(
                    gradient,
                    startCenter: center,
                    startRadius: 0,
                    endCenter: center,
                    endRadius: radius,
                    options: []
                )
            }
        }
    }
    
    private func addPolishedRoomLabel(to node: SCNNode, location: CalibratedLocation, radius: Float) {
        // Create polished background card with glass effect
        let cardWidth: CGFloat = 2.2
        let cardHeight: CGFloat = 0.9
        let cardGeometry = SCNPlane(width: cardWidth, height: cardHeight)
        
        // Glass morphism background with better visibility
        cardGeometry.firstMaterial?.diffuse.contents = createGlassBackgroundTexture()
        cardGeometry.firstMaterial?.emission.contents = UIColor.black.withAlphaComponent(0.1)
        cardGeometry.firstMaterial?.transparency = 0.15
        
        let cardNode = SCNNode(geometry: cardGeometry)
        cardNode.position = SCNVector3(0, radius + 1.2, 0) // Higher position
        cardNode.constraints = [SCNBillboardConstraint()]
        
        // Add subtle drop shadow plane behind
        let shadowGeometry = SCNPlane(width: cardWidth + 0.1, height: cardHeight + 0.1)
        shadowGeometry.firstMaterial?.diffuse.contents = UIColor.black.withAlphaComponent(0.3)
        shadowGeometry.firstMaterial?.transparency = 0.7
        
        let shadowNode = SCNNode(geometry: shadowGeometry)
        shadowNode.position = SCNVector3(0.02, -0.02, -0.001) // Slight offset for shadow
        cardNode.addChildNode(shadowNode)
        
        // Room name text with better contrast
        let nameText = SCNText(string: location.name, extrusionDepth: 0.01)
        nameText.firstMaterial?.diffuse.contents = UIColor.white
        nameText.firstMaterial?.emission.contents = UIColor.white.withAlphaComponent(0.4)
        nameText.font = UIFont.systemFont(ofSize: 0.22, weight: .semibold)
        
        let nameNode = SCNNode(geometry: nameText)
        nameNode.position = SCNVector3(-0.9, 0.15, 0.002)
        cardNode.addChildNode(nameNode)
        
        // Signal strength with SF Symbol-like icon
        let strengthPercentage = Int(location.signalStrength * 100)
        let signalIcon = getSignalIcon(for: location.signalStrength)
        let strengthText = SCNText(string: "\(signalIcon) \(strengthPercentage)%", extrusionDepth: 0.01)
        
        let colors = gradientColorsForSignal(location.signalStrength)
        strengthText.firstMaterial?.diffuse.contents = colors.primary
        strengthText.firstMaterial?.emission.contents = colors.emission.withAlphaComponent(0.3)
        strengthText.font = UIFont.systemFont(ofSize: 0.18, weight: .bold)
        
        let strengthNode = SCNNode(geometry: strengthText)
        strengthNode.position = SCNVector3(-0.9, -0.15, 0.002)
        cardNode.addChildNode(strengthNode)
        
        // Add subtle glow to the entire card
        let cardGlow = SCNPlane(width: cardWidth + 0.2, height: cardHeight + 0.2)
        cardGlow.firstMaterial?.diffuse.contents = colors.emission.withAlphaComponent(0.1)
        cardGlow.firstMaterial?.transparency = 0.9
        cardGlow.firstMaterial?.writesToDepthBuffer = false
        
        let glowNode = SCNNode(geometry: cardGlow)
        glowNode.position = SCNVector3(0, 0, -0.002)
        cardNode.addChildNode(glowNode)
        
        node.addChildNode(cardNode)
    }
    
    private func createGlassBackgroundTexture() -> UIImage {
        let size = CGSize(width: 256, height: 128)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Glass morphism background
            cgContext.setFillColor(UIColor.black.withAlphaComponent(0.6).cgColor)
            cgContext.fill(CGRect(origin: .zero, size: size))
            
            // Add subtle border
            cgContext.setStrokeColor(UIColor.white.withAlphaComponent(0.2).cgColor)
            cgContext.setLineWidth(2.0)
            cgContext.stroke(CGRect(origin: .zero, size: size))
            
            // Add subtle inner glow
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 3
            
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [
                UIColor.white.withAlphaComponent(0.1).cgColor,
                UIColor.clear.cgColor
            ] as CFArray
            
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0]) {
                cgContext.drawRadialGradient(
                    gradient,
                    startCenter: center,
                    startRadius: 0,
                    endCenter: center,
                    endRadius: radius,
                    options: []
                )
            }
        }
    }
    
    private func getSignalIcon(for strength: Double) -> String {
        switch strength {
        case 0.8...1.0:
            return "📶" // Excellent
        case 0.6..<0.8:
            return "📶" // Good
        case 0.4..<0.6:
            return "📶" // Fair
        case 0.2..<0.4:
            return "📵" // Poor
        default:
            return "📵" // Very Poor
        }
    }
    
    private func addEnhancedSelectionHighlight(to node: SCNNode, radius: Float) {
        // Animated selection rings
        for i in 0..<3 {
            let ringRadius = radius + Float(0.3) + (Float(i) * Float(0.2))
            let ring = SCNTorus(ringRadius: CGFloat(ringRadius), pipeRadius: 0.03)
            ring.firstMaterial?.diffuse.contents = UIColor.cyan
            ring.firstMaterial?.emission.contents = UIColor.cyan.withAlphaComponent(0.8)
            ring.firstMaterial?.transparency = 0.7
            
            let ringNode = SCNNode(geometry: ring)
            ringNode.name = "selection_ring_\(i)"
            
            // Staggered rotation animations
            let rotation = SCNAction.rotateBy(x: 0, y: CGFloat(2 * Float.pi), z: 0, duration: 2.0 + Double(i))
            let repeatRotation = SCNAction.repeatForever(rotation)
            
            // Pulsing scale
            let scale = SCNAction.sequence([
                SCNAction.scale(to: 1.1, duration: 1.0),
                SCNAction.scale(to: 0.9, duration: 1.0)
            ])
            let repeatScale = SCNAction.repeatForever(scale)
            
            let group = SCNAction.group([repeatRotation, repeatScale])
            ringNode.runAction(group)
            
            node.addChildNode(ringNode)
        }
    }
    
    private func getRoomPosition(for location: CalibratedLocation) -> SCNVector3 {
        if let layoutData = layoutData,
           let room = layoutData.rooms.first(where: { $0.calibratedLocation.id == location.id }) {
            // Convert 2D layout position to 3D, constrained within house bounds
            let x = (room.position.x - 150) / 30 // Scale and center
            let z = (room.position.y - 200) / 30 // Scale and center
            let y = Float(location.floor - 1) * Float(4.0) + Float(1.5) // Floor height + room height
            
            // Constrain within house boundaries (-9 to 9 for safety margin)
            let constrainedX = max(-9, min(9, Float(x)))
            let constrainedZ = max(-9, min(9, Float(z)))
            
            return SCNVector3(constrainedX, y, constrainedZ)
        } else {
            // Position rooms in realistic house locations
            let y = Float(location.floor - 1) * Float(4.0) + Float(1.5) // Floor height + room height
            
            // Create realistic room positions based on room name
            let position = getRealisticRoomPosition(for: location.name, floor: location.floor)
            return SCNVector3(position.x, y, position.z)
        }
    }
    
    private func getRealisticRoomPosition(for roomName: String, floor: Int) -> SCNVector3 {
        let roomName = roomName.lowercased()
        
        // Define realistic room positions within house bounds (-9 to 9)
        if roomName.contains("living") || roomName.contains("lounge") {
            return SCNVector3(-4, 0, 4) // Front left
        } else if roomName.contains("kitchen") {
            return SCNVector3(4, 0, 4) // Front right
        } else if roomName.contains("bedroom") || roomName.contains("master") {
            return SCNVector3(-4, 0, -4) // Back left
        } else if roomName.contains("bathroom") || roomName.contains("bath") {
            return SCNVector3(4, 0, -4) // Back right
        } else if roomName.contains("dining") {
            return SCNVector3(0, 0, 6) // Front center
        } else if roomName.contains("office") || roomName.contains("study") {
            return SCNVector3(-6, 0, 0) // Left center
        } else if roomName.contains("garage") {
            return SCNVector3(6, 0, 0) // Right center
        } else if roomName.contains("hallway") || roomName.contains("corridor") {
            return SCNVector3(0, 0, 0) // Center
        } else {
            // Random but consistent position for unknown rooms
            let hash = roomName.hash
            let x = Float((hash % 1600) - 800) / 100 // Range -8 to 8
            let z = Float(((hash / 1000) % 1600) - 800) / 100 // Range -8 to 8
            return SCNVector3(x, 0, z)
        }
    }
    
    private func colorForSignalStrength(_ strength: Double) -> UIColor {
        // Keep this method for backward compatibility
        return gradientColorsForSignal(strength).primary
    }
    
    private func addEnhancedSignalLines(to scene: SCNScene, for locations: [CalibratedLocation]) {
        // Connect rooms with enhanced signal lines
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
                    if distance < 4.0 && signalAverage > 0.3 {
                        let line = createEnhancedSignalLine(from: pos1, to: pos2, strength: signalAverage)
                        scene.rootNode.addChildNode(line)
                    }
                }
            }
        }
    }
    
    private func createEnhancedSignalLine(from start: SCNVector3, to end: SCNVector3, strength: Double) -> SCNNode {
        let vector = SCNVector3(end.x - start.x, end.y - start.y, end.z - start.z)
        let distance = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
        
        // Create animated signal beam
        let cylinder = SCNCylinder(radius: 0.03, height: CGFloat(distance))
        let colors = gradientColorsForSignal(strength)
        
        cylinder.firstMaterial?.diffuse.contents = colors.primary.withAlphaComponent(0.6)
        cylinder.firstMaterial?.emission.contents = colors.emission.withAlphaComponent(0.8)
        cylinder.firstMaterial?.transparency = 0.7
        cylinder.firstMaterial?.writesToDepthBuffer = false
        
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
        
        // Add pulsing animation for data flow effect
        let pulse = SCNAction.sequence([
            SCNAction.fadeOpacity(to: 0.3, duration: 1.0),
            SCNAction.fadeOpacity(to: 1.0, duration: 1.0)
        ])
        let repeatPulse = SCNAction.repeatForever(pulse)
        lineNode.runAction(repeatPulse)
        
        return lineNode
    }
    
    private func addEnhancedLighting(to scene: SCNScene) {
        print("💡 Adding enhanced lighting to scene")
        
        // Enhanced ambient light with subtle color
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = UIColor(red: 0.4, green: 0.4, blue: 0.6, alpha: 1.0)
        ambientLight.intensity = 300
        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        scene.rootNode.addChildNode(ambientNode)
        
        // Main directional light
        let directionalLight = SCNLight()
        directionalLight.type = .directional
        directionalLight.color = UIColor.white
        directionalLight.intensity = 1000
        directionalLight.castsShadow = true
        directionalLight.shadowMode = .deferred
        directionalLight.shadowRadius = 10
        directionalLight.shadowMapSize = CGSize(width: 2048, height: 2048)
        directionalLight.shadowColor = UIColor.black.withAlphaComponent(0.3)
        
        let directionalNode = SCNNode()
        directionalNode.light = directionalLight
        directionalNode.position = SCNVector3(8, 12, 8)
        directionalNode.look(at: SCNVector3(0, 2, 0))
        scene.rootNode.addChildNode(directionalNode)
        
        // Accent spotlight for drama
        let spotLight = SCNLight()
        spotLight.type = .spot
        spotLight.color = UIColor.cyan
        spotLight.intensity = 500
        spotLight.spotInnerAngle = 30
        spotLight.spotOuterAngle = 60
        
        let spotNode = SCNNode()
        spotNode.light = spotLight
        spotNode.position = SCNVector3(0, 10, 0)
        spotNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(spotNode)
        
        print("✅ Added enhanced ambient, directional, and spot lighting")
    }
    
    private func addAmbientParticles(to scene: SCNScene) {
        // Add floating ambient particles for atmosphere
        let particleSystem = SCNParticleSystem()
        particleSystem.birthRate = 5
        particleSystem.particleLifeSpan = 20.0
        particleSystem.particleSize = 0.02
        particleSystem.particleVelocity = 0.5
        particleSystem.particleVelocityVariation = 0.3
        particleSystem.emissionDuration = 0
        
        // Subtle blue particles
        particleSystem.particleColor = UIColor.cyan.withAlphaComponent(0.3)
        particleSystem.particleColorVariation = SCNVector4(0.2, 0.2, 0.2, 0.2)
        
        // Floating upward
        particleSystem.emittingDirection = SCNVector3(0, 1, 0)
        particleSystem.spreadingAngle = 180
        
        // Create emitter node
        let emitterNode = SCNNode()
        emitterNode.position = SCNVector3(0, -2, 0)
        emitterNode.addParticleSystem(particleSystem)
        
        scene.rootNode.addChildNode(emitterNode)
    }
    
    // Set initial camera position only once
    private func setupInitialCamera(_ sceneView: SCNView) {
        setupEnhancedCamera(sceneView)
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
        
        // Create enhanced floor planes
        createEnhancedFloorPlanes(in: scene)
        
        // Create enhanced room nodes
        for location in locations {
            let roomNode = createEnhancedRoomNode(for: location)
            scene.rootNode.addChildNode(roomNode)
        }
        
        // Add enhanced signal lines if enabled
        if showSignalLines {
            addEnhancedSignalLines(to: scene, for: locations)
        }
        
        // Add enhanced lighting
        addEnhancedLighting(to: scene)
        
        // Add ambient particles
        addAmbientParticles(to: scene)
        
        print("🔄 Enhanced scene content updated")
    }
    
    private func updateCamera(_ sceneView: SCNView) {
        guard let camera = sceneView.pointOfView else { return }
        
        // Calculate building height for better camera positioning
        let floors = Set(calibratedLocations.map { $0.floor }).sorted()
        let maxFloor = floors.max() ?? 1
        let buildingHeight = Float(maxFloor - 1) * Float(4.0)
        let centerHeight = buildingHeight / Float(2.0) + Float(2.0)
        
        switch cameraMode {
        case .overview:
            // Adjust overview based on building height
            let cameraDistance: Float = maxFloor > 1 ? 16 : 12
            let cameraHeight: Float = maxFloor > 1 ? centerHeight + 8 : 12
            camera.position = SCNVector3(cameraDistance, cameraHeight, cameraDistance)
            camera.look(at: SCNVector3(0, centerHeight, 0))
        case .floor:
            let currentFloor = filterFloor ?? 1
            let floorHeight = Float(currentFloor - 1) * Float(4.0)
            camera.position = SCNVector3(0, floorHeight + Float(6), Float(8))
            camera.look(at: SCNVector3(0, floorHeight, 0))
        case .signal:
            camera.position = SCNVector3(15, centerHeight + 4, 0)
            camera.look(at: SCNVector3(0, centerHeight, 0))
        case .router:
            let topHeight = buildingHeight + 8
            camera.position = SCNVector3(0, topHeight, 0)
            camera.look(at: SCNVector3(0, centerHeight, 0))
        }
        
        // Animate camera transition
        let moveAction = SCNAction.move(to: camera.position, duration: 1.5)
        moveAction.timingMode = .easeInEaseOut
        camera.runAction(moveAction)
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

struct EnhancedControlsPanel: View {
    @Binding var showSignalLines: Bool
    let totalRooms: Int
    
    var body: some View {
        VStack(spacing: 16) {
            // Title Section with SF Symbols
            HStack {
                Image(systemName: "cube.transparent.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("3D WiFi Visualization")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    HStack {
                        Image(systemName: "wifi.router.fill")
                            .font(.caption)
                            .foregroundColor(.cyan)
                        Text("\(totalRooms) rooms analyzed")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
            }
            
            Divider()
                .background(Color.gray.opacity(0.3))
            
            // Controls Section with improved styling
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                            .font(.caption)
                            .foregroundColor(.cyan)
                        Text("Display Options")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    
                    HStack {
                        Toggle("", isOn: $showSignalLines)
                            .toggleStyle(SwitchToggleStyle(tint: .cyan))
                            .labelsHidden()
                        
                        HStack {
                            Image(systemName: "line.3.connected")
                                .font(.caption2)
                                .foregroundColor(.cyan)
                            Text("Signal Connections")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                    }
                }
                
                Spacer()
                
                // Enhanced Signal Legend with SF Symbols
                VStack(alignment: .trailing, spacing: 6) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .font(.caption)
                            .foregroundColor(.cyan)
                        Text("Signal Strength")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    
                    // Gradient bar legend with better styling
                    HStack(spacing: 4) {
                        VStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(LinearGradient(
                                    colors: [
                                        Color(red: 0.9, green: 0.2, blue: 0.2),
                                        Color(red: 1.0, green: 0.4, blue: 0.2),
                                        Color(red: 1.0, green: 0.7, blue: 0.2),
                                        Color(red: 0.7, green: 0.9, blue: 0.2),
                                        Color(red: 0.2, green: 0.9, blue: 0.3)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .frame(width: 70, height: 12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                                )
                            
                            HStack {
                                Text("0%")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("100%")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 70)
                        }
                        
                        VStack(spacing: 2) {
                            ForEach(0..<5) { index in
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(strengthColor(for: index))
                            }
                        }
                    }
                    
                    // Signal quality indicators with SF Symbols
                    VStack(alignment: .trailing, spacing: 2) {
                        SignalIndicatorRow(icon: "wifi", label: "Excellent", color: .green)
                        SignalIndicatorRow(icon: "wifi", label: "Good", color: .yellow)
                        SignalIndicatorRow(icon: "wifi", label: "Fair", color: .orange)
                        SignalIndicatorRow(icon: "wifi.slash", label: "Poor", color: .red)
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [.cyan.opacity(0.5), .blue.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(0.4), radius: 15, x: 0, y: 5)
    }
    
    private func strengthColor(for index: Int) -> Color {
        let colors: [Color] = [
            .red,      // 0-20%
            .orange,   // 20-40%
            .yellow,   // 40-60%
            Color(red: 0.7, green: 0.9, blue: 0.2), // 60-80%
            .green     // 80-100%
        ]
        return colors[index]
    }
}

struct SignalIndicatorRow: View {
    let icon: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(color)
        }
    }
}

struct ControlsPanel: View {
    @Binding var showSignalLines: Bool
    let totalRooms: Int
    
    var body: some View {
        EnhancedControlsPanel(showSignalLines: $showSignalLines, totalRooms: totalRooms)
    }
    }
    
    private func addTransparentHouseStructure(to scene: SCNScene, floors: [Int], environmentType: EnvironmentType?) {
        let maxFloor = floors.max() ?? 1
        let buildingHeight = Float(maxFloor) * Float(4.0)
        
        print("🏠 Creating transparent house structure for \(maxFloor) floor(s)")
        
        // Create house structure based on environment type
        switch environmentType ?? .house {
        case .house:
            createResidentialHouse(in: scene, height: buildingHeight, floors: floors)
        case .office:
            createOfficeBuilding(in: scene, height: buildingHeight, floors: floors)
        case .apartment:
            createApartmentBuilding(in: scene, height: buildingHeight, floors: floors)
        }
        
        // Add wireframe outline for better visibility
        addHouseWireframe(to: scene, height: buildingHeight)
    }
    
    private func createResidentialHouse(in scene: SCNScene, height: Float, floors: [Int]) {
        print("🏠 Creating residential house with height: \(height), floors: \(floors)")
        
        // Main house walls (transparent)
        let wallMaterial = createTransparentWallMaterial(color: UIColor.brown.withAlphaComponent(0.6))
        
        // Front and back walls
        let frontWall = SCNPlane(width: 20, height: CGFloat(height + 2))
        frontWall.firstMaterial = wallMaterial
        
        let frontWallNode = SCNNode(geometry: frontWall)
        frontWallNode.position = SCNVector3(0, height/2, 10)
        frontWallNode.name = "house_front_wall"
        scene.rootNode.addChildNode(frontWallNode)
        print("🧱 Added front wall at: \(frontWallNode.position)")
        
        let backWallNode = SCNNode(geometry: frontWall)
        backWallNode.position = SCNVector3(0, height/2, -10)
        backWallNode.eulerAngles = SCNVector3(0, Float.pi, 0)
        backWallNode.name = "house_back_wall"
        scene.rootNode.addChildNode(backWallNode)
        print("🧱 Added back wall at: \(backWallNode.position)")
        
        // Left and right walls
        let sideWall = SCNPlane(width: 20, height: CGFloat(height + 2))
        sideWall.firstMaterial = wallMaterial
        
        let leftWallNode = SCNNode(geometry: sideWall)
        leftWallNode.position = SCNVector3(-10, height/2, 0)
        leftWallNode.eulerAngles = SCNVector3(0, Float.pi/2, 0)
        leftWallNode.name = "house_left_wall"
        scene.rootNode.addChildNode(leftWallNode)
        
        let rightWallNode = SCNNode(geometry: sideWall)
        rightWallNode.position = SCNVector3(10, height/2, 0)
        rightWallNode.eulerAngles = SCNVector3(0, -Float.pi/2, 0)
        rightWallNode.name = "house_right_wall"
        scene.rootNode.addChildNode(rightWallNode)
        
        // Add roof for house
        createHouseRoof(in: scene, height: height)
        
        // Add windows and doors
        addHouseWindowsAndDoors(to: scene, height: height)
        
        // Add interior room divisions
        addInteriorRoomDivisions(to: scene, height: height, floors: floors)
        
        // Add house outline/wireframe for better visibility
        addHouseWireframe(to: scene, height: height)
    }
    
    private func createOfficeBuilding(in scene: SCNScene, height: Float, floors: [Int]) {
        // Modern office building with glass walls
        let wallMaterial = createTransparentWallMaterial(color: UIColor.blue.withAlphaComponent(0.5))
        
        // Create rectangular office building
        let buildingWidth: Float = 22
        let buildingDepth: Float = 18
        
        // Walls
        let walls = [
            (SCNVector3(0, height/2, buildingDepth/2), SCNVector3(0, 0, 0)), // Front
            (SCNVector3(0, height/2, -buildingDepth/2), SCNVector3(0, Float.pi, 0)), // Back
            (SCNVector3(-buildingWidth/2, height/2, 0), SCNVector3(0, Float.pi/2, 0)), // Left
            (SCNVector3(buildingWidth/2, height/2, 0), SCNVector3(0, -Float.pi/2, 0)) // Right
        ]
        
        for (position, rotation) in walls {
            let wall = SCNPlane(width: CGFloat(max(buildingWidth, buildingDepth)), height: CGFloat(height + 2))
            wall.firstMaterial = wallMaterial
            
            let wallNode = SCNNode(geometry: wall)
            wallNode.position = position
            wallNode.eulerAngles = rotation
            wallNode.name = "office_wall"
            scene.rootNode.addChildNode(wallNode)
        }
        
        // Add office features
        addOfficeFeatures(to: scene, height: height, floors: floors)
    }
    
    private func createApartmentBuilding(in scene: SCNScene, height: Float, floors: [Int]) {
        // Apartment building with concrete-like appearance
        let wallMaterial = createTransparentWallMaterial(color: UIColor.gray.withAlphaComponent(0.5))
        
        let buildingWidth: Float = 24
        let buildingDepth: Float = 16
        
        // Create apartment building walls
        let walls = [
            (SCNVector3(0, height/2, buildingDepth/2), SCNVector3(0, 0, 0)), // Front
            (SCNVector3(0, height/2, -buildingDepth/2), SCNVector3(0, Float.pi, 0)), // Back
            (SCNVector3(-buildingWidth/2, height/2, 0), SCNVector3(0, Float.pi/2, 0)), // Left
            (SCNVector3(buildingWidth/2, height/2, 0), SCNVector3(0, -Float.pi/2, 0)) // Right
        ]
        
        for (position, rotation) in walls {
            let wall = SCNPlane(width: CGFloat(max(buildingWidth, buildingDepth)), height: CGFloat(height + 2))
            wall.firstMaterial = wallMaterial
            
            let wallNode = SCNNode(geometry: wall)
            wallNode.position = position
            wallNode.eulerAngles = rotation
            wallNode.name = "apartment_wall"
            scene.rootNode.addChildNode(wallNode)
        }
        
        // Add apartment features
        addApartmentFeatures(to: scene, height: height, floors: floors)
    }
    
    private func createTransparentWallMaterial(color: UIColor) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = color
        material.transparency = 0.7 // Much more visible
        material.isDoubleSided = true
        material.lightingModel = .constant // Always visible regardless of lighting
        material.specular.contents = UIColor.white.withAlphaComponent(0.5)
        material.roughness.contents = 0.6
        material.emission.contents = color.withAlphaComponent(0.4) // Strong glow for visibility
        material.cullMode = .front // Fix: Use .front instead of .none
        
        print("🏗️ Created wall material with high visibility")
        return material
    }
    
    private func createHouseRoof(in scene: SCNScene, height: Float) {
        // Triangular roof for residential house
        let roofHeight: Float = 3.0
        // Removed unused roofPeak variable
        
        // Create roof geometry using triangular planes
        let roofMaterial = SCNMaterial()
        roofMaterial.diffuse.contents = UIColor.red.withAlphaComponent(0.6)
        roofMaterial.transparency = 0.4
        roofMaterial.isDoubleSided = true
        roofMaterial.emission.contents = UIColor.red.withAlphaComponent(0.1)
        
        // Front roof triangle
        let frontRoof = SCNPlane(width: 20, height: CGFloat(roofHeight * 1.4))
        frontRoof.firstMaterial = roofMaterial
        
        let frontRoofNode = SCNNode(geometry: frontRoof)
        frontRoofNode.position = SCNVector3(0, height + roofHeight/2, 10)
        frontRoofNode.eulerAngles = SCNVector3(Float.pi/4, 0, 0)
        frontRoofNode.name = "house_roof_front"
        scene.rootNode.addChildNode(frontRoofNode)
        
        // Back roof triangle
        let backRoofNode = SCNNode(geometry: frontRoof)
        backRoofNode.position = SCNVector3(0, height + roofHeight/2, -10)
        backRoofNode.eulerAngles = SCNVector3(-Float.pi/4, Float.pi, 0)
        backRoofNode.name = "house_roof_back"
        scene.rootNode.addChildNode(backRoofNode)
    }
    
    private func addHouseWindowsAndDoors(to scene: SCNScene, height: Float) {
        // Add transparent windows
        let windowMaterial = SCNMaterial()
        windowMaterial.diffuse.contents = UIColor.cyan.withAlphaComponent(0.2)
        windowMaterial.transparency = 0.8
        windowMaterial.emission.contents = UIColor.white.withAlphaComponent(0.1)
        
        // Front windows
        let windowPositions = [
            SCNVector3(-5, 2, 9.9),
            SCNVector3(5, 2, 9.9),
            SCNVector3(-5, 6, 9.9), // Upper floor if exists
            SCNVector3(5, 6, 9.9)
        ]
        
        for position in windowPositions {
            if position.y <= height {
                let window = SCNPlane(width: 2, height: 2)
                window.firstMaterial = windowMaterial
                
                let windowNode = SCNNode(geometry: window)
                windowNode.position = position
                windowNode.name = "house_window"
                scene.rootNode.addChildNode(windowNode)
            }
        }
        
        // Front door
        let doorMaterial = SCNMaterial()
        doorMaterial.diffuse.contents = UIColor.brown.withAlphaComponent(0.4)
        doorMaterial.transparency = 0.6
        
        let door = SCNPlane(width: 1.5, height: 3)
        door.firstMaterial = doorMaterial
        
        let doorNode = SCNNode(geometry: door)
        doorNode.position = SCNVector3(0, 1.5, 9.9)
        doorNode.name = "house_door"
        scene.rootNode.addChildNode(doorNode)
    }
    
    private func addInteriorRoomDivisions(to scene: SCNScene, height: Float, floors: [Int]) {
        // Add interior wall divisions to show rooms
        let interiorWallMaterial = createTransparentWallMaterial(color: UIColor.lightGray.withAlphaComponent(0.1))
        
        for floor in floors {
            let floorHeight = Float(floor - 1) * Float(4.0)
            let wallHeight: Float = 3.5
            
            // Horizontal division (separating front/back rooms)
            let horizontalWall = SCNPlane(width: 18, height: CGFloat(wallHeight))
            horizontalWall.firstMaterial = interiorWallMaterial
            
            let horizontalWallNode = SCNNode(geometry: horizontalWall)
            horizontalWallNode.position = SCNVector3(0, floorHeight + wallHeight/2, 0)
            horizontalWallNode.eulerAngles = SCNVector3(0, Float.pi/2, 0)
            horizontalWallNode.name = "interior_wall_horizontal_\(floor)"
            scene.rootNode.addChildNode(horizontalWallNode)
            
            // Vertical division (separating left/right rooms)
            let verticalWall = SCNPlane(width: 18, height: CGFloat(wallHeight))
            verticalWall.firstMaterial = interiorWallMaterial
            
            let verticalWallNode = SCNNode(geometry: verticalWall)
            verticalWallNode.position = SCNVector3(0, floorHeight + wallHeight/2, 0)
            verticalWallNode.name = "interior_wall_vertical_\(floor)"
            scene.rootNode.addChildNode(verticalWallNode)
        }
    }
    
    private func addOfficeFeatures(to scene: SCNScene, height: Float, floors: [Int]) {
        // Add office-specific features like glass dividers
        let glassMaterial = createTransparentWallMaterial(color: UIColor.blue.withAlphaComponent(0.08))
        
        for floor in floors {
            let floorHeight = Float(floor - 1) * Float(4.0)
            
            // Office cubicle divisions
            let cubiclePositions = [
                SCNVector3(-5, floorHeight + 1.5, 0),
                SCNVector3(5, floorHeight + 1.5, 0),
                SCNVector3(0, floorHeight + 1.5, -4),
                SCNVector3(0, floorHeight + 1.5, 4)
            ]
            
            for position in cubiclePositions {
                let cubicleWall = SCNPlane(width: 8, height: 3)
                cubicleWall.firstMaterial = glassMaterial
                
                let cubicleNode = SCNNode(geometry: cubicleWall)
                cubicleNode.position = position
                cubicleNode.name = "office_cubicle_\(floor)"
                scene.rootNode.addChildNode(cubicleNode)
            }
        }
    }
    
    private func addApartmentFeatures(to scene: SCNScene, height: Float, floors: [Int]) {
        // Add apartment-specific features like balconies
        let balconyMaterial = SCNMaterial()
        balconyMaterial.diffuse.contents = UIColor.brown.withAlphaComponent(0.3)
        balconyMaterial.transparency = 0.7
        
        for floor in floors {
            if floor > 1 { // Only upper floors have balconies
                let floorHeight = Float(floor - 1) * Float(4.0)
                
                let balcony = SCNBox(width: 4, height: 0.2, length: 2, chamferRadius: 0.1)
                balcony.firstMaterial = balconyMaterial
                
                let balconyNode = SCNNode(geometry: balcony)
                balconyNode.position = SCNVector3(0, floorHeight + 1, 11)
                balconyNode.name = "apartment_balcony_\(floor)"
                scene.rootNode.addChildNode(balconyNode)
            }
        }
    }
    
    private func addHouseWireframe(to scene: SCNScene, height: Float) {
        // Add very bright wireframe outline to make house structure clearly visible
        let wireframeMaterial = SCNMaterial()
        wireframeMaterial.diffuse.contents = UIColor.cyan // Bright cyan for high visibility
        wireframeMaterial.emission.contents = UIColor.cyan.withAlphaComponent(0.8) // Strong glow
        wireframeMaterial.lightingModel = .constant // Always visible regardless of lighting
        
        print("🔵 Adding house wireframe with height: \(height)")
        
        // Large corner posts for maximum visibility
        let cornerPositions = [
            SCNVector3(-10, height/2, -10), // Back left
            SCNVector3(10, height/2, -10),  // Back right
            SCNVector3(-10, height/2, 10),  // Front left
            SCNVector3(10, height/2, 10)    // Front right
        ]
        
        for (index, position) in cornerPositions.enumerated() {
            let post = SCNCylinder(radius: 0.3, height: CGFloat(height + 2)) // Thicker posts
            post.firstMaterial = wireframeMaterial
            
            let postNode = SCNNode(geometry: post)
            postNode.position = position
            postNode.name = "house_corner_post_\(index)"
            scene.rootNode.addChildNode(postNode)
            print("📍 Added corner post at: \(position)")
        }
        
        // Thick edge lines for clear visibility
        let edgeData: [(position: SCNVector3, rotation: SCNVector3, name: String)] = [
            // Bottom edges
            (SCNVector3(0, 0.1, -10), SCNVector3(0, 0, Float.pi/2), "bottom_back"),
            (SCNVector3(0, 0.1, 10), SCNVector3(0, 0, Float.pi/2), "bottom_front"),
            (SCNVector3(-10, 0.1, 0), SCNVector3(0, 0, 0), "bottom_left"),
            (SCNVector3(10, 0.1, 0), SCNVector3(0, 0, 0), "bottom_right"),
            // Top edges
            (SCNVector3(0, height + 1.9, -10), SCNVector3(0, 0, Float.pi/2), "top_back"),
            (SCNVector3(0, height + 1.9, 10), SCNVector3(0, 0, Float.pi/2), "top_front"),
            (SCNVector3(-10, height + 1.9, 0), SCNVector3(0, 0, 0), "top_left"),
            (SCNVector3(10, height + 1.9, 0), SCNVector3(0, 0, 0), "top_right")
        ]
        
        for edgeInfo in edgeData {
            let edge = SCNCylinder(radius: 0.15, height: 20) // Thicker edges
            edge.firstMaterial = wireframeMaterial
            
            let edgeNode = SCNNode(geometry: edge)
            edgeNode.position = edgeInfo.position
            edgeNode.eulerAngles = edgeInfo.rotation
            edgeNode.name = "house_edge_\(edgeInfo.name)"
            scene.rootNode.addChildNode(edgeNode)
            print("📏 Added edge: \(edgeInfo.name) at \(edgeInfo.position)")
        }
        
        // Add a bright outline box for immediate visibility
        let outlineBox = SCNBox(width: 20, height: CGFloat(height), length: 20, chamferRadius: 0)
        let outlineMaterial = SCNMaterial()
        outlineMaterial.diffuse.contents = UIColor.clear
        outlineMaterial.lightingModel = .constant
        
        // Create wireframe appearance
        let wireframeMat = SCNMaterial()
        wireframeMat.diffuse.contents = UIColor.yellow // Bright yellow outline
        wireframeMat.emission.contents = UIColor.yellow.withAlphaComponent(0.9)
        wireframeMat.lightingModel = .constant
        wireframeMat.fillMode = .lines // This creates wireframe effect
        
        outlineBox.firstMaterial = wireframeMat
        
        let outlineNode = SCNNode(geometry: outlineBox)
        outlineNode.position = SCNVector3(0, height/2, 0)
        outlineNode.name = "house_outline_box"
        scene.rootNode.addChildNode(outlineNode)
        print("📦 Added bright outline box")
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
        layoutData: Optional<RoomLayoutData>.none,
        environmentType: .house
    )
}
