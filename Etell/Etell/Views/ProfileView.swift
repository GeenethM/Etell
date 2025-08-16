//
//  ProfileView.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-16.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: FirebaseAuthService
    @EnvironmentObject var notificationService: NotificationService
    @State private var showingSignOutAlert = false
    @State private var showingDeleteAccountAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    ProfileHeaderSection()
                    
                    // Settings Sections
                    NotificationSettingsSection()
                    SecuritySettingsSection()
                    AccountSettingsSection()
                    AppSettingsSection()
                    
                    // Sign Out Button
                    SignOutSection()
                }
                .padding()
            }
            .navigationTitle("Profile")
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Sign Out", role: .destructive) {
                authService.signOut()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
            Button("Delete", role: .destructive) {
                // Handle account deletion
                authService.signOut()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
    }
}

struct ProfileHeaderSection: View {
    @EnvironmentObject var authService: FirebaseAuthService
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Image
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                if let imageURL = authService.currentUser?.profileImageURL {
                    AsyncImage(url: URL(string: imageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                }
                
                // Edit Button
                Button(action: {
                    // Handle profile image edit
                }) {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
                .offset(x: 35, y: 35)
            }
            
            // User Info
            VStack(spacing: 4) {
                Text(authService.currentUser?.displayName ?? "User")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(authService.currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Member since \(memberSinceText)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var memberSinceText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: authService.currentUser?.createdAt ?? Date())
    }
}

struct NotificationSettingsSection: View {
    @EnvironmentObject var notificationService: NotificationService
    @EnvironmentObject var authService: FirebaseAuthService
    
    var body: some View {
        SettingsSection(title: "Notifications") {
            SettingsToggleRow(
                title: "Push Notifications",
                subtitle: "Get alerts about your service",
                isOn: Binding(
                    get: { authService.currentUser?.notificationsEnabled ?? false },
                    set: { newValue in
                        authService.updateUserSettings(
                            faceIDEnabled: authService.currentUser?.faceIDEnabled ?? false,
                            notificationsEnabled: newValue
                        )
                        if newValue && !notificationService.isAuthorized {
                            notificationService.requestNotificationPermission()
                        }
                    }
                )
            )
            
            SettingsRow(
                title: "Notification Preferences",
                subtitle: "Customize what notifications you receive",
                icon: "bell.badge"
            ) {
                // Navigate to detailed notification settings
            }
        }
    }
}

struct SecuritySettingsSection: View {
    @EnvironmentObject var notificationService: NotificationService
    @EnvironmentObject var authService: FirebaseAuthService
    
    var body: some View {
        SettingsSection(title: "Security") {
            SettingsToggleRow(
                title: notificationService.biometryType == .faceID ? "Face ID" : "Touch ID",
                subtitle: "Use biometrics to sign in",
                isOn: Binding(
                    get: { authService.currentUser?.faceIDEnabled ?? false },
                    set: { newValue in
                        authService.updateUserSettings(
                            faceIDEnabled: newValue,
                            notificationsEnabled: authService.currentUser?.notificationsEnabled ?? true
                        )
                        if newValue {
                            notificationService.enableFaceID()
                        } else {
                            notificationService.disableFaceID()
                        }
                    }
                )
            )
            .disabled(!notificationService.isFaceIDAvailable)
            
            SettingsRow(
                title: "Change Password",
                subtitle: "Update your account password",
                icon: "key"
            ) {
                // Navigate to change password
            }
            
            SettingsRow(
                title: "Two-Factor Authentication",
                subtitle: "Add an extra layer of security",
                icon: "shield"
            ) {
                // Navigate to 2FA setup
            }
        }
    }
}

struct AccountSettingsSection: View {
    var body: some View {
        SettingsSection(title: "Account") {
            SettingsRow(
                title: "Edit Profile",
                subtitle: "Update your personal information",
                icon: "person"
            ) {
                // Navigate to edit profile
            }
            
            SettingsRow(
                title: "Billing & Plans",
                subtitle: "Manage your subscription",
                icon: "creditcard"
            ) {
                // Navigate to billing
            }
            
            SettingsRow(
                title: "Usage History",
                subtitle: "View your data usage over time",
                icon: "chart.line.uptrend.xyaxis"
            ) {
                // Navigate to usage history
            }
            
            SettingsRow(
                title: "Connected Devices",
                subtitle: "Manage devices on your network",
                icon: "wifi"
            ) {
                // Navigate to device management
            }
        }
    }
}

struct AppSettingsSection: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("temperatureUnit") private var temperatureUnit = "Celsius"
    
    var body: some View {
        SettingsSection(title: "App Settings") {
            SettingsToggleRow(
                title: "Dark Mode",
                subtitle: "Use dark appearance",
                isOn: $isDarkMode
            )
            
            SettingsRow(
                title: "Language",
                subtitle: "English",
                icon: "globe"
            ) {
                // Navigate to language settings
            }
            
            SettingsRow(
                title: "Privacy Policy",
                subtitle: "Read our privacy policy",
                icon: "hand.raised"
            ) {
                // Navigate to privacy policy
            }
            
            SettingsRow(
                title: "Terms of Service",
                subtitle: "Read our terms of service",
                icon: "doc.text"
            ) {
                // Navigate to terms
            }
            
            SettingsRow(
                title: "About",
                subtitle: "App version and information",
                icon: "info.circle"
            ) {
                // Navigate to about page
            }
        }
    }
}

struct SignOutSection: View {
    @EnvironmentObject var authService: FirebaseAuthService
    @Binding var showingSignOutAlert: Bool
    @Binding var showingDeleteAccountAlert: Bool
    
    init() {
        // Create bindings for the parent state
        _showingSignOutAlert = .constant(false)
        _showingDeleteAccountAlert = .constant(false)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                showingSignOutAlert = true
            }) {
                Text("Sign Out")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            
            Button(action: {
                showingDeleteAccountAlert = true
            }) {
                Text("Delete Account")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 8)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct SettingsRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding()
    }
}

// Fix for SignOutSection - Create a separate view to handle the alerts
struct ProfileViewContainer: View {
    @EnvironmentObject var authService: FirebaseAuthService
    @EnvironmentObject var notificationService: NotificationService
    @State private var showingSignOutAlert = false
    @State private var showingDeleteAccountAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    ProfileHeaderSection()
                    NotificationSettingsSection()
                    SecuritySettingsSection()
                    AccountSettingsSection()
                    AppSettingsSection()
                    
                    VStack(spacing: 12) {
                        Button(action: {
                            showingSignOutAlert = true
                        }) {
                            Text("Sign Out")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            showingDeleteAccountAlert = true
                        }) {
                            Text("Delete Account")
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Profile")
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Sign Out", role: .destructive) {
                authService.signOut()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
            Button("Delete", role: .destructive) {
                authService.signOut()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
    }
}

#Preview {
    ProfileViewContainer()
        .environmentObject(FirebaseAuthService())
        .environmentObject(NotificationService())
}
