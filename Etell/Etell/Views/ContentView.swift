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
                    .onAppear { print("🟡 Showing FrontPageView") }
            } else if authService.requiresBiometricAuth {
                // User has Firebase auth but needs biometric authentication
                BiometricLockView()
                    .onAppear { print("🟡 Showing BiometricLockView - Biometric auth required") }
            } else if authService.isAuthenticated {
                // Authenticated user - show main app
                MainTabView()
                    .onAppear { print("🟡 Showing MainTabView - User authenticated") }
            } else {
                // Returning user but not authenticated - show login
                LoginView()
                    .onAppear { print("🟡 Showing LoginView - User not authenticated") }
            }
        }
        .onAppear {
            print("🟡 ContentView appeared - hasSeenWelcome: \(hasSeenWelcome), isAuthenticated: \(authService.isAuthenticated), requiresBiometricAuth: \(authService.requiresBiometricAuth)")
            // Initialize notification service
            if notificationService.isAuthorized {
                notificationService.requestNotificationPermission()
            }
        }
        .onChange(of: authService.isAuthenticated) { newValue in
            print("🟡 Authentication state changed to: \(newValue)")
        }
        .onChange(of: authService.requiresBiometricAuth) { newValue in
            print("🟡 Biometric auth requirement changed to: \(newValue)")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(FirebaseAuthService())
        .environmentObject(NotificationService())
}
