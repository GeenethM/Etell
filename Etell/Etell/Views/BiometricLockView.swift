//
//  BiometricLockView.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-17.
//

import SwiftUI
import LocalAuthentication

struct BiometricLockView: View {
    @EnvironmentObject var authService: FirebaseAuthService
    @EnvironmentObject var notificationService: NotificationService
    @State private var isAuthenticating = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // App Icon/Logo
                Image(systemName: "lock.shield")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                
                VStack(spacing: 16) {
                    Text("App Locked")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Please authenticate with \(notificationService.biometryType == .faceID ? "Face ID" : "Touch ID") to continue")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Authenticate Button
                Button(action: {
                    authenticateWithBiometrics()
                }) {
                    HStack(spacing: 12) {
                        if isAuthenticating {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: notificationService.biometryType == .faceID ? "faceid" : "touchid")
                                .font(.system(size: 20))
                        }
                        
                        Text(isAuthenticating ? "Authenticating..." : "Unlock with \(notificationService.biometryType == .faceID ? "Face ID" : "Touch ID")")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                .disabled(isAuthenticating)
                .padding(.horizontal, 40)
                
                // Sign Out Option
                Button(action: {
                    authService.signOut()
                }) {
                    Text("Sign Out")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            // Automatically try to authenticate when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                authenticateWithBiometrics()
            }
        }
        .alert("Authentication Failed", isPresented: $showError) {
            Button("Try Again") {
                authenticateWithBiometrics()
            }
            Button("Sign Out") {
                authService.signOut()
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func authenticateWithBiometrics() {
        isAuthenticating = true
        
        Task {
            let success = await notificationService.authenticateWithBiometrics()
            
            DispatchQueue.main.async {
                isAuthenticating = false
                
                if success {
                    // Authentication successful - unlock the app
                    authService.completeBiometricAuthentication()
                } else {
                    // Authentication failed
                    errorMessage = "Biometric authentication failed. Please try again or sign out to use a different account."
                    showError = true
                }
            }
        }
    }
}

struct BiometricLockView_Previews: PreviewProvider {
    static var previews: some View {
        BiometricLockView()
            .environmentObject(FirebaseAuthService())
            .environmentObject(NotificationService())
    }
}
