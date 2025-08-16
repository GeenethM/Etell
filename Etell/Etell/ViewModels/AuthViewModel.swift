//
//  AuthViewModel.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-16.
//

import Foundation
import Combine
import Firebase
import FirebaseAuth

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
    
    // Mutable references for environment object updates
    private var _authService: FirebaseAuthService
    private var _notificationService: NotificationService
    
    var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@") && password.count >= 6
    }
    
    init(authService: FirebaseAuthService, notificationService: NotificationService) {
        self.authService = authService
        self.notificationService = notificationService
        self._authService = authService
        self._notificationService = notificationService
    }
    
    func updateServices(authService: FirebaseAuthService, notificationService: NotificationService) {
        self._authService = authService
        self._notificationService = notificationService
    }
    
    func signIn() async {
        guard isFormValid else {
            showErrorMessage("Please enter a valid email and password (minimum 6 characters)")
            return
        }
        
        isLoading = true
        
        do {
            try await _authService.signIn(email: email, password: password)
            
            // Check for Face ID authentication if enabled
            if _notificationService.isFaceIDEnabled && _notificationService.isFaceIDAvailable {
                let success = await _notificationService.authenticateWithBiometrics()
                if !success {
                    _authService.signOut()
                    showErrorMessage("Biometric authentication failed")
                    isLoading = false
                    return
                }
            }
        } catch {
            showErrorMessage(friendlyErrorMessage(from: error))
        }
        
        isLoading = false
    }
    
    func signUp() async {
        guard isFormValid else {
            showErrorMessage("Please enter a valid email and password (minimum 6 characters)")
            return
        }
        
        isLoading = true
        
        do {
            try await _authService.signUp(email: email, password: password)
        } catch {
            showErrorMessage(friendlyErrorMessage(from: error))
        }
        
        isLoading = false
    }
    
    func resetPassword() async {
        guard !email.isEmpty && email.contains("@") else {
            showErrorMessage("Please enter a valid email address")
            return
        }
        
        isLoading = true
        
        do {
            try await _authService.resetPassword(email: email)
            showErrorMessage("Password reset email sent! Check your inbox.")
        } catch {
            showErrorMessage(friendlyErrorMessage(from: error))
        }
        
        isLoading = false
    }
    
    func signOut() {
        _authService.signOut()
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    func clearError() {
        showError = false
        errorMessage = ""
    }
    
    private func friendlyErrorMessage(from error: Error) -> String {
        if let authError = error as NSError? {
            switch authError.code {
            case AuthErrorCode.emailAlreadyInUse.rawValue:
                return "This email address is already in use. Try signing in instead."
            case AuthErrorCode.invalidEmail.rawValue:
                return "Please enter a valid email address."
            case AuthErrorCode.userNotFound.rawValue:
                return "No account found with this email. Please sign up first."
            case AuthErrorCode.wrongPassword.rawValue:
                return "Incorrect password. Please try again."
            case AuthErrorCode.weakPassword.rawValue:
                return "Password should be at least 6 characters long."
            case AuthErrorCode.networkError.rawValue:
                return "Network error. Please check your internet connection."
            case AuthErrorCode.tooManyRequests.rawValue:
                return "Too many failed attempts. Please try again later."
            case AuthErrorCode.userDisabled.rawValue:
                return "This account has been disabled. Please contact support."
            default:
                return authError.localizedDescription
            }
        }
        return error.localizedDescription
    }
}
