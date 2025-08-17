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
                    .environmentObject(viewModel)
                    .frame(height: 250)
                
                // Controls and Information
                ScrollView {
                    VStack(spacing: 20) {
                        CalibrationInstructions()
                        TowerManagementSection()
                            .environmentObject(viewModel)
                        RoomSelector()
                            .environmentObject(viewModel)
                        CalibrationButton()
                            .environmentObject(viewModel)
                        
                        if viewModel.hasCalibrations {
                            CalibrationsList()
                                .environmentObject(viewModel)
                            ResultsSection()
                                .environmentObject(viewModel)
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
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var showingAddTowerSheet = false
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    
    var body: some View {
        VStack(spacing: 0) {
            // Map Controls Header
            HStack {
                Text("Long press: add • Tap tower: remove")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Reset Towers") {
                    viewModel.clearAllTowers()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            
            Map(position: $cameraPosition) {
                // User location marker
                if let userLocation = viewModel.userLocation {
                    Annotation("Your Location", coordinate: userLocation) {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 20, height: 20)
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                                .frame(width: 20, height: 20)
                            Circle()
                                .stroke(Color.blue, lineWidth: 1)
                                .frame(width: 40, height: 40)
                                .opacity(0.3)
                        }
                    }
                    .annotationTitles(.hidden)
                }
                
                // Cell towers
                ForEach(viewModel.towers) { tower in
                    Annotation(tower.name, coordinate: tower.coordinate) {
                        Button(action: {
                            viewModel.removeTower(tower)
                        }) {
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .fill(signalStrengthColor(tower.signalStrength).opacity(0.2))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "antenna.radiowaves.left.and.right")
                                        .foregroundColor(signalStrengthColor(tower.signalStrength))
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                Text(tower.name)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.white.opacity(0.9))
                                    .cornerRadius(4)
                                    .shadow(radius: 2)
                                Text("\(Int(tower.signalStrength * 100))%")
                                    .font(.caption2)
                                    .foregroundColor(signalStrengthColor(tower.signalStrength))
                                    .fontWeight(.bold)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .annotationTitles(.hidden)
                }
            }
            .mapStyle(.standard(elevation: .flat))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .onMapCameraChange { context in
                // Handle camera changes if needed
            }
            .gesture(
                LongPressGesture(minimumDuration: 0.5)
                    .onEnded { _ in
                        handleMapLongPress()
                    }
            )
            .onAppear {
                updateCameraPosition()
            }
            .onReceive(viewModel.$userLocation) { newLocation in
                updateCameraPosition()
            }
        }
        .sheet(isPresented: $showingAddTowerSheet) {
            if let coordinate = selectedCoordinate {
                AddTowerView(coordinate: coordinate) { tower in
                    viewModel.addTower(tower)
                    showingAddTowerSheet = false
                }
            }
        }
    }
    
    private func signalStrengthColor(_ strength: Double) -> Color {
        switch strength {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .blue
        case 0.4..<0.6: return .orange
        default: return .red
        }
    }
    
    private func handleMapLongPress() {
        // Generate a coordinate near the user's location for the new tower
        if let userLocation = viewModel.userLocation {
            let randomOffset = 0.002 // Small random offset from user location
            let latitude = userLocation.latitude + Double.random(in: -randomOffset...randomOffset)
            let longitude = userLocation.longitude + Double.random(in: -randomOffset...randomOffset)
            
            selectedCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            showingAddTowerSheet = true
        } else {
            // Fallback to San Francisco if no user location
            let latitude = 37.7749 + Double.random(in: -0.002...0.002)
            let longitude = -122.4194 + Double.random(in: -0.002...0.002)
            
            selectedCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            showingAddTowerSheet = true
        }
    }
    
    private func updateCameraPosition() {
        if let userLocation = viewModel.userLocation {
            withAnimation(.easeInOut(duration: 1.0)) {
                cameraPosition = .region(MKCoordinateRegion(
                    center: userLocation,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
            }
        }
    }
}

struct TowerManagementSection: View {
    @EnvironmentObject var viewModel: CalibrationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Cell Towers")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.towers.count) towers")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Long press map to add new towers")
                    Text("• Tap existing towers to remove them")
                    Text("• Different colors show signal quality")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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

struct AddTowerView: View {
    let coordinate: CLLocationCoordinate2D
    let onAdd: (Tower) -> Void
    
    @State private var towerName = ""
    @State private var signalStrength: Double = 0.8
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Tower Details")) {
                    HStack {
                        Text("Name:")
                        TextField("Enter tower name", text: $towerName)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Signal Strength:")
                            Spacer()
                            Text("\(Int(signalStrength * 100))%")
                                .foregroundColor(signalStrengthColor)
                                .fontWeight(.bold)
                        }
                        
                        Slider(value: $signalStrength, in: 0.1...1.0, step: 0.1)
                            .accentColor(signalStrengthColor)
                    }
                }
                
                Section(header: Text("Location")) {
                    HStack {
                        Text("Latitude:")
                        Spacer()
                        Text("\(coordinate.latitude, specifier: "%.6f")")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Longitude:")
                        Spacer()
                        Text("\(coordinate.longitude, specifier: "%.6f")")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Preview")) {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(signalStrengthColor.opacity(0.2))
                                .frame(width: 40, height: 40)
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .foregroundColor(signalStrengthColor)
                                .font(.system(size: 20, weight: .semibold))
                        }
                        
                        VStack(alignment: .leading) {
                            Text(towerName.isEmpty ? "New Tower" : towerName)
                                .fontWeight(.medium)
                            Text("Signal: \(Int(signalStrength * 100))%")
                                .font(.caption)
                                .foregroundColor(signalStrengthColor)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Add Tower")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let tower = Tower(
                            name: towerName.isEmpty ? "Tower \(Int.random(in: 1000...9999))" : towerName,
                            coordinate: coordinate,
                            signalStrength: signalStrength
                        )
                        onAdd(tower)
                    }
                    .fontWeight(.semibold)
                    .disabled(false) // Always enabled since we have a fallback name
                }
            }
        }
        .onAppear {
            // Generate a default name
            if towerName.isEmpty {
                towerName = "Tower \(Int.random(in: 100...999))"
            }
        }
    }
    
    private var signalStrengthColor: Color {
        switch signalStrength {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .blue
        case 0.4..<0.6: return .orange
        default: return .red
        }
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
