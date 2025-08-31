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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with Back button and Title
                HStack {
                    Button(action: {
                        // Handle back action if needed
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Text("Profile")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // Invisible spacer to center the title
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .opacity(0)
                        Text("Back")
                            .opacity(0)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header
                        VStack(spacing: 16) {
                            // Profile Image with edit functionality
                            ZStack {
                                Button(action: {
                                    showingImagePicker = true
                                }) {
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
                                                Image(systemName: "person.circle.fill")
                                                    .font(.system(size: 60))
                                                    .foregroundColor(.blue)
                                            }
                                        } else {
                                            Image(systemName: "person.circle.fill")
                                                .font(.system(size: 60))
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                                }
                            }
                            
                            // User Info
                            VStack(spacing: 4) {
                                Text(authService.currentUser?.displayName ?? "John Smith")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text(authService.currentUser?.email ?? "johnsmith@example.com")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 20)
                        
                        VStack(spacing: 16) {
                            // Account Details
                            SettingsRow(
                                icon: "person.circle",
                                title: "Account Details",
                                showChevron: true
                            ) {
                                // Handle account details
                            }
                            
                            Divider()
                            
                            // Security Section
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("SECURITY")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .fontWeight(.medium)
                                    Spacer()
                                }
                                .padding(.horizontal)
                                
                                VStack(spacing: 0) {
                                    ToggleRow(
                                        icon: "faceid",
                                        title: "Enable Face ID",
                                        isOn: $faceIDEnabled
                                    )
                                    
                                    Divider()
                                        .padding(.leading, 60)
                                    
                                    SettingsRow(
                                        icon: "lock",
                                        title: "Change Password",
                                        showChevron: true
                                    ) {
                                        // Handle password change
                                    }
                                }
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            
                            // App Preferences Section
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("APP PREFERENCES")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .fontWeight(.medium)
                                    Spacer()
                                }
                                .padding(.horizontal)
                                
                                VStack(spacing: 0) {
                                    ToggleRow(
                                        icon: "bell",
                                        title: "Notifications",
                                        isOn: $notificationsEnabled
                                    )
                                    
                                    Divider()
                                        .padding(.leading, 60)
                                    
                                    ToggleRow(
                                        icon: "moon",
                                        title: "Dark Mode",
                                        isOn: $darkModeEnabled
                                    )
                                }
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            
                            // Logout Button
                            Button(action: {
                                showingSignOutAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "arrow.right.square")
                                        .foregroundColor(.red)
                                    Text("Logout")
                                        .foregroundColor(.red)
                                        .fontWeight(.medium)
                                    Spacer()
                                }
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .padding(.top, 20)
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 100) // Space for tab bar
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .photosPicker(
            isPresented: $showingImagePicker,
            selection: $selectedImage,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: selectedImage) { newItem in
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
    }
}

// MARK: - Supporting View Components

struct SettingsRow: View {
    let icon: String
    let title: String
    let showChevron: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding()
    }
}

#Preview {
    ProfileView()
        .environmentObject(FirebaseAuthService())
        .environmentObject(NotificationService())
}