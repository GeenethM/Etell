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
    @Published var fullName = ""
    @Published var routerNumber = ""
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var enableFaceID = false
    
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
        print("🔧 AuthViewModel: updateServices called")
        print("🔧 AuthViewModel: Original _authService: \(ObjectIdentifier(self._authService))")
        print("🔧 AuthViewModel: New authService: \(ObjectIdentifier(authService))")
        self._authService = authService
        self._notificationService = notificationService
        print("🔧 AuthViewModel: Services updated successfully")
    }
    
    func signIn() async {
        guard isFormValid else {
            showErrorMessage("Please enter a valid email and password (minimum 6 characters)")
            return
        }
        
        isLoading = true
        
        do {
            try await _authService.signIn(email: email, password: password)
            
            // Save Face ID preference and credentials if enabled
            if enableFaceID {
                try await _authService.updateUserSettings(
                    faceIDEnabled: true,
                    notificationsEnabled: _authService.currentUser?.notificationsEnabled ?? true
                )
                _authService.saveBiometricCredentials(email: email, password: password)
            }
            
            // Complete biometric authentication if required (e.g., app restart scenario)
            if _authService.requiresBiometricAuth {
                _authService.completeBiometricAuthentication()
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
            // Pass the fullName as displayName to Firebase
            print("🟠 AuthViewModel: About to signup with fullName: '\(fullName)'")
            print("🟠 AuthViewModel: Email: '\(email)', Password length: \(password.count)")
            print("🟠 AuthViewModel: Using _authService instance: \(ObjectIdentifier(_authService))")
            try await _authService.signUp(email: email, password: password, displayName: fullName.isEmpty ? nil : fullName)
            print("🟠 AuthViewModel: Signup completed successfully")
            
            // Save Face ID preference if enabled
            if enableFaceID {
                try await _authService.updateUserSettings(
                    faceIDEnabled: true,
                    notificationsEnabled: true
                )
                _authService.saveBiometricCredentials(email: email, password: password)
            }
            
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
        resetLoginState()
    }
    
    func resetLoginState() {
        // Reset all login-related state when signing out
        email = ""
        password = ""
        enableFaceID = false
        isLoading = false
        clearError()
    }
    
    func signInWithBiometrics() async {
        print("🔐 Starting biometric authentication")
        
        // Check if biometrics are available
        guard _notificationService.isFaceIDAvailable else {
            showErrorMessage("Biometric authentication is not available on this device.")
            return
        }
        
        // Check if we have saved credentials
        guard _authService.hasBiometricCredentials() else {
            showErrorMessage("No biometric credentials found. Please sign in with your password first and enable Face ID.")
            return
        }
        
        isLoading = true
        
        // Authenticate with biometrics
        let biometricSuccess = await _notificationService.authenticateWithBiometrics()
        
        if biometricSuccess {
            print("🔐 Biometric authentication successful - retrieving credentials")
            
            // Get stored credentials
            if let credentials = _authService.getBiometricCredentials() {
                do {
                    // Sign in with stored credentials
                    try await _authService.signIn(email: credentials.email, password: credentials.password)
                    
                    // Complete biometric authentication
                    _authService.completeBiometricAuthentication()
                    
                    print("🔐 Successfully signed in with biometric authentication")
                } catch {
                    showErrorMessage("Failed to sign in with stored credentials: \(friendlyErrorMessage(from: error))")
                }
            } else {
                showErrorMessage("Failed to retrieve stored credentials. Please sign in with your password.")
            }
        } else {
            showErrorMessage("Biometric authentication failed. Please try again or sign in with your password.")
        }
        
        isLoading = false
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
