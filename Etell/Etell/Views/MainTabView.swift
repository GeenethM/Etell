//
//  MainTabView.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-16.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var dashboardViewModel = DashboardViewModel()
    @StateObject private var signalService = SignalCalibrationService()
    @StateObject private var calibrationViewModel: CalibrationViewModel
    @EnvironmentObject var authService: FirebaseAuthService
    
    init() {
        let service = SignalCalibrationService()
        self._signalService = StateObject(wrappedValue: service)
        self._calibrationViewModel = StateObject(wrappedValue: CalibrationViewModel(signalService: service))
    }
    
    var body: some View {
        TabView {
            DashboardView()
                .environmentObject(dashboardViewModel)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            CalibrationView()
                .environmentObject(calibrationViewModel)
                .tabItem {
                    Image(systemName: "map")
                    Text("Map")
                }
            
            CalibrationView()
                .environmentObject(calibrationViewModel)
                .tabItem {
                    Image(systemName: "camera.metering.center.weighted")
                    Text("Calibration")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
        .accentColor(.blue)
    }
}
