//
//  Loginpage.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-16.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel: AuthViewModel
    @EnvironmentObject var authService: FirebaseAuthService
    @EnvironmentObject var notificationService: NotificationService
    @State private var showingSignUp = false
    
    init() {
        // Initialize with dependencies - this will be properly injected when view is created
        let authService = FirebaseAuthService()
        let notificationService = NotificationService()
        _viewModel = StateObject(wrappedValue: AuthViewModel(authService: authService, notificationService: notificationService))
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Title
                Text("Welcome to E-tell")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.top, 100)
                
                // Subtitle
                Text("Sign in or create an account to continue")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 8)
                
                VStack(spacing: 20) {
                    // Email Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .padding(.leading, 4)
                        
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
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Password Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .padding(.leading, 4)
                        
                        HStack {
                            Image(systemName: "lock")
                                .foregroundColor(.gray)
                                .frame(width: 20)
                            
                            SecureField("Enter your password", text: $viewModel.password)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Forgot Password
                    HStack {
                        Spacer()
                        Button(action: {
                            print("Forgot password tapped")
                        }) {
                            Text("Forgot password ?")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.top, 4)
                    
                    // Face ID Toggle
                    if notificationService.isFaceIDAvailable {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.gray)
                                .font(.system(size: 16))
                            
                            Text("Enable Face ID for future login")
                                .font(.system(size: 16))
                                .foregroundColor(.black)
                            
                            Spacer()
                            
                            Toggle("", isOn: Binding(
                                get: { authService.currentUser?.faceIDEnabled ?? false },
                                set: { newValue in
                                    authService.updateUserSettings(
                                        faceIDEnabled: newValue,
                                        notificationsEnabled: authService.currentUser?.notificationsEnabled ?? true
                                    )
                                }
                            ))
                            .labelsHidden()
                        }
                        .padding(.top, 20)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 40)
                
                // Login Button
                Button(action: {
                    Task {
                        await viewModel.signIn()
                    }
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        }
                        Text(viewModel.isLoading ? "Signing In..." : "Login")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(viewModel.isFormValid && !viewModel.isLoading ? Color.blue : Color.gray)
                    .cornerRadius(8)
                }
                .disabled(!viewModel.isFormValid || viewModel.isLoading)
                .padding(.horizontal, 40)
                .padding(.top, 30)
                
                // Or text
                Text("or")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .padding(.vertical, 20)
                
                // Sign Up Button
                Button(action: {
                    showingSignUp = true
                }) {
                    Text("Sign Up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage)
        }
        .sheet(isPresented: $showingSignUp) {
            SignUpView()
        }
        .onAppear {
            // Reinitialize viewModel with proper environment objects
            let newViewModel = AuthViewModel(authService: authService, notificationService: notificationService)
            // Note: In a real app, you'd want to handle this dependency injection better
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
