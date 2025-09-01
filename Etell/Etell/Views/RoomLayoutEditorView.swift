//
//  RoomLayoutEditorView.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-24.
//

import SwiftUI

struct RoomLayoutEditorView: View {
    @StateObject private var viewModel: RoomLayoutEditorViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showing3DView = false
    
    init(calibratedLocations: [CalibratedLocation]) {
        _viewModel = StateObject(wrappedValue: RoomLayoutEditorViewModel(calibratedLocations: calibratedLocations))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Instructions Header
                InstructionsHeader()
                
                // Floor Tabs
                FloorTabBar()
                    .environmentObject(viewModel)
                
                // Main Grid Area
                GridLayoutArea()
                    .environmentObject(viewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Controls Footer
                ControlsFooter()
                    .environmentObject(viewModel)
            }
            .navigationTitle("Arrange Your Rooms")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: {
                            showing3DView = true
                        }) {
                            Image(systemName: "cube")
                                .font(.headline)
                        }
                        
                        Button("Generate WiFi Plan") {
                            viewModel.generateWiFiRecommendations()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showing3DView) {
                Room3DVisualizationView(
                    calibratedLocations: viewModel.calibratedLocations,
                    layoutData: viewModel.layoutData
                )
            }
            .sheet(isPresented: $viewModel.showingWiFiRecommendations) {
                if let recommendations = viewModel.wifiRecommendations {
                    WiFiRecommendationsView(recommendations: recommendations)
                        .environmentObject(viewModel)
                }
            }
        }
    }
}

// MARK: - Instructions Header
struct InstructionsHeader: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "hand.drag")
                    .foregroundColor(.blue)
                Text("Drag and resize rooms to match your floor plan")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            HStack {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .foregroundColor(.green)
                    .font(.caption)
                Text("Drag corners to resize")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Image(systemName: "grid")
                    .foregroundColor(.orange)
                    .font(.caption)
                Text("Snap to grid")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

// MARK: - Floor Tab Bar
struct FloorTabBar: View {
    @EnvironmentObject var viewModel: RoomLayoutEditorViewModel
    
    var body: some View {
        let floors = viewModel.layoutData.floors.map { $0.floor }.sorted()
        
        HStack(spacing: 0) {
            ForEach(floors, id: \.self) { floor in
                Button(action: {
                    viewModel.switchToFloor(floor)
                }) {
                    VStack(spacing: 4) {
                        Text("Floor \(floor)")
                            .font(.subheadline)
                            .fontWeight(viewModel.layoutData.currentFloor == floor ? .semibold : .regular)
                        
                        Text("\(roomCount(for: floor)) rooms")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(viewModel.layoutData.currentFloor == floor ? Color.blue.opacity(0.1) : Color.clear)
                    .foregroundColor(viewModel.layoutData.currentFloor == floor ? .blue : .primary)
                }
                
                if floor != floors.last {
                    Divider()
                        .frame(height: 30)
                }
            }
        }
        .background(Color(.systemGray6))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.gray.opacity(0.3)),
            alignment: .bottom
        )
    }
    
    private func roomCount(for floor: Int) -> Int {
        viewModel.layoutData.floors.first { $0.floor == floor }?.rooms.count ?? 0
    }
}

// MARK: - Grid Layout Area
struct GridLayoutArea: View {
    @EnvironmentObject var viewModel: RoomLayoutEditorViewModel

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                GridBackground(size: geometry.size)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: .gray.opacity(0.15), radius: 12, x: 0, y: 4)
                ForEach(viewModel.layoutData.rooms) { room in
                    DraggableRoomCard(room: room)
                        .environmentObject(viewModel)
                }
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal)
            .onTapGesture {
                viewModel.deselectRoom()
            }
        }
    }
}

// MARK: - Grid Background
struct GridBackground: View {
    let size: CGSize
    private let gridSpacing: CGFloat = 20

    var body: some View {
        Canvas { context, canvasSize in
            context.stroke(
                Path { path in
                    // Vertical lines
                    var x: CGFloat = 0
                    while x <= canvasSize.width {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: canvasSize.height))
                        x += gridSpacing
                    }
                    // Horizontal lines
                    var y: CGFloat = 0
                    while y <= canvasSize.height {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: canvasSize.width, y: y))
                        y += gridSpacing
                    }
                },
                with: .color(.blue.opacity(0.12)),
                style: StrokeStyle(lineWidth: 1, dash: [4, 4])
            )
        }
    }
}

// MARK: - Draggable Room Card
struct DraggableRoomCard: View {
    let room: DraggableRoom
    @EnvironmentObject var viewModel: RoomLayoutEditorViewModel
    @State private var dragOffset = CGSize.zero
    @State private var isDragging = false
    @State private var isResizing = false
    @State private var resizeOffset = CGSize.zero
    
    // Get the current room data from viewModel to ensure we have the latest state
    private var currentRoom: DraggableRoom {
        viewModel.layoutData.rooms.first { $0.id == room.id } ?? room
    }
    
    var body: some View {
        ZStack {
            // Main Room Card
            RoomCardContent(room: currentRoom)
                .frame(width: currentRoom.size.width + resizeOffset.width, 
                       height: currentRoom.size.height + resizeOffset.height)
                .position(
                    x: currentRoom.position.x + currentRoom.size.width/2 + dragOffset.width,
                    y: currentRoom.position.y + currentRoom.size.height/2 + dragOffset.height
                )
                .scaleEffect(isDragging ? 1.05 : 1.0)
                .shadow(radius: isDragging ? 8 : 2)
                .animation(.spring(response: 0.3), value: isDragging)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if !isResizing {
                                isDragging = true
                                dragOffset = value.translation
                            }
                        }
                        .onEnded { value in
                            isDragging = false
                            let newPosition = CGPoint(
                                x: currentRoom.position.x + value.translation.width,
                                y: currentRoom.position.y + value.translation.height
                            )
                            viewModel.moveRoom(currentRoom.id, to: newPosition)
                            dragOffset = .zero
                        }
                )
                .onTapGesture {
                    viewModel.selectRoom(currentRoom)
                }
            
            // Resize Handle (only when selected)
            if currentRoom.isSelected {
                ResizeHandle()
                    .position(
                        x: currentRoom.position.x + currentRoom.size.width + dragOffset.width + resizeOffset.width,
                        y: currentRoom.position.y + currentRoom.size.height + dragOffset.height + resizeOffset.height
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                isResizing = true
                                resizeOffset = value.translation
                            }
                            .onEnded { value in
                                isResizing = false
                                let newSize = CGSize(
                                    width: currentRoom.size.width + value.translation.width,
                                    height: currentRoom.size.height + value.translation.height
                                )
                                viewModel.resizeRoom(currentRoom.id, to: newSize)
                                resizeOffset = .zero
                            }
                    )
            }
        }
    }
}

// MARK: - Room Card Content
struct RoomCardContent: View {
    let room: DraggableRoom
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: room.calibratedLocation.type.icon)
                .font(.system(size: min(room.size.width * 0.3, 24)))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.18), radius: 2, x: 0, y: 1)
            if room.size.width > 50 {
                Text(room.calibratedLocation.name)
                    .font(.system(size: min(room.size.width * 0.15, 14)))
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            if room.size.height > 40 {
                Text("\(Int(room.calibratedLocation.signalStrength * 100))%")
                    .font(.system(size: min(room.size.width * 0.12, 12)))
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.85))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [
                        colorForSignalStrength(room.calibratedLocation.signalStrength),
                        colorForSignalStrength(room.calibratedLocation.signalStrength).opacity(0.7)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(room.isSelected ? Color.white : Color.clear, lineWidth: 2)
                )
        )
        .shadow(color: .black.opacity(room.isSelected ? 0.18 : 0.08), radius: room.isSelected ? 10 : 4, x: 0, y: 2)
        .overlay(
            room.isSelected ?
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue, lineWidth: 3)
                    .shadow(color: .blue.opacity(0.3), radius: 8)
                : nil
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: room.isSelected)
    }
    
    private func colorForSignalStrength(_ strength: Double) -> Color {
        switch strength {
        case 0.7...1.0: return .green
        case 0.4..<0.7: return .orange
        default: return .red
        }
    }
}

// MARK: - Resize Handle
struct ResizeHandle: View {
    var body: some View {
        Circle()
            .fill(Color.blue)
            .frame(width: 12, height: 12)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 2)
            )
            .shadow(radius: 2)
    }
}

// MARK: - Controls Footer
struct ControlsFooter: View {
    @EnvironmentObject var viewModel: RoomLayoutEditorViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            // Selected Room Info
            if let selectedRoom = viewModel.selectedRoom {
                SelectedRoomInfo(room: selectedRoom)
            }
            
            // Control Buttons
            HStack(spacing: 16) {
                Button(action: {
                    viewModel.layoutData.snapToGrid.toggle()
                }) {
                    HStack {
                        Image(systemName: viewModel.layoutData.snapToGrid ? "grid" : "grid.slash")
                        Text("Snap to Grid")
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(viewModel.layoutData.snapToGrid ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                }
                
                Spacer()
                
                Text("\(viewModel.layoutData.rooms.count) rooms on Floor \(viewModel.layoutData.currentFloor)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

// MARK: - Selected Room Info
struct SelectedRoomInfo: View {
    let room: DraggableRoom
    
    var body: some View {
        HStack {
            Image(systemName: room.calibratedLocation.type.icon)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(room.calibratedLocation.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text("Size: \(Int(room.size.width))×\(Int(room.size.height))")
                    Text("•")
                    Text("Signal: \(Int(room.calibratedLocation.signalStrength * 100))%")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Deselect") {
                
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    RoomLayoutEditorView(calibratedLocations: [
        CalibratedLocation(
            name: "Living Room",
            type: .room,
            floor: 1,
            signalStrength: 0.8,
            coordinates: nil,
            timestamp: Date(),
            recommendations: []
        ),
        CalibratedLocation(
            name: "Kitchen",
            type: .room,
            floor: 1,
            signalStrength: 0.6,
            coordinates: nil,
            timestamp: Date(),
            recommendations: []
        )
    ])
}
