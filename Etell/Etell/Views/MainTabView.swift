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
    
    init() {
        // Configure tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.shadowColor = UIColor.separator
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
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
