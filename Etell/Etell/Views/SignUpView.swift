//
//  SignUpView.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-16.
//

import SwiftUI

struct SignUpView: View {
    @StateObject private var viewModel: AuthViewModel
    @EnvironmentObject var authService: FirebaseAuthService
    @EnvironmentObject var notificationService: NotificationService
    @Environment(\.dismiss) var dismiss
    @State private var confirmPassword = ""
    
    init() {
        let authService = FirebaseAuthService()
        let notificationService = NotificationService()
        _viewModel = StateObject(wrappedValue: AuthViewModel(authService: authService, notificationService: notificationService))
    }
    
    var isFormValid: Bool {
        viewModel.isFormValid && confirmPassword == viewModel.password && viewModel.password.count >= 6
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Create Account")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Join Etell and get started with fast, reliable internet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // Form Fields
                    VStack(spacing: 20) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            HStack {
                                Image(systemName: "envelope")
                                    .foregroundColor(.gray)
                                    .frame(width: 20)
                                
                                TextField("Enter your email", text: $viewModel.email)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            HStack {
                                Image(systemName: "lock")
                                    .foregroundColor(.gray)
                                    .frame(width: 20)
                                
                                SecureField("Create a password", text: $viewModel.password)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            
                            Text("Password must be at least 6 characters")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Confirm Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            HStack {
                                Image(systemName: "lock")
                                    .foregroundColor(.gray)
                                    .frame(width: 20)
                                
                                SecureField("Confirm your password", text: $confirmPassword)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            
                            if !confirmPassword.isEmpty && confirmPassword != viewModel.password {
                                Text("Passwords do not match")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    // Terms and Conditions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("By creating an account, you agree to our:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Button("Terms of Service") {
                                // Show terms
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                            
                            Text("and")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button("Privacy Policy") {
                                // Show privacy policy
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Sign Up Button
                    Button(action: {
                        Task {
                            await viewModel.signUp()
                            if authService.isAuthenticated {
                                dismiss()
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
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid && !viewModel.isLoading ? Color.blue : Color.gray)
                        .cornerRadius(12)
                    }
                    .disabled(!isFormValid || viewModel.isLoading)
                    
                    // Sign In Link
                    HStack {
                        Text("Already have an account?")
                            .foregroundColor(.secondary)
                        
                        Button("Sign In") {
                            dismiss()
                        }
                        .foregroundColor(.blue)
                    }
                    .font(.subheadline)
                }
                .padding()
            }
            .navigationTitle("Sign Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage)
        }
        .onAppear {
            // Reinitialize viewModel with proper environment objects
            let newViewModel = AuthViewModel(authService: authService, notificationService: notificationService)
        }
    }
}

#Preview {
    SignUpView()
        .environmentObject(FirebaseAuthService())
        .environmentObject(NotificationService())
}
