//
//  CalibrationResultsView.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-23.
//

import SwiftUI

struct CalibrationResultsView: View {
    @EnvironmentObject var viewModel: EnhancedCalibrationViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingLayoutEditor = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary Header
                    CalibrationSummaryHeader()
                        .environmentObject(viewModel)
                    
                    // Layout Editor Button
                    LayoutEditorPrompt()
                    
                    // All Calibrated Locations
                    AllLocationsSection()
                        .environmentObject(viewModel)
                    
                    // Router Placement Recommendations
                    RouterRecommendationsSection()
                        .environmentObject(viewModel)
                    
                    // WiFi Extender Recommendations
                    ExtenderRecommendationsSection()
                        .environmentObject(viewModel)
                    
                    // Overall Network Health
                    NetworkHealthSection()
                        .environmentObject(viewModel)
                }
                .padding()
            }
            .navigationTitle("Calibration Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingLayoutEditor) {
                RoomLayoutEditorView(calibratedLocations: viewModel.calibratedLocations)
            }
        }
    }
    
    // MARK: - Layout Editor Prompt
    @ViewBuilder
    private func LayoutEditorPrompt() -> some View {
        Button(action: {
            showingLayoutEditor = true
        }) {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "square.grid.3x3")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Arrange Your Room Layout")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Get precise WiFi recommendations based on your floor plan")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Text("📐 Drag & resize rooms")
                    Text("•")
                    Text("🏢 Multi-floor support")
                    Text("•")
                    Text("📡 Smart WiFi placement")
                    Spacer()
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Summary Header
struct CalibrationSummaryHeader: View {
    @EnvironmentObject var viewModel: EnhancedCalibrationViewModel
    
    var body: some View {
        let summary = viewModel.generateFinalRecommendations()
        
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("Network Analysis Complete")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("\(summary.totalLocations) locations analyzed")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            // Overall Signal Quality Circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: summary.averageSignalStrength)
                    .stroke(overallSignalColor(summary.averageSignalStrength), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                VStack {
                    Text("\(Int(summary.averageSignalStrength * 100))%")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Average Signal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Quick Stats
            HStack(spacing: 20) {
                StatCard(
                    title: "Strong Areas",
                    value: "\(summary.strongAreas.count)",
                    color: .green
                )
                
                StatCard(
                    title: "Weak Areas",
                    value: "\(summary.weakAreas.count)",
                    color: .red
                )
                
                StatCard(
                    title: "Extenders Needed",
                    value: "\(summary.extenderRecommendations.count)",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func overallSignalColor(_ strength: Double) -> Color {
        switch strength {
        case 0.7...1.0: return .green
        case 0.4..<0.7: return .orange
        default: return .red
        }
    }
}

struct StatCard: View {
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

// MARK: - All Locations Section
struct AllLocationsSection: View {
    @EnvironmentObject var viewModel: EnhancedCalibrationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Calibrated Locations")
                .font(.headline)
            
            VStack(spacing: 8) {
                ForEach(viewModel.calibratedLocations, id: \.id) { location in
                    DetailedLocationRow(location: location)
                }
            }
        }
        .padding()
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

struct DetailedLocationRow: View {
    let location: CalibratedLocation
    @State private var showingDetails = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Location Icon
                ZStack {
                    Circle()
                        .fill(signalColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: location.type.icon)
                        .foregroundColor(signalColor)
                        .font(.system(size: 18, weight: .semibold))
                }
                
                // Location Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 8) {
                        Text("Floor \(location.floor)")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                        
                        Text(location.type.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Signal Strength
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(location.signalStrength * 100))%")
                        .font(.headline)
                        .foregroundColor(signalColor)
                    
                    Text(signalQuality)
                        .font(.caption)
                        .foregroundColor(signalColor)
                }
                
                // Expand Button
                Button(action: {
                    withAnimation(.spring()) {
                        showingDetails.toggle()
                    }
                }) {
                    Image(systemName: showingDetails ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            .padding(.vertical, 8)
            
            // Expanded Details
            if showingDetails {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    
                    Text("Recommendations:")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    ForEach(location.recommendations, id: \.self) { recommendation in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 4, height: 4)
                                .padding(.top, 6)
                            
                            Text(recommendation)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 8)
                .transition(.slide)
            }
        }
    }
    
    private var signalColor: Color {
        switch location.signalStrength {
        case 0.7...1.0: return .green
        case 0.4..<0.7: return .orange
        default: return .red
        }
    }
    
    private var signalQuality: String {
        switch location.signalStrength {
        case 0.8...1.0: return "Excellent"
        case 0.6..<0.8: return "Good"
        case 0.4..<0.6: return "Fair"
        case 0.2..<0.4: return "Poor"
        default: return "Very Poor"
        }
    }
}

// MARK: - Router Recommendations Section
struct RouterRecommendationsSection: View {
    @EnvironmentObject var viewModel: EnhancedCalibrationViewModel
    
    var body: some View {
        let summary = viewModel.generateFinalRecommendations()
        
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "wifi.router")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("Router Placement")
                    .font(.headline)
            }
            
            if summary.routerRecommendations.isEmpty {
                Text("Consider placing your router in a central location for optimal coverage")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .italic()
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(summary.routerRecommendations, id: \.self) { recommendation in
                        RecommendationRow(
                            icon: "checkmark.circle.fill",
                            text: recommendation,
                            color: .green
                        )
                    }
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

// MARK: - Extender Recommendations Section
struct ExtenderRecommendationsSection: View {
    @EnvironmentObject var viewModel: EnhancedCalibrationViewModel
    
    var body: some View {
        let summary = viewModel.generateFinalRecommendations()
        
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                Text("WiFi Extender Recommendations")
                    .font(.headline)
            }
            
            if summary.extenderRecommendations.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Text("Great! Your current coverage seems adequate. No extenders needed.")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("We recommend installing WiFi extenders in these locations:")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    ForEach(summary.extenderRecommendations, id: \.location) { extender in
                        ExtenderRecommendationCard(extender: extender)
                    }
                }
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

struct ExtenderRecommendationCard: View {
    let extender: ExtenderRecommendation
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 4) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundColor(.orange)
                    .font(.title3)
                
                Text("Floor \(extender.floor)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(extender.type.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Location: \(extender.location)")
                    .font(.caption)
                    .foregroundColor(.primary)
                
                Text(extender.reason)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack {
                Text("HIGH")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                
                Text("PRIORITY")
                    .font(.caption2)
                    .foregroundColor(.orange)
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

// MARK: - Network Health Section
struct NetworkHealthSection: View {
    @EnvironmentObject var viewModel: EnhancedCalibrationViewModel
    
    var body: some View {
        let summary = viewModel.generateFinalRecommendations()
        
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.pink)
                    .font(.title2)
                
                Text("Network Health Score")
                    .font(.headline)
            }
            
            let healthScore = calculateHealthScore(summary)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Overall Score:")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("\(Int(healthScore * 100))/100")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(healthColor(healthScore))
                }
                
                ProgressView(value: healthScore)
                    .progressViewStyle(LinearProgressViewStyle(tint: healthColor(healthScore)))
                
                Text(healthDescription(healthScore))
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func calculateHealthScore(_ summary: CalibrationSummary) -> Double {
        let averageSignal = summary.averageSignalStrength
        let weakAreasPenalty = Double(summary.weakAreas.count) * 0.1
        let strongAreasBonus = Double(summary.strongAreas.count) * 0.05
        
        return min(1.0, max(0.0, averageSignal - weakAreasPenalty + strongAreasBonus))
    }
    
    private func healthColor(_ score: Double) -> Color {
        switch score {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .orange
        default: return .red
        }
    }
    
    private func healthDescription(_ score: Double) -> String {
        switch score {
        case 0.8...1.0: return "Excellent network health! Your WiFi coverage is strong throughout your space."
        case 0.6..<0.8: return "Good network health with room for improvement in weak areas."
        default: return "Network needs attention. Consider implementing the recommended improvements."
        }
    }
}

struct RecommendationRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    CalibrationResultsView()
        .environmentObject(EnhancedCalibrationViewModel())
}
