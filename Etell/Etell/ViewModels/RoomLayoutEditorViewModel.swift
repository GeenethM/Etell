//
//  RoomLayoutEditor.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-24.
//

import SwiftUI

// MARK: - Data Models
struct RoomLayoutData {
    var rooms: [DraggableRoom] = []
    var floors: [FloorLayout] = []
    var currentFloor: Int = 1
    var gridSize: CGSize = CGSize(width: 300, height: 400)
    var snapToGrid: Bool = true
    var lastUpdate: Date = Date() // Add timestamp to force UI updates
}

struct DraggableRoom: Identifiable, Equatable {
    let id = UUID()
    let calibratedLocation: CalibratedLocation
    var position: CGPoint
    var size: CGSize
    var floor: Int
    var isSelected: Bool = false
    
    static func == (lhs: DraggableRoom, rhs: DraggableRoom) -> Bool {
        lhs.id == rhs.id
    }
}

struct FloorLayout {
    let floor: Int
    var rooms: [DraggableRoom]
    var adjacencyMap: [UUID: Set<UUID>] = [:]
}

// MARK: - Room Layout Editor View Model
@MainActor
class RoomLayoutEditorViewModel: ObservableObject {
    @Published var layoutData = RoomLayoutData()
    @Published var selectedRoom: DraggableRoom?
    @Published var showingWiFiRecommendations = false
    @Published var wifiRecommendations: WiFiLayoutRecommendations?
    
    private let gridCellSize: CGFloat = 20
    
    init(calibratedLocations: [CalibratedLocation]) {
        setupInitialLayout(from: calibratedLocations)
    }
    
    private func setupInitialLayout(from locations: [CalibratedLocation]) {
        // Group by floors
        let floors = Set(locations.map { $0.floor }).sorted()
        
        for floor in floors {
            let floorRooms = locations.filter { $0.floor == floor }
            var draggableRooms: [DraggableRoom] = []
            
            // Create initial room layout in a grid pattern
            for (index, location) in floorRooms.enumerated() {
                let col = index % 3
                let row = index / 3
                
                let position = CGPoint(
                    x: CGFloat(col) * 80 + 40,
                    y: CGFloat(row) * 60 + 40
                )
                
                let size = sizeForLocationType(location.type)
                
                let room = DraggableRoom(
                    calibratedLocation: location,
                    position: position,
                    size: size,
                    floor: floor
                )
                
                draggableRooms.append(room)
            }
            
            let floorLayout = FloorLayout(floor: floor, rooms: draggableRooms)
            layoutData.floors.append(floorLayout)
        }
        
        // Set current floor rooms
        updateCurrentFloorRooms()
    }
    
    private func sizeForLocationType(_ type: LocationType) -> CGSize {
        switch type {
        case .room:
            return CGSize(width: 60, height: 60)
        case .hallway:
            return CGSize(width: 80, height: 30)
        case .staircase:
            return CGSize(width: 40, height: 40)
        }
    }
    
    func selectRoom(_ room: DraggableRoom) {
        selectedRoom = room
        updateRoomSelection(room.id, isSelected: true)
    }
    
    func deselectRoom() {
        if let selected = selectedRoom {
            updateRoomSelection(selected.id, isSelected: false)
        }
        selectedRoom = nil
    }
    
    func moveRoom(_ roomId: UUID, to position: CGPoint) {
        let snappedPosition = layoutData.snapToGrid ? snapToGrid(position) : position
        
        if let floorIndex = layoutData.floors.firstIndex(where: { $0.floor == layoutData.currentFloor }),
           let roomIndex = layoutData.floors[floorIndex].rooms.firstIndex(where: { $0.id == roomId }) {
            layoutData.floors[floorIndex].rooms[roomIndex].position = snappedPosition
            
            // Force UI update by updating timestamp and triggering objectWillChange
            layoutData.lastUpdate = Date()
            objectWillChange.send()
            updateCurrentFloorRooms()
            calculateAdjacency()
        }
    }
    
    func resizeRoom(_ roomId: UUID, to size: CGSize) {
        let constrainedSize = CGSize(
            width: max(30, min(120, size.width)),
            height: max(20, min(100, size.height))
        )
        
        if let floorIndex = layoutData.floors.firstIndex(where: { $0.floor == layoutData.currentFloor }),
           let roomIndex = layoutData.floors[floorIndex].rooms.firstIndex(where: { $0.id == roomId }) {
            layoutData.floors[floorIndex].rooms[roomIndex].size = constrainedSize
            
            // Force UI update by updating timestamp and triggering objectWillChange
            layoutData.lastUpdate = Date()
            objectWillChange.send()
            updateCurrentFloorRooms()
            calculateAdjacency()
        }
    }
    
    func switchToFloor(_ floor: Int) {
        deselectRoom()
        layoutData.currentFloor = floor
        updateCurrentFloorRooms()
    }
    
    private func updateCurrentFloorRooms() {
        if let floorLayout = layoutData.floors.first(where: { $0.floor == layoutData.currentFloor }) {
            // Create a new array to ensure SwiftUI detects the change
            layoutData.rooms = Array(floorLayout.rooms)
        }
    }
    
    private func updateRoomSelection(_ roomId: UUID, isSelected: Bool) {
        if let floorIndex = layoutData.floors.firstIndex(where: { $0.floor == layoutData.currentFloor }),
           let roomIndex = layoutData.floors[floorIndex].rooms.firstIndex(where: { $0.id == roomId }) {
            layoutData.floors[floorIndex].rooms[roomIndex].isSelected = isSelected
            
            // Force UI update by updating timestamp and triggering objectWillChange
            layoutData.lastUpdate = Date()
            objectWillChange.send()
            updateCurrentFloorRooms()
        }
    }
    
    private func snapToGrid(_ position: CGPoint) -> CGPoint {
        let snappedX = round(position.x / gridCellSize) * gridCellSize
        let snappedY = round(position.y / gridCellSize) * gridCellSize
        return CGPoint(x: snappedX, y: snappedY)
    }
    
    private func calculateAdjacency() {
        for floorIndex in layoutData.floors.indices {
            var adjacencyMap: [UUID: Set<UUID>] = [:]
            let rooms = layoutData.floors[floorIndex].rooms
            
            for room in rooms {
                var adjacentRooms: Set<UUID> = []
                
                for otherRoom in rooms where otherRoom.id != room.id {
                    if areRoomsAdjacent(room, otherRoom) {
                        adjacentRooms.insert(otherRoom.id)
                    }
                }
                
                adjacencyMap[room.id] = adjacentRooms
            }
            
            layoutData.floors[floorIndex].adjacencyMap = adjacencyMap
        }
    }
    
    private func areRoomsAdjacent(_ room1: DraggableRoom, _ room2: DraggableRoom) -> Bool {
        let threshold: CGFloat = 10 // Proximity threshold
        
        let rect1 = CGRect(origin: room1.position, size: room1.size)
        let rect2 = CGRect(origin: room2.position, size: room2.size)
        
        // Check if rooms are touching or very close
        let expandedRect1 = rect1.insetBy(dx: -threshold, dy: -threshold)
        return expandedRect1.intersects(rect2)
    }
    
    func generateWiFiRecommendations() {
        let recommendations = WiFiLayoutAnalyzer.analyze(layoutData: layoutData)
        wifiRecommendations = recommendations
        showingWiFiRecommendations = true
    }
}

// MARK: - WiFi Layout Analyzer
struct WiFiLayoutAnalyzer {
    static func analyze(layoutData: RoomLayoutData) -> WiFiLayoutRecommendations {
        var routerRecommendations: [RouterRecommendation] = []
        var extenderRecommendations: [LayoutExtenderRecommendation] = []
        
        for floorLayout in layoutData.floors {
            // Find optimal router position for this floor
            if let routerRec = findOptimalRouterPosition(for: floorLayout) {
                routerRecommendations.append(routerRec)
            }
            
            // Find extender positions based on adjacency and signal strength
            let extenders = findOptimalExtenderPositions(for: floorLayout)
            extenderRecommendations.append(contentsOf: extenders)
        }
        
        return WiFiLayoutRecommendations(
            routerRecommendations: routerRecommendations,
            extenderRecommendations: extenderRecommendations,
            coverageAnalysis: analyzeCoverage(layoutData: layoutData)
        )
    }
    
    private static func findOptimalRouterPosition(for floor: FloorLayout) -> RouterRecommendation? {
        guard !floor.rooms.isEmpty else { return nil }
        
        // Calculate centrality scores for each room
        var bestRoom: DraggableRoom?
        var bestScore: Double = 0
        
        for room in floor.rooms {
            let centralityScore = calculateCentralityScore(for: room, in: floor)
            let signalScore = room.calibratedLocation.signalStrength
            let typeBonus = room.calibratedLocation.type == .room ? 0.2 : 0.0
            
            let totalScore = centralityScore * 0.4 + signalScore * 0.4 + typeBonus
            
            if totalScore > bestScore {
                bestScore = totalScore
                bestRoom = room
            }
        }
        
        guard let optimalRoom = bestRoom else { return nil }
        
        return RouterRecommendation(
            floor: floor.floor,
            room: optimalRoom.calibratedLocation,
            position: optimalRoom.position,
            score: bestScore,
            reasoning: generateRouterReasoning(for: optimalRoom, score: bestScore)
        )
    }
    
    private static func calculateCentralityScore(for room: DraggableRoom, in floor: FloorLayout) -> Double {
        let center = CGPoint(
            x: room.position.x + room.size.width / 2,
            y: room.position.y + room.size.height / 2
        )
        
        var totalDistance: Double = 0
        var roomCount = 0
        
        for otherRoom in floor.rooms where otherRoom.id != room.id {
            let otherCenter = CGPoint(
                x: otherRoom.position.x + otherRoom.size.width / 2,
                y: otherRoom.position.y + otherRoom.size.height / 2
            )
            
            let distance = sqrt(pow(center.x - otherCenter.x, 2) + pow(center.y - otherCenter.y, 2))
            totalDistance += distance
            roomCount += 1
        }
        
        guard roomCount > 0 else { return 1.0 }
        
        let averageDistance = totalDistance / Double(roomCount)
        // Invert distance (closer to center = higher score)
        return max(0, 1 - (averageDistance / 200))
    }
    
    private static func findOptimalExtenderPositions(for floor: FloorLayout) -> [LayoutExtenderRecommendation] {
        var extenders: [LayoutExtenderRecommendation] = []
        
        // Find rooms with weak signal
        let weakRooms = floor.rooms.filter { $0.calibratedLocation.signalStrength < 0.5 }
        
        for weakRoom in weakRooms {
            // Check if there's a nearby strong room for extender placement
            if let extenderPosition = findExtenderPosition(for: weakRoom, in: floor) {
                let extender = LayoutExtenderRecommendation(
                    floor: floor.floor,
                    targetRoom: weakRoom.calibratedLocation,
                    recommendedPosition: extenderPosition.position,
                    placementRoom: extenderPosition.room?.calibratedLocation,
                    signalImprovement: estimateSignalImprovement(for: weakRoom, with: extenderPosition),
                    reasoning: generateExtenderReasoning(for: weakRoom, position: extenderPosition)
                )
                extenders.append(extender)
            }
        }
        
        return extenders
    }
    
    private static func findExtenderPosition(for weakRoom: DraggableRoom, in floor: FloorLayout) -> ExtenderPosition? {
        guard let adjacentRooms = floor.adjacencyMap[weakRoom.id] else { return nil }
        
        // Find adjacent room with better signal
        var bestPosition: ExtenderPosition?
        var bestSignal: Double = 0
        
        for adjacentRoomId in adjacentRooms {
            if let adjacentRoom = floor.rooms.first(where: { $0.id == adjacentRoomId }),
               adjacentRoom.calibratedLocation.signalStrength > weakRoom.calibratedLocation.signalStrength {
                
                // Calculate position between rooms
                let position = CGPoint(
                    x: (weakRoom.position.x + adjacentRoom.position.x) / 2,
                    y: (weakRoom.position.y + adjacentRoom.position.y) / 2
                )
                
                if adjacentRoom.calibratedLocation.signalStrength > bestSignal {
                    bestSignal = adjacentRoom.calibratedLocation.signalStrength
                    bestPosition = ExtenderPosition(position: position, room: adjacentRoom)
                }
            }
        }
        
        return bestPosition
    }
    
    private static func generateRouterReasoning(for room: DraggableRoom, score: Double) -> String {
        var reasons: [String] = []
        
        if score > 0.8 {
            reasons.append("Central location with excellent coverage potential")
        } else if score > 0.6 {
            reasons.append("Good central position")
        }
        
        if room.calibratedLocation.signalStrength > 0.7 {
            reasons.append("Strong existing signal strength")
        }
        
        if room.calibratedLocation.type == .room {
            reasons.append("Main living area suitable for router placement")
        }
        
        return reasons.joined(separator: " • ")
    }
    
    private static func generateExtenderReasoning(for room: DraggableRoom, position: ExtenderPosition) -> String {
        let signalPercent = Int(room.calibratedLocation.signalStrength * 100)
        var reasoning = "Weak signal area (\(signalPercent)%)"
        
        if let placementRoom = position.room {
            let placementSignal = Int(placementRoom.calibratedLocation.signalStrength * 100)
            reasoning += " • Placement near \(placementRoom.calibratedLocation.name) (\(placementSignal)% signal)"
        }
        
        return reasoning
    }
    
    private static func estimateSignalImprovement(for room: DraggableRoom, with position: ExtenderPosition) -> Double {
        let currentSignal = room.calibratedLocation.signalStrength
        let extenderBoost = 0.3 // Estimated 30% improvement
        return min(1.0, currentSignal + extenderBoost)
    }
    
    private static func analyzeCoverage(layoutData: RoomLayoutData) -> CoverageAnalysis {
        var totalRooms = 0
        var wellCoveredRooms = 0
        var weakAreas = 0
        
        for floor in layoutData.floors {
            totalRooms += floor.rooms.count
            for room in floor.rooms {
                if room.calibratedLocation.signalStrength >= 0.7 {
                    wellCoveredRooms += 1
                } else if room.calibratedLocation.signalStrength < 0.4 {
                    weakAreas += 1
                }
            }
        }
        
        let coveragePercentage = totalRooms > 0 ? Double(wellCoveredRooms) / Double(totalRooms) : 0
        
        return CoverageAnalysis(
            totalRooms: totalRooms,
            wellCoveredRooms: wellCoveredRooms,
            weakAreas: weakAreas,
            coveragePercentage: coveragePercentage
        )
    }
}

// MARK: - Supporting Data Models
struct WiFiLayoutRecommendations {
    let routerRecommendations: [RouterRecommendation]
    let extenderRecommendations: [LayoutExtenderRecommendation]
    let coverageAnalysis: CoverageAnalysis
}

struct RouterRecommendation {
    let floor: Int
    let room: CalibratedLocation
    let position: CGPoint
    let score: Double
    let reasoning: String
}

struct LayoutExtenderRecommendation {
    let floor: Int
    let targetRoom: CalibratedLocation
    let recommendedPosition: CGPoint
    let placementRoom: CalibratedLocation?
    let signalImprovement: Double
    let reasoning: String
}

struct ExtenderPosition {
    let position: CGPoint
    let room: DraggableRoom?
}

struct CoverageAnalysis {
    let totalRooms: Int
    let wellCoveredRooms: Int
    let weakAreas: Int
    let coveragePercentage: Double
}
