//
//  SignUpView.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-16.
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authService: FirebaseAuthService
    @EnvironmentObject var notificationService: NotificationService
    @Environment(\.dismiss) var dismiss
    @State private var confirmPassword = ""
    @State private var enableFaceID = false
    @StateObject private var viewModel = AuthViewModel(authService: FirebaseAuthService(), notificationService: NotificationService())
    
    var isFormValid: Bool {
        !viewModel.fullName.isEmpty && viewModel.isFormValid && confirmPassword == viewModel.password && viewModel.password.count >= 6
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Create Account")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Fill the fields and create an account")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // Form Fields
                    VStack(spacing: 24) {
                        // Full Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Full Name")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "envelope")
                                    .foregroundColor(.gray)
                                    .frame(width: 20)
                                
                                TextField("Enter your full name", text: $viewModel.fullName)
                                    .autocapitalization(.words)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                        }
                        
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email Address")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "envelope")
                                    .foregroundColor(.gray)
                                    .frame(width: 20)
                                
                                TextField("Enter your email", text: $viewModel.email)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "lock")
                                    .foregroundColor(.gray)
                                    .frame(width: 20)
                                
                                SecureField("Enter your password", text: $viewModel.password)
                                
                                Button(action: {
                                    // Toggle password visibility if needed
                                }) {
                                    Image(systemName: "eye.slash")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                        }
                        
                        // Confirm Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "lock")
                                    .foregroundColor(.gray)
                                    .frame(width: 20)
                                
                                SecureField("Enter your password", text: $confirmPassword)
                                
                                Button(action: {
                                    // Toggle password visibility if needed
                                }) {
                                    Image(systemName: "eye.slash")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            
                            if !confirmPassword.isEmpty && confirmPassword != viewModel.password {
                                Text("Passwords do not match")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Face ID Toggle
                        HStack(spacing: 12) {
                            Image(systemName: "faceid")
                                .foregroundColor(.gray)
                                .frame(width: 20)
                            
                            Text("Enable Face ID for future login")
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Toggle("", isOn: $enableFaceID)
                                .labelsHidden()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                    
                    // Create Account Button
                    Button(action: {
                        print("📱 SignUpView: Create Account button tapped")
                        print("📱 SignUpView: viewModel.fullName = '\(viewModel.fullName)'")
                        print("📱 SignUpView: viewModel.email = '\(viewModel.email)'")
                        print("📱 SignUpView: Form is valid: \(isFormValid)")
                        Task {
                            // Use the environment authService directly with form data
                            print("📱 SignUpView: Calling authService.signUp directly")
                            do {
                                try await authService.signUp(
                                    email: viewModel.email, 
                                    password: viewModel.password, 
                                    displayName: viewModel.fullName.isEmpty ? nil : viewModel.fullName
                                )
                                print("📱 SignUpView: Direct signup completed successfully")
                                
                                if authService.isAuthenticated {
                                    if enableFaceID {
                                        notificationService.enableFaceID()
                                    }
                                    dismiss()
                                }
                            } catch {
                                print("📱 SignUpView: Direct signup error: \(error.localizedDescription)")
                                // Handle error - you might want to show an alert here
                            }
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            }
                            Text(viewModel.isLoading ? "Creating Account..." : "Create Account")
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isFormValid && !viewModel.isLoading ? Color.blue : Color.gray)
                        .cornerRadius(12)
                    }
                    .disabled(!isFormValid || viewModel.isLoading)
                    
                    // Sign In Link
                    HStack {
                        Text("Already have an account?")
                            .foregroundColor(.secondary)
                        
                        Button("Log In") {
                            dismiss()
                        }
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                    }
                    .font(.subheadline)
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 24)
            }
            .navigationBarHidden(true)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage)
        }
        .onAppear {
            // Update viewModel to use environment objects
            print("📱 SignUpView: onAppear called")
            print("📱 SignUpView: Environment authService: \(ObjectIdentifier(authService))")
            viewModel.updateServices(authService: authService, notificationService: notificationService)
        }
    }
}

#Preview {
    SignUpView()
        .environmentObject(FirebaseAuthService())
        .environmentObject(NotificationService())
}
