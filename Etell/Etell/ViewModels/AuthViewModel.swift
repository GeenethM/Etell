//
//  AuthViewModel.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-16.
//

import Foundation
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    
    private let authService: FirebaseAuthService
    private let notificationService: NotificationService
    private var cancellables = Set<AnyCancellable>()
    
    var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }
    
    init(authService: FirebaseAuthService, notificationService: NotificationService) {
        self.authService = authService
        self.notificationService = notificationService
    }
    
    func signIn() async {
        guard isFormValid else {
            showErrorMessage("Please enter valid email and password")
            return
        }
        
        isLoading = true
        
        do {
            try await authService.signIn(email: email, password: password)
            
            // Check for Face ID authentication if enabled
            if notificationService.isFaceIDEnabled && notificationService.isFaceIDAvailable {
                let success = await notificationService.authenticateWithBiometrics()
                if !success {
                    authService.signOut()
                    showErrorMessage("Biometric authentication failed")
                    isLoading = false
                    return
                }
            }
        } catch {
            showErrorMessage("Sign in failed: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func signUp() async {
        guard isFormValid else {
            showErrorMessage("Please enter valid email and password")
            return
        }
        
        isLoading = true
        
        do {
            try await authService.signUp(email: email, password: password)
        } catch {
            showErrorMessage("Sign up failed: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func signOut() {
        authService.signOut()
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    func clearError() {
        showError = false
        errorMessage = ""
    }
}
