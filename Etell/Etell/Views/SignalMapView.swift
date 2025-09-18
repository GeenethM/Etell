//
//  SignalMapView.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-23.
//

import SwiftUI
import MapKit
import CoreLocation

struct SignalTower: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let name: String
    let signalStrength: Double // 0.0 to 1.0
    let range: Double // in meters
    let provider: String
    let technology: String // 4G, 5G, etc.
    let address: String
}

struct SearchLocation: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D
}

enum MapDisplayMode: String, CaseIterable {
    case standard = "Standard"
    case satellite = "Satellite"
    case hybrid = "Hybrid"
    
    var mapStyle: MapStyle {
        switch self {
        case .standard: return .standard
        case .satellite: return .imagery
        case .hybrid: return .hybrid
        }
    }
}

struct SignalMapView: View {
    @State private var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612), // Colombo, Sri Lanka
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    
    @State private var signalTowers: [SignalTower] = [
        SignalTower(coordinate: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612), name: "Colombo Central", signalStrength: 0.9, range: 2000, provider: "Dialog", technology: "5G", address: "World Trade Center, Colombo 01"),
        SignalTower(coordinate: CLLocationCoordinate2D(latitude: 6.9344, longitude: 79.8428), name: "Fort Tower", signalStrength: 0.85, range: 1800, provider: "Mobitel", technology: "4G", address: "Fort Railway Station, Colombo 01"),
        SignalTower(coordinate: CLLocationCoordinate2D(latitude: 6.9147, longitude: 79.8731), name: "Bambalapitiya", signalStrength: 0.75, range: 1500, provider: "Hutch", technology: "4G", address: "Galle Road, Bambalapitiya"),
        SignalTower(coordinate: CLLocationCoordinate2D(latitude: 6.9497, longitude: 79.8608), name: "Slave Island", signalStrength: 0.8, range: 1600, provider: "Airtel", technology: "4G", address: "Sir Chittampalam A. Gardiner Mawatha"),
        SignalTower(coordinate: CLLocationCoordinate2D(latitude: 6.9065, longitude: 79.8487), name: "Wellawatte", signalStrength: 0.7, range: 1400, provider: "Dialog", technology: "4G", address: "Galle Road, Wellawatte"),
        SignalTower(coordinate: CLLocationCoordinate2D(latitude: 6.9583, longitude: 79.8750), name: "Kotahena", signalStrength: 0.65, range: 1200, provider: "Mobitel", technology: "4G", address: "Kotahena Junction"),
        SignalTower(coordinate: CLLocationCoordinate2D(latitude: 6.9022, longitude: 79.8607), name: "Mount Lavinia", signalStrength: 0.82, range: 1700, provider: "Dialog", technology: "5G", address: "Mount Lavinia Hotel Area"),
        SignalTower(coordinate: CLLocationCoordinate2D(latitude: 6.9390, longitude: 79.8540), name: "Pettah", signalStrength: 0.78, range: 1550, provider: "Hutch", technology: "4G", address: "Main Street, Pettah"),
    ]
    
    @State private var selectedTower: SignalTower?
    @State private var showTowerRanges = true
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var isSearchLoading = false
    @State private var searchResults: [SearchLocation] = []
    @State private var mapDisplayMode: MapDisplayMode = .standard
    @State private var showingMapOptions = false
    @State private var showingFilters = false
    @State private var selectedProviders: Set<String> = []
    @State private var selectedTechnologies: Set<String> = []
    @State private var minSignalStrength: Double = 0.0
    
    private let locationManager = CLLocationManager()
    private let searchCompleter = MKLocalSearchCompleter()
    
    var filteredTowers: [SignalTower] {
        signalTowers.filter { tower in
            let providerMatch = selectedProviders.isEmpty || selectedProviders.contains(tower.provider)
            let technologyMatch = selectedTechnologies.isEmpty || selectedTechnologies.contains(tower.technology)
            let signalMatch = tower.signalStrength >= minSignalStrength
            
            return providerMatch && technologyMatch && signalMatch
        }
    }
    
    var availableProviders: [String] {
        Array(Set(signalTowers.map { $0.provider })).sorted()
    }
    
    var availableTechnologies: [String] {
        Array(Set(signalTowers.map { $0.technology })).sorted()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Modern Map Implementation
                Map(position: $cameraPosition) {
                    // User Location
                    UserAnnotation()
                    
                    // Signal Tower Annotations
                    ForEach(filteredTowers) { tower in
                        Annotation(tower.name, coordinate: tower.coordinate) {
                            ModernSignalTowerAnnotation(
                                tower: tower,
                                isSelected: selectedTower?.id == tower.id
                            ) {
                                selectedTower = tower
                            }
                        }
                    }
                    
                    // Signal Range Overlays
                    if showTowerRanges {
                        ForEach(filteredTowers) { tower in
                            MapCircle(center: tower.coordinate, radius: tower.range)
                                .foregroundStyle(signalColor(for: tower.signalStrength).opacity(0.2))
                                .stroke(signalColor(for: tower.signalStrength).opacity(0.4), lineWidth: 1)
                        }
                    }
                }
                .mapStyle(mapDisplayMode.mapStyle)
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }
                
                // Search Overlay
                VStack(spacing: 0) {
                    ModernSearchBar(
                        searchText: $searchText,
                        isSearching: $isSearching,
                        isLoading: $isSearchLoading,
                        searchResults: searchResults,
                        onSearchResultTap: { location in
                            moveToLocation(location.coordinate)
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isSearching = false
                                searchText = location.name
                            }
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    Spacer()
                    
                    // Bottom Controls
                    HStack {
                        // Map Style Button
                        Button {
                            showingMapOptions = true
                        } label: {
                            Image(systemName: "map")
                                .font(.title2)
                                .foregroundStyle(.primary)
                        }
                        .buttonStyle(ModernMapControlStyle())
                        
                        // Filter Button
                        Button {
                            showingFilters = true
                        } label: {
                            Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                .font(.title2)
                                .foregroundStyle(hasActiveFilters ? .blue : .primary)
                        }
                        .buttonStyle(ModernMapControlStyle())
                        
                        Spacer()
                        
                        // Range Toggle
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showTowerRanges.toggle()
                            }
                        } label: {
                            Image(systemName: showTowerRanges ? "eye.fill" : "eye.slash.fill")
                                .font(.title2)
                                .foregroundStyle(showTowerRanges ? .blue : .primary)
                        }
                        .buttonStyle(ModernMapControlStyle())
                        
                        // Refresh Button
                        Button {
                            refreshTowerData()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.title2)
                                .foregroundStyle(.primary)
                        }
                        .buttonStyle(ModernMapControlStyle())
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100) // Space for tab bar
                }
                
                // Tower Details Card
                if let tower = selectedTower {
                    VStack {
                        Spacer()
                        ModernTowerDetailsCard(tower: tower) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedTower = nil
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 160) // Space for controls and tab bar
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Signal Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .onChange(of: searchText) { oldValue, newValue in
                if !newValue.isEmpty {
                    performSearch(query: newValue)
                } else {
                    searchResults = []
                    isSearching = false
                    isSearchLoading = false
                }
            }
            .sheet(isPresented: $showingMapOptions) {
                MapOptionsView(selectedMode: $mapDisplayMode)
                    .presentationDetents([.height(200)])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingFilters) {
                FilterOptionsView(
                    selectedProviders: $selectedProviders,
                    selectedTechnologies: $selectedTechnologies,
                    minSignalStrength: $minSignalStrength,
                    availableProviders: availableProviders,
                    availableTechnologies: availableTechnologies
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
    }
    
    private var hasActiveFilters: Bool {
        !selectedProviders.isEmpty || !selectedTechnologies.isEmpty || minSignalStrength > 0.0
    }
    
    private func signalColor(for strength: Double) -> Color {
        switch strength {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .orange
        default: return .red
        }
    }
    
    private func moveToLocation(_ coordinate: CLLocationCoordinate2D) {
        withAnimation(.easeInOut(duration: 0.8)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
    }
    
    private func performSearch(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            isSearching = false
            isSearchLoading = false
            return
        }
        
        // Set searching and loading state
        isSearching = true
        isSearchLoading = true
        
        // Simulate a brief search delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Search through existing signal towers
            let filteredTowers = signalTowers.filter { tower in
                tower.name.localizedCaseInsensitiveContains(query) ||
                tower.address.localizedCaseInsensitiveContains(query) ||
                tower.provider.localizedCaseInsensitiveContains(query) ||
                tower.technology.localizedCaseInsensitiveContains(query)
            }
            
            // Convert towers to search results
            searchResults = filteredTowers.map { tower in
                SearchLocation(
                    name: tower.name,
                    subtitle: "\(tower.provider) • \(tower.technology) • \(tower.address)",
                    coordinate: tower.coordinate
                )
            }
            
            // Clear loading state
            isSearchLoading = false
            
            print("Tower search completed: \(searchResults.count) results for '\(query)'")
        }
    }
    
    private func refreshTowerData() {
        withAnimation(.easeInOut(duration: 0.5)) {
            for i in signalTowers.indices {
                signalTowers[i] = SignalTower(
                    coordinate: signalTowers[i].coordinate,
                    name: signalTowers[i].name,
                    signalStrength: Double.random(in: 0.5...1.0),
                    range: signalTowers[i].range,
                    provider: signalTowers[i].provider,
                    technology: signalTowers[i].technology,
                    address: signalTowers[i].address
                )
            }
        }
    }
}

// MARK: - Modern UI Components

struct ModernSearchBar: View {
    @Binding var searchText: String
    @Binding var isSearching: Bool
    @Binding var isLoading: Bool
    let searchResults: [SearchLocation]
    let onSearchResultTap: (SearchLocation) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Search Input
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 16, height: 16)
                
                TextField("Search towers...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSearching = true
                        }
                    }
                    .onSubmit {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSearching = false
                        }
                    }
                    .onChange(of: searchText) { oldValue, newValue in
                        if !newValue.isEmpty {
                            isSearching = true
                        }
                    }
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(width: 16, height: 16)
                        .transition(.scale.combined(with: .opacity))
                } else if !searchText.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            searchText = ""
                            isSearching = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 16))
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.quaternary, lineWidth: 0.5)
            )
            
            // Search Results Dropdown
            if isSearching && (!searchResults.isEmpty || isLoading) {
                VStack(spacing: 0) {
                    if isLoading && searchResults.isEmpty {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Searching...")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    } else if searchResults.isEmpty && !isLoading {
                        HStack {
                            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.secondary)
                            Text("No towers found")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    } else {
                        ForEach(searchResults.prefix(5)) { location in
                            Button {
                                onSearchResultTap(location)
                            } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "location")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(.blue)
                                        .frame(width: 16, height: 16)
                                        .padding(.top, 2)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(location.name)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundStyle(.primary)
                                            .lineLimit(1)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        if !location.subtitle.isEmpty {
                                            Text(location.subtitle)
                                                .font(.system(size: 13))
                                                .foregroundStyle(.secondary)
                                                .lineLimit(2)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    }
                                    
                                    Image(systemName: "arrow.up.left")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(.tertiary)
                                        .padding(.top, 2)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            
                            if location.id != searchResults.prefix(5).last?.id {
                                Divider()
                                    .padding(.leading, 44) // Align with text content
                            }
                        }
                    }
                }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.quaternary, lineWidth: 0.5)
                )
                .padding(.top, 4)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSearching)
        .animation(.easeInOut(duration: 0.2), value: searchText.isEmpty)
    }
}

struct ModernSignalTowerAnnotation: View {
    let tower: SignalTower
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background Circle
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: isSelected ? 44 : 32, height: isSelected ? 44 : 32)
                    .overlay(
                        Circle()
                            .stroke(signalColor, lineWidth: isSelected ? 3 : 2)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                // Tower Icon
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: isSelected ? 16 : 12, weight: .semibold))
                    .foregroundStyle(signalColor)
                
                // Technology Badge
                if tower.technology == "5G" && isSelected {
                    Text("5G")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(.purple, in: Capsule())
                        .offset(x: 18, y: -18)
                }
            }
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    private var signalColor: Color {
        switch tower.signalStrength {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .orange
        default: return .red
        }
    }
}

struct ModernMapControlStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 44, height: 44)
            .background(.ultraThinMaterial, in: Circle())
            .overlay(
                Circle()
                    .stroke(.quaternary, lineWidth: 0.5)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ModernTowerDetailsCard: View {
    let tower: SignalTower
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(tower.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        
                        if tower.technology == "5G" {
                            Text("5G")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.purple, in: Capsule())
                        }
                    }
                    
                    Text(tower.provider)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            Divider()
                .padding(.horizontal, 20)
            
            // Content
            VStack(spacing: 16) {
                // Signal Strength
                VStack(alignment: .leading, spacing: 8) {
                    Text("Signal Strength")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 12) {
                        // Signal Bars
                        HStack(spacing: 4) {
                            ForEach(0..<5, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(index < Int(tower.signalStrength * 5) ? signalColor : Color.gray.opacity(0.3))
                                    .frame(width: 6, height: CGFloat(8 + index * 2))
                            }
                        }
                        
                        Text("\(Int(tower.signalStrength * 100))%")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(signalColor)
                        
                        Spacer()
                        
                        Text(signalQuality)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(signalColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(signalColor.opacity(0.1), in: Capsule())
                    }
                }
                
                // Metrics Grid
                HStack(spacing: 16) {
                    MetricView(
                        title: "Technology",
                        value: tower.technology,
                        icon: "antenna.radiowaves.left.and.right",
                        color: tower.technology == "5G" ? .purple : .blue
                    )
                    
                    MetricView(
                        title: "Range",
                        value: "\(formatDistance(tower.range))",
                        icon: "dot.radiowaves.left.and.right",
                        color: .orange
                    )
                    
                    MetricView(
                        title: "Provider",
                        value: tower.provider,
                        icon: "building.2",
                        color: .green
                    )
                }
                
                // Address
                if !tower.address.isEmpty {
                    HStack {
                        Image(systemName: "location")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text(tower.address)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                        
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.quaternary, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
    }
    
    private var signalColor: Color {
        switch tower.signalStrength {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .orange
        default: return .red
        }
    }
    
    private var signalQuality: String {
        switch tower.signalStrength {
        case 0.8...1.0: return "Excellent"
        case 0.6..<0.8: return "Good"
        case 0.4..<0.6: return "Fair"
        default: return "Poor"
        }
    }
    
    private func formatDistance(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.1f km", meters / 1000)
        } else {
            return "\(Int(meters)) m"
        }
    }
}

struct MetricView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 24, height: 24)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(1)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct MapOptionsView: View {
    @Binding var selectedMode: MapDisplayMode
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                ForEach(MapDisplayMode.allCases, id: \.self) { mode in
                    Button {
                        selectedMode = mode
                        dismiss()
                    } label: {
                        HStack {
                            Text(mode.rawValue)
                                .font(.body)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            if selectedMode == mode {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                                    .font(.body)
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(selectedMode == mode ? .blue.opacity(0.1) : .clear, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .navigationTitle("Map Style")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct FilterOptionsView: View {
    @Binding var selectedProviders: Set<String>
    @Binding var selectedTechnologies: Set<String>
    @Binding var minSignalStrength: Double
    let availableProviders: [String]
    let availableTechnologies: [String]
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Signal Strength Filter
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Minimum Signal Strength")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("0%")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Spacer()
                                
                                Text("\(Int(minSignalStrength * 100))%")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.blue)
                                
                                Spacer()
                                
                                Text("100%")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Slider(value: $minSignalStrength, in: 0...1, step: 0.1)
                                .accentColor(.blue)
                        }
                    }
                    
                    // Provider Filter
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Providers")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(availableProviders, id: \.self) { provider in
                                FilterChip(
                                    title: provider,
                                    isSelected: selectedProviders.contains(provider)
                                ) {
                                    if selectedProviders.contains(provider) {
                                        selectedProviders.remove(provider)
                                    } else {
                                        selectedProviders.insert(provider)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Technology Filter
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Technology")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(availableTechnologies, id: \.self) { technology in
                                FilterChip(
                                    title: technology,
                                    isSelected: selectedTechnologies.contains(technology)
                                ) {
                                    if selectedTechnologies.contains(technology) {
                                        selectedTechnologies.remove(technology)
                                    } else {
                                        selectedTechnologies.insert(technology)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        selectedProviders.removeAll()
                        selectedTechnologies.removeAll()
                        minSignalStrength = 0.0
                    }
                }
                
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

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ? Color.blue : Color.secondary.opacity(0.3),
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        SignalMapView()
    }
}
