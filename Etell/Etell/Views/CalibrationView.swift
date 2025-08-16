//
//  CalibrationView.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-16.
//

import SwiftUI
import MapKit

struct CalibrationView: View {
    @StateObject private var viewModel: CalibrationViewModel
    
    init() {
        let signalService = SignalCalibrationService()
        _viewModel = StateObject(wrappedValue: CalibrationViewModel(signalService: signalService))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Map View
                MapView()
                    .frame(height: 250)
                
                // Controls and Information
                ScrollView {
                    VStack(spacing: 20) {
                        CalibrationInstructions()
                        RoomSelector()
                        CalibrationButton()
                        
                        if viewModel.hasCalibrations {
                            CalibrationsList()
                            ResultsSection()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Signal Calibration")
            .onAppear {
                viewModel.startCalibration()
            }
            .sheet(isPresented: $viewModel.showingResult) {
                if let result = viewModel.calibrationResult {
                    CalibrationResultView(result: result)
                }
            }
        }
    }
}

struct MapView: View {
    @EnvironmentObject var viewModel: CalibrationViewModel
    
    var body: some View {
        Map(coordinateRegion: $viewModel.mapRegion, annotationItems: viewModel.towers) { tower in
            MapAnnotation(coordinate: tower.coordinate) {
                VStack {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .foregroundColor(.red)
                        .font(.title2)
                    Text(tower.name)
                        .font(.caption)
                        .padding(.horizontal, 4)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(4)
                }
            }
        }
        .overlay(
            // User location indicator
            Circle()
                .fill(Color.blue)
                .frame(width: 16, height: 16)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
                .opacity(viewModel.userLocation != nil ? 1 : 0),
            alignment: .center
        )
    }
}

struct CalibrationInstructions: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How to Calibrate")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("1. Select a room from the list below")
                Text("2. Go to that room in your home")
                Text("3. Tap 'Calibrate Signal' to measure strength")
                Text("4. Repeat for all rooms")
                Text("5. View results and recommendations")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RoomSelector: View {
    @EnvironmentObject var viewModel: CalibrationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Room")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(viewModel.commonRooms, id: \.self) { room in
                    Button(action: {
                        viewModel.selectRoom(room)
                    }) {
                        Text(room)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(viewModel.currentRoom == room ? Color.blue : Color(.systemGray5))
                            .foregroundColor(viewModel.currentRoom == room ? .white : .primary)
                            .cornerRadius(8)
                    }
                }
            }
            
            HStack {
                TextField("Custom room name", text: $viewModel.currentRoom)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !viewModel.currentRoom.isEmpty {
                    Button("Clear") {
                        viewModel.currentRoom = ""
                    }
                    .font(.caption)
                }
            }
        }
    }
}

struct CalibrationButton: View {
    @EnvironmentObject var viewModel: CalibrationViewModel
    
    var body: some View {
        Button(action: {
            Task {
                await viewModel.calibrateCurrentRoom()
            }
        }) {
            HStack {
                if viewModel.isCalibrating {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "wifi")
                }
                
                Text(viewModel.isCalibrating ? "Calibrating..." : "Calibrate Signal")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.currentRoom.isEmpty || viewModel.isCalibrating ? Color.gray : Color.blue)
            .cornerRadius(12)
        }
        .disabled(viewModel.currentRoom.isEmpty || viewModel.isCalibrating)
    }
}

struct CalibrationsList: View {
    @EnvironmentObject var viewModel: CalibrationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Calibrated Rooms (\(viewModel.calibrationCount))")
                    .font(.headline)
                Spacer()
                Button("Clear All") {
                    viewModel.clearCalibrations()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
            
            ForEach(viewModel.calibrations) { calibration in
                CalibrationRow(calibration: calibration)
            }
        }
    }
}

struct CalibrationRow: View {
    let calibration: RoomCalibration
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(calibration.roomName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Signal: \(signalQuality)")
                    .font(.caption)
                    .foregroundColor(signalColor)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(calibration.signalStrength * 100, specifier: "%.0f")%")
                    .font(.headline)
                    .foregroundColor(signalColor)
                
                Text(DateFormatter.timeOnly.string(from: calibration.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var signalQuality: String {
        switch calibration.signalStrength {
        case 0.8...1.0: return "Excellent"
        case 0.6..<0.8: return "Good"
        case 0.4..<0.6: return "Fair"
        case 0.2..<0.4: return "Poor"
        default: return "Very Poor"
        }
    }
    
    private var signalColor: Color {
        switch calibration.signalStrength {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .blue
        case 0.4..<0.6: return .orange
        default: return .red
        }
    }
}

struct ResultsSection: View {
    @EnvironmentObject var viewModel: CalibrationViewModel
    
    var body: some View {
        Button(action: {
            viewModel.generateReport()
        }) {
            Text("Generate Report & Recommendations")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .cornerRadius(12)
        }
    }
}

struct CalibrationResultView: View {
    let result: CalibrationResult
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Overall Signal Quality
                    OverallSignalCard(result: result)
                    
                    // Weak Areas
                    if !result.weakAreas.isEmpty {
                        WeakAreasSection(weakAreas: result.weakAreas)
                    }
                    
                    // Optimal Router Location
                    if result.optimalRouterLocation != nil {
                        OptimalLocationSection()
                    }
                    
                    // Product Recommendations
                    if !result.recommendedProducts.isEmpty {
                        RecommendationsSection(products: result.recommendedProducts)
                    }
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
                }
            }
        }
    }
}

struct OverallSignalCard: View {
    let result: CalibrationResult
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Overall Signal Quality")
                .font(.headline)
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: result.averageSignalStrength)
                    .stroke(signalColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                VStack {
                    Text("\(result.averageSignalStrength * 100, specifier: "%.0f")%")
                        .font(.title)
                        .fontWeight(.bold)
                    Text(qualityText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var signalColor: Color {
        switch result.averageSignalStrength {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .blue
        case 0.4..<0.6: return .orange
        default: return .red
        }
    }
    
    private var qualityText: String {
        switch result.averageSignalStrength {
        case 0.8...1.0: return "Excellent"
        case 0.6..<0.8: return "Good"
        case 0.4..<0.6: return "Fair"
        default: return "Poor"
        }
    }
}

struct WeakAreasSection: View {
    let weakAreas: [RoomCalibration]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Areas Needing Improvement")
                .font(.headline)
            
            ForEach(weakAreas) { area in
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading) {
                        Text(area.roomName)
                            .fontWeight(.medium)
                        Text("Signal: \(area.signalStrength * 100, specifier: "%.0f")%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct OptimalLocationSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Optimal Router Placement")
                .font(.headline)
            
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.green)
                Text("Based on your calibrations, we've identified the best location for your router.")
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RecommendationsSection: View {
    let products: [Product]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommended Products")
                .font(.headline)
            
            Text("To improve coverage in weak areas:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ForEach(products) { product in
                NavigationLink(destination: ProductDetailView(product: product)) {
                    HStack {
                        AsyncImage(url: URL(string: product.imageURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Rectangle()
                                .foregroundColor(.gray.opacity(0.3))
                        }
                        .frame(width: 50, height: 50)
                        .cornerRadius(8)
                        
                        VStack(alignment: .leading) {
                            Text(product.name)
                                .fontWeight(.medium)
                            Text("$\(product.price, specifier: "%.2f")")
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ProductDetailView: View {
    let product: Product
    
    var body: some View {
        VStack {
            Text(product.name)
                .font(.title)
            Text(product.description)
            Text("$\(product.price, specifier: "%.2f")")
                .font(.title2)
                .foregroundColor(.blue)
        }
        .padding()
        .navigationTitle(product.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension DateFormatter {
    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    CalibrationView()
}
