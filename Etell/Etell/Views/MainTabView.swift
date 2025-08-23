//
//  MainTabView.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-16.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var dashboardViewModel = DashboardViewModel()
    @EnvironmentObject var authService: FirebaseAuthService
    
    var body: some View {
        TabView {
            DashboardView()
                .environmentObject(dashboardViewModel)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            SignalMapView()
                .tabItem {
                    Image(systemName: "map")
                    Text("Map")
                }
            
            AccessoriesStoreView()
                .tabItem {
                    Image(systemName: "bag.fill")
                    Text("Store")
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
