//
//  ContentView.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-16.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: FirebaseAuthService
    @EnvironmentObject var notificationService: NotificationService
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    
    var body: some View {
        Group {
            if !hasSeenWelcome {
                // First time user - show welcome screen
                FrontPageView()
            } else if authService.isAuthenticated {
                // Authenticated user - show main app
                MainTabView()
            } else {
                // Returning user but not authenticated - show login
                LoginView()
            }
        }
        .onAppear {
            // Initialize notification service
            if notificationService.isAuthorized {
                notificationService.requestNotificationPermission()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(FirebaseAuthService())
        .environmentObject(NotificationService())
}
