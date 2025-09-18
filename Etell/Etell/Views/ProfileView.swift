//
//  ProfileView.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-16.
//

import SwiftUI
import PhotosUI

// MARK: - Main Profile View
struct ProfileView: View {
    @EnvironmentObject var authService: FirebaseAuthService
    @EnvironmentObject var notificationService: NotificationService
    @State private var showingSignOutAlert = false
    @State private var showingImagePicker = false
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImage: Image?
    @State private var faceIDEnabled = true
    @State private var notificationsEnabled = true
    @State private var darkModeEnabled = false
    @State private var showingAccountDetails = false
    @State private var showingPasswordChange = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 24) {
                    // Profile Header Card
                    ModernProfileHeader()
                    
                    // Security Settings
                    ModernSecuritySection()
                    
                    // App Preferences
                    ModernPreferencesSection()
                    
                    // Account Management
                    ModernAccountSection()
                    
                    // Logout Section
                    ModernLogoutSection()
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .background(.ultraThinMaterial.opacity(0.5))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .photosPicker(
            isPresented: $showingImagePicker,
            selection: $selectedImage,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: selectedImage) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    if let uiImage = UIImage(data: data) {
                        profileImage = Image(uiImage: uiImage)
                    }
                }
            }
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Sign Out", role: .destructive) {
                print("🟠 Sign Out confirmed - calling authService.signOut()")
                authService.signOut()
                notificationService.disableFaceID()
                print("🟠 Sign out process completed")
            }
            Button("Cancel", role: .cancel) { 
                print("🟠 Sign Out cancelled")
            }
        } message: {
            Text("Are you sure you want to sign out? This will clear all your login data and return you to the login page.")
        }
        .environmentObject(authService)
        .environmentObject(notificationService)
    }
    
    // MARK: - Profile Header
    @ViewBuilder
    private func ModernProfileHeader() -> some View {
        VStack(spacing: 20) {
            // Profile Image with Edit Button
            ZStack {
                Button {
                    showingImagePicker = true
                } label: {
                    Group {
                        if let profileImage {
                            profileImage
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else if let imageURL = authService.currentUser?.profileImageURL {
                            AsyncImage(url: URL(string: imageURL)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 40))
                                            .foregroundStyle(.secondary)
                                    )
                            }
                        } else {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 40))
                                        .foregroundStyle(.secondary)
                                )
                        }
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(.quaternary, lineWidth: 2)
                    )
                }
                
                // Edit Button
                Button {
                    showingImagePicker = true
                } label: {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(.blue.gradient, in: Circle())
                        .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .offset(x: 35, y: 35)
            }
            
            // User Information
            VStack(spacing: 8) {
                Text(authService.currentUser?.displayName ?? "John Smith")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text(authService.currentUser?.email ?? "johnsmith@example.com")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                // Status Badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    
                    Text("Active")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(.green.opacity(0.1), in: Capsule())
            }
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Security Section
    @ViewBuilder
    private func ModernSecuritySection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Security")
                .font(.title3)
                .fontWeight(.bold)
            
            VStack(spacing: 0) {
                ModernToggleRow(
                    icon: "faceid",
                    title: "Face ID",
                    subtitle: "Use Face ID to unlock the app",
                    isOn: $faceIDEnabled,
                    iconColor: .blue
                )
                
                Divider()
                    .padding(.leading, 60)
                
                ModernSettingsRow(
                    icon: "lock.shield",
                    title: "Change Password",
                    subtitle: "Update your account password",
                    iconColor: .orange,
                    showChevron: true
                ) {
                    showingPasswordChange = true
                }
                
                Divider()
                    .padding(.leading, 60)
                
                ModernSettingsRow(
                    icon: "key",
                    title: "Two-Factor Authentication",
                    subtitle: "Add an extra layer of security",
                    iconColor: .green,
                    showChevron: true
                ) {
                    // Handle 2FA
                }
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
    
    // MARK: - Preferences Section
    @ViewBuilder
    private func ModernPreferencesSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Preferences")
                .font(.title3)
                .fontWeight(.bold)
            
            VStack(spacing: 0) {
                ModernToggleRow(
                    icon: "bell.badge",
                    title: "Push Notifications",
                    subtitle: "Receive alerts and updates",
                    isOn: $notificationsEnabled,
                    iconColor: .red
                )
                
                Divider()
                    .padding(.leading, 60)
                
                ModernToggleRow(
                    icon: "moon.fill",
                    title: "Dark Mode",
                    subtitle: "Use dark appearance",
                    isOn: $darkModeEnabled,
                    iconColor: .indigo
                )
                
                Divider()
                    .padding(.leading, 60)
                
                ModernSettingsRow(
                    icon: "globe",
                    title: "Language",
                    subtitle: "English",
                    iconColor: .cyan,
                    showChevron: true
                ) {
                    // Handle language
                }
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
    
    // MARK: - Account Section
    @ViewBuilder
    private func ModernAccountSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account")
                .font(.title3)
                .fontWeight(.bold)
            
            VStack(spacing: 0) {
                ModernSettingsRow(
                    icon: "person.circle",
                    title: "Account Details",
                    subtitle: "Manage your personal information",
                    iconColor: .blue,
                    showChevron: true
                ) {
                    showingAccountDetails = true
                }
                
                Divider()
                    .padding(.leading, 60)
                
                ModernSettingsRow(
                    icon: "creditcard",
                    title: "Billing & Payments",
                    subtitle: "Manage payment methods",
                    iconColor: .green,
                    showChevron: true
                ) {
                    // Handle billing
                }
                
                Divider()
                    .padding(.leading, 60)
                
                ModernSettingsRow(
                    icon: "doc.text",
                    title: "Privacy Policy",
                    subtitle: "Read our privacy policy",
                    iconColor: .purple,
                    showChevron: true
                ) {
                    // Handle privacy policy
                }
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
    
    // MARK: - Logout Section
    @ViewBuilder
    private func ModernLogoutSection() -> some View {
        Button {
            showingSignOutAlert = true
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.title3)
                    .foregroundStyle(.red)
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sign Out")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.red)
                    
                    Text("Sign out of your account")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(.red.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.red.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Modern Settings Row
struct ModernSettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    let showChevron: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(iconColor.gradient)
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Modern Toggle Row
struct ModernToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor.gradient)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
    }
}

#Preview {
    ProfileView()
        .environmentObject(FirebaseAuthService())
        .environmentObject(NotificationService())
}