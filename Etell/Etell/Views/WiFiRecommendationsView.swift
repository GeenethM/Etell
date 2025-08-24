//
//  WiFiRecommendationsView.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-24.
//

import SwiftUI

struct WiFiRecommendationsView: View {
    let recommendations: WiFiLayoutRecommendations
    @EnvironmentObject var viewModel: RoomLayoutEditorViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Coverage Analysis Header
                    CoverageAnalysisHeader(analysis: recommendations.coverageAnalysis)
                    
                    // Router Recommendations
                    LayoutRouterRecommendationsSection(recommendations: recommendations.routerRecommendations)
                        .environmentObject(viewModel)
                    
                    // Extender Recommendations
                    if !recommendations.extenderRecommendations.isEmpty {
                        LayoutExtenderRecommendationsSection(recommendations: recommendations.extenderRecommendations)
                            .environmentObject(viewModel)
                    }
                    
                    // Layout Preview
                    LayoutPreviewSection()
                        .environmentObject(viewModel)
                    
                    // Implementation Guide
                    ImplementationGuideSection()
                }
                .padding()
            }
            .navigationTitle("WiFi Layout Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Coverage Analysis Header
struct CoverageAnalysisHeader: View {
    let analysis: CoverageAnalysis
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("WiFi Coverage Analysis")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Based on your room layout and signal measurements")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            // Coverage Score Circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: analysis.coveragePercentage)
                    .stroke(coverageColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                VStack {
                    Text("\(Int(analysis.coveragePercentage * 100))%")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Coverage")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Stats Grid
            HStack(spacing: 20) {
                CoverageStatCard(
                    title: "Total Rooms",
                    value: "\(analysis.totalRooms)",
                    color: .blue
                )
                
                CoverageStatCard(
                    title: "Well Covered",
                    value: "\(analysis.wellCoveredRooms)",
                    color: .green
                )
                
                CoverageStatCard(
                    title: "Weak Areas",
                    value: "\(analysis.weakAreas)",
                    color: .red
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var coverageColor: Color {
        switch analysis.coveragePercentage {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .orange
        default: return .red
        }
    }
}

struct CoverageStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Layout Router Recommendations Section
struct LayoutRouterRecommendationsSection: View {
    let recommendations: [RouterRecommendation]
    @EnvironmentObject var viewModel: RoomLayoutEditorViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "wifi.router")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("Optimal Router Placement")
                    .font(.headline)
            }
            
            if recommendations.isEmpty {
                EmptyRecommendationCard(
                    icon: "wifi.router",
                    title: "No specific router recommendations",
                    description: "Your current setup appears to be working well"
                )
            } else {
                ForEach(recommendations, id: \.floor) { recommendation in
                    LayoutRouterRecommendationCard(recommendation: recommendation)
                        .environmentObject(viewModel)
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

struct LayoutRouterRecommendationCard: View {
    let recommendation: RouterRecommendation
    @EnvironmentObject var viewModel: RoomLayoutEditorViewModel
    @State private var showingOnLayout = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Floor \(recommendation.floor)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                        
                        Spacer()
                        
                        Text("Score: \(Int(recommendation.score * 100))/100")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                    
                    Text("Place router in \(recommendation.room.name)")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }
            
            // Reasoning
            Text(recommendation.reasoning)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Position Info
            HStack {
                Image(systemName: recommendation.room.type.icon)
                    .foregroundColor(.blue)
                
                Text("\(recommendation.room.type.rawValue) • Signal: \(Int(recommendation.room.signalStrength * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    showingOnLayout.toggle()
                }) {
                    Text(showingOnLayout ? "Hide on Layout" : "Show on Layout")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            // Layout Preview (when toggled)
            if showingOnLayout {
                RouterLayoutPreview(recommendation: recommendation)
                    .environmentObject(viewModel)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
    }
}

struct RouterLayoutPreview: View {
    let recommendation: RouterRecommendation
    @EnvironmentObject var viewModel: RoomLayoutEditorViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Router Position on Layout:")
                .font(.caption)
                .fontWeight(.medium)
            
            // Mini layout view
            ZStack {
                Rectangle()
                    .fill(Color(.systemGray6))
                    .frame(height: 100)
                
                // Simplified room layout for this floor
                let floorRooms = viewModel.layoutData.floors.first { $0.floor == recommendation.floor }?.rooms ?? []
                
                ForEach(floorRooms) { room in
                    let isRouterRoom = room.calibratedLocation.name == recommendation.room.name
                    
                    Rectangle()
                        .fill(isRouterRoom ? Color.blue : Color.gray.opacity(0.5))
                        .frame(
                            width: room.size.width * 0.3,
                            height: room.size.height * 0.3
                        )
                        .position(
                            x: room.position.x * 0.3 + 20,
                            y: room.position.y * 0.3 + 20
                        )
                        .overlay(
                            Group {
                                if isRouterRoom {
                                    Image(systemName: "wifi.router")
                                        .foregroundColor(.white)
                                        .font(.caption)
                                }
                            }
                        )
                }
            }
            .cornerRadius(6)
        }
    }
}

// MARK: - Layout Extender Recommendations Section
struct LayoutExtenderRecommendationsSection: View {
    let recommendations: [LayoutExtenderRecommendation]
    @EnvironmentObject var viewModel: RoomLayoutEditorViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                Text("WiFi Extender Recommendations")
                    .font(.headline)
            }
            
            Text("Based on your room layout and adjacency analysis")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            ForEach(recommendations, id: \.targetRoom.id) { recommendation in
                LayoutExtenderRecommendationCard(recommendation: recommendation)
                    .environmentObject(viewModel)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

struct LayoutExtenderRecommendationCard: View {
    let recommendation: LayoutExtenderRecommendation
    @EnvironmentObject var viewModel: RoomLayoutEditorViewModel
    @State private var showingDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Target Room Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Floor \(recommendation.floor)")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(3)
                        
                        Text("Target: \(recommendation.targetRoom.name)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    if let placementRoom = recommendation.placementRoom {
                        Text("Place extender near \(placementRoom.name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Signal Improvement
                VStack(alignment: .trailing, spacing: 2) {
                    Text("+\(Int((recommendation.signalImprovement - recommendation.targetRoom.signalStrength) * 100))%")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("improvement")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Reasoning
            Text(recommendation.reasoning)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Toggle Details
            Button(action: {
                withAnimation(.spring()) {
                    showingDetails.toggle()
                }
            }) {
                HStack {
                    Text(showingDetails ? "Hide Details" : "Show Position Details")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Image(systemName: showingDetails ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            // Detailed Layout Preview
            if showingDetails {
                ExtenderLayoutPreview(recommendation: recommendation)
                    .environmentObject(viewModel)
                    .transition(.slide)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }
}

struct ExtenderLayoutPreview: View {
    let recommendation: LayoutExtenderRecommendation
    @EnvironmentObject var viewModel: RoomLayoutEditorViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Extender Position:")
                .font(.caption)
                .fontWeight(.medium)
            
            ZStack {
                Rectangle()
                    .fill(Color(.systemGray6))
                    .frame(height: 80)
                
                let floorRooms = viewModel.layoutData.floors.first { $0.floor == recommendation.floor }?.rooms ?? []
                
                ForEach(floorRooms) { room in
                    let isTargetRoom = room.calibratedLocation.name == recommendation.targetRoom.name
                    let isPlacementRoom = room.calibratedLocation.name == recommendation.placementRoom?.name
                    
                    Rectangle()
                        .fill(isTargetRoom ? Color.red.opacity(0.7) : (isPlacementRoom ? Color.blue.opacity(0.7) : Color.gray.opacity(0.3)))
                        .frame(
                            width: room.size.width * 0.25,
                            height: room.size.height * 0.25
                        )
                        .position(
                            x: room.position.x * 0.25 + 15,
                            y: room.position.y * 0.25 + 15
                        )
                }
                
                // Extender Position
                Circle()
                    .fill(Color.orange)
                    .frame(width: 12, height: 12)
                    .position(
                        x: recommendation.recommendedPosition.x * 0.25 + 15,
                        y: recommendation.recommendedPosition.y * 0.25 + 15
                    )
                    .overlay(
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 6))
                            .foregroundColor(.white)
                            .position(
                                x: recommendation.recommendedPosition.x * 0.25 + 15,
                                y: recommendation.recommendedPosition.y * 0.25 + 15
                            )
                    )
            }
            .cornerRadius(6)
            
            // Legend
            HStack(spacing: 16) {
                LegendItem(color: .red, text: "Weak Signal")
                LegendItem(color: .orange, text: "Extender")
                if recommendation.placementRoom != nil {
                    LegendItem(color: .blue, text: "Strong Signal")
                }
            }
            .font(.caption2)
        }
    }
}

struct LegendItem: View {
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Layout Preview Section
struct LayoutPreviewSection: View {
    @EnvironmentObject var viewModel: RoomLayoutEditorViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Room Layout")
                .font(.headline)
            
            Text("Tap on floors to see recommendations in context")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            // Floor tabs for preview
            let floors = viewModel.layoutData.floors.map { $0.floor }.sorted()
            
            TabView {
                ForEach(floors, id: \.self) { floor in
                    LayoutFloorPreview(floor: floor)
                        .environmentObject(viewModel)
                        .tabItem {
                            Text("Floor \(floor)")
                        }
                }
            }
            .frame(height: 200)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

struct LayoutFloorPreview: View {
    let floor: Int
    @EnvironmentObject var viewModel: RoomLayoutEditorViewModel
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(.systemGray6))
            
            let floorRooms = viewModel.layoutData.floors.first { $0.floor == floor }?.rooms ?? []
            
            ForEach(floorRooms) { room in
                Rectangle()
                    .fill(colorForSignalStrength(room.calibratedLocation.signalStrength))
                    .frame(
                        width: room.size.width * 0.5,
                        height: room.size.height * 0.5
                    )
                    .position(
                        x: room.position.x * 0.5 + 30,
                        y: room.position.y * 0.5 + 30
                    )
                    .overlay(
                        Text(room.calibratedLocation.name)
                            .font(.caption2)
                            .foregroundColor(.white)
                            .position(
                                x: room.position.x * 0.5 + 30,
                                y: room.position.y * 0.5 + 30
                            )
                    )
            }
        }
        .cornerRadius(8)
    }
    
    private func colorForSignalStrength(_ strength: Double) -> Color {
        switch strength {
        case 0.7...1.0: return .green.opacity(0.8)
        case 0.4..<0.7: return .orange.opacity(0.8)
        default: return .red.opacity(0.8)
        }
    }
}

// MARK: - Implementation Guide Section
struct ImplementationGuideSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Implementation Guide")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                ImplementationStep(
                    number: "1",
                    title: "Router Placement",
                    description: "Move your main router to the recommended location for optimal coverage"
                )
                
                ImplementationStep(
                    number: "2",
                    title: "Install Extenders",
                    description: "Place WiFi extenders in the suggested locations to boost weak areas"
                )
                
                ImplementationStep(
                    number: "3",
                    title: "Test Coverage",
                    description: "Use the calibration tool again to verify improved signal strength"
                )
                
                ImplementationStep(
                    number: "4",
                    title: "Fine-tune",
                    description: "Adjust positions based on real-world performance"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ImplementationStep: View {
    let number: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue)
                .frame(width: 24, height: 24)
                .overlay(
                    Text(number)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Empty Recommendation Card
struct EmptyRecommendationCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.gray)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    WiFiRecommendationsView(
        recommendations: WiFiLayoutRecommendations(
            routerRecommendations: [],
            extenderRecommendations: [],
            coverageAnalysis: CoverageAnalysis(
                totalRooms: 5,
                wellCoveredRooms: 3,
                weakAreas: 2,
                coveragePercentage: 0.6
            )
        )
    )
    .environmentObject(RoomLayoutEditorViewModel(calibratedLocations: []))
}
