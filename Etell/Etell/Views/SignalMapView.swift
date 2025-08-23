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
}

struct SignalMapView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612), // Colombo, Sri Lanka
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    @State private var signalTowers: [SignalTower] = [
        SignalTower(coordinate: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612), name: "Colombo Central", signalStrength: 0.9, range: 2000, provider: "Dialog", technology: "5G"),
        SignalTower(coordinate: CLLocationCoordinate2D(latitude: 6.9344, longitude: 79.8428), name: "Fort Tower", signalStrength: 0.85, range: 1800, provider: "Mobitel", technology: "4G"),
        SignalTower(coordinate: CLLocationCoordinate2D(latitude: 6.9147, longitude: 79.8731), name: "Bambalapitiya", signalStrength: 0.75, range: 1500, provider: "Hutch", technology: "4G"),
        SignalTower(coordinate: CLLocationCoordinate2D(latitude: 6.9497, longitude: 79.8608), name: "Slave Island", signalStrength: 0.8, range: 1600, provider: "Airtel", technology: "4G"),
        SignalTower(coordinate: CLLocationCoordinate2D(latitude: 6.9065, longitude: 79.8487), name: "Wellawatte", signalStrength: 0.7, range: 1400, provider: "Dialog", technology: "4G"),
        SignalTower(coordinate: CLLocationCoordinate2D(latitude: 6.9583, longitude: 79.8750), name: "Kotahena", signalStrength: 0.65, range: 1200, provider: "Mobitel", technology: "4G")
    ]
    
    @State private var selectedTower: SignalTower?
    @State private var showTowerRanges = true
    
    var body: some View {
        NavigationView {
            ZStack {
                Map(coordinateRegion: $region, interactionModes: .all, showsUserLocation: true, annotationItems: signalTowers) { tower in
                    MapAnnotation(coordinate: tower.coordinate) {
                        SignalTowerAnnotation(tower: tower, isSelected: selectedTower?.id == tower.id) {
                            selectedTower = tower
                        }
                    }
                }
                .overlay(
                    // Signal Range Overlays
                    ForEach(signalTowers) { tower in
                        if showTowerRanges {
                            SignalRangeOverlay(tower: tower, region: region)
                        }
                    }
                )
                .ignoresSafeArea()
                
                VStack {
                    // Top Controls
                    HStack {
                        Spacer()
                        Button(action: {
                            showTowerRanges.toggle()
                        }) {
                            Image(systemName: showTowerRanges ? "eye.fill" : "eye.slash.fill")
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding(.trailing)
                    }
                    .padding(.top)
                    
                    Spacer()
                    
                    // Tower Details Card
                    if let tower = selectedTower {
                        TowerDetailsCard(tower: tower) {
                            selectedTower = nil
                        }
                        .padding()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .navigationTitle("Signal Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        // Simulate refreshing tower data
                        refreshTowerData()
                    }
                }
            }
        }
    }
    
    private func refreshTowerData() {
        // Simulate updating signal strengths
        for i in signalTowers.indices {
            signalTowers[i] = SignalTower(
                coordinate: signalTowers[i].coordinate,
                name: signalTowers[i].name,
                signalStrength: Double.random(in: 0.5...1.0),
                range: signalTowers[i].range,
                provider: signalTowers[i].provider,
                technology: signalTowers[i].technology
            )
        }
    }
}

struct SignalTowerAnnotation: View {
    let tower: SignalTower
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(signalColor)
                    .frame(width: isSelected ? 35 : 25, height: isSelected ? 35 : 25)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: isSelected ? 3 : 2)
                    )
                
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundColor(.white)
                    .font(.system(size: isSelected ? 14 : 10, weight: .bold))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var signalColor: Color {
        switch tower.signalStrength {
        case 0.8...1.0:
            return .green
        case 0.6..<0.8:
            return .orange
        default:
            return .red
        }
    }
}

struct SignalRangeOverlay: View {
    let tower: SignalTower
    let region: MKCoordinateRegion
    
    var body: some View {
        Circle()
            .fill(signalColor.opacity(0.2))
            .overlay(
                Circle()
                    .stroke(signalColor.opacity(0.4), lineWidth: 1)
            )
            .frame(width: rangeSize, height: rangeSize)
            .position(coordinateToPoint(tower.coordinate))
    }
    
    private var signalColor: Color {
        switch tower.signalStrength {
        case 0.8...1.0:
            return .green
        case 0.6..<0.8:
            return .orange
        default:
            return .red
        }
    }
    
    private var rangeSize: CGFloat {
        // Convert range in meters to screen points (simplified calculation)
        let metersPerDegree = 111_320.0 // Approximate meters per degree of latitude
        let degreesForRange = tower.range / metersPerDegree
        let screenPointsPerDegree = UIScreen.main.bounds.width / region.span.longitudeDelta
        return CGFloat(degreesForRange * screenPointsPerDegree)
    }
    
    private func coordinateToPoint(_ coordinate: CLLocationCoordinate2D) -> CGPoint {
        let screenBounds = UIScreen.main.bounds
        
        // Calculate relative position within the visible region
        let deltaLat = coordinate.latitude - region.center.latitude
        let deltaLon = coordinate.longitude - region.center.longitude
        
        // Convert to screen coordinates
        let x = screenBounds.width * (0.5 + deltaLon / region.span.longitudeDelta)
        let y = screenBounds.height * (0.5 - deltaLat / region.span.latitudeDelta)
        
        return CGPoint(x: x, y: y)
    }
}

struct TowerDetailsCard: View {
    let tower: SignalTower
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tower.name)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(tower.provider)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title2)
                }
            }
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Signal Strength")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        ForEach(0..<5, id: \.self) { index in
                            Image(systemName: "circle.fill")
                                .foregroundColor(index < Int(tower.signalStrength * 5) ? signalColor : Color.gray.opacity(0.3))
                                .font(.caption)
                        }
                        Text("\(Int(tower.signalStrength * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Technology")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(tower.technology)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(tower.technology == "5G" ? .purple : .blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Range")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(tower.range))m")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
    }
    
    private var signalColor: Color {
        switch tower.signalStrength {
        case 0.8...1.0:
            return .green
        case 0.6..<0.8:
            return .orange
        default:
            return .red
        }
    }
}

#Preview {
    SignalMapView()
}
