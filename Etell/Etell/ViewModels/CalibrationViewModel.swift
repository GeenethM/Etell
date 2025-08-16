//
//  CalibrationViewModel.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-16.
//

import Foundation
import MapKit
import Combine

@MainActor
class CalibrationViewModel: ObservableObject {
    @Published var currentRoom = ""
    @Published var isCalibrating = false
    @Published var calibrationResult: CalibrationResult?
    @Published var showingResult = false
    @Published var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    private let signalService: SignalCalibrationService
    private var cancellables = Set<AnyCancellable>()
    
    var commonRooms = ["Living Room", "Kitchen", "Bedroom", "Office", "Bathroom", "Dining Room", "Basement", "Garage"]
    
    var hasCalibrations: Bool {
        !signalService.calibrations.isEmpty
    }
    
    var calibrationCount: Int {
        signalService.calibrations.count
    }
    
    init(signalService: SignalCalibrationService) {
        self.signalService = signalService
        
        // Update map region when user location changes
        signalService.$userLocation
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.mapRegion = MKCoordinateRegion(
                    center: location,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
            .store(in: &cancellables)
    }
    
    func startCalibration() {
        signalService.startLocationUpdates()
    }
    
    func calibrateCurrentRoom() async {
        guard !currentRoom.isEmpty else { return }
        
        isCalibrating = true
        
        // Simulate calibration process
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        signalService.calibrateSignalInRoom(roomName: currentRoom)
        currentRoom = ""
        isCalibrating = false
    }
    
    func generateReport() {
        calibrationResult = signalService.generateCalibrationResult()
        showingResult = true
    }
    
    func clearCalibrations() {
        signalService.clearCalibrations()
        calibrationResult = nil
        showingResult = false
    }
    
    func selectRoom(_ room: String) {
        currentRoom = room
    }
    
    var towers: [Tower] {
        signalService.towers
    }
    
    var calibrations: [RoomCalibration] {
        signalService.calibrations
    }
    
    var userLocation: CLLocationCoordinate2D? {
        signalService.userLocation
    }
    
    var currentHeading: Double {
        signalService.currentHeading
    }
}
