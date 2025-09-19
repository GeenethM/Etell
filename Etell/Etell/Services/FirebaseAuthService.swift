//
//  FirebaseAuthService.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-16.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

class FirebaseAuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var requiresBiometricAuth = false // New property for biometric lock
    
    private var cancellables = Set<AnyCancellable>()
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private var isSigningUp = false // Flag to prevent auth listener override during signup
    
    init() {
        // For debugging: Clear any existing auth state
        try? Auth.auth().signOut()
        setupAuthStateListener()
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    private func setupAuthStateListener() {
        // Listen to Firebase auth state changes
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            print("🔵 Auth state changed - User: \(firebaseUser?.email ?? "nil")")
            print("🔵 isSigningUp flag: \(self?.isSigningUp ?? false)")
            DispatchQueue.main.async {
                if let firebaseUser = firebaseUser {
                    // User is signed in
                    print("🔵 User signed in: \(firebaseUser.email ?? "unknown")")
                    print("🔵 DisplayName from Firebase: '\(firebaseUser.displayName ?? "nil")'")
                    
                    // Only update currentUser if we're not in the middle of a signup process
                    if self?.isSigningUp != true {
                        print("🔵 Updating currentUser from auth state listener")
                        // Load user data from Firestore instead of creating from Firebase Auth
                        Task {
                            do {
                                try await self?.loadUserData()
                            } catch {
                                print("🔴 Error loading user data: \(error.localizedDescription)")
                                // Fallback to creating user from Firebase Auth data
                                self?.currentUser = User(
                                    id: firebaseUser.uid,
                                    email: firebaseUser.email ?? "",
                                    displayName: firebaseUser.displayName,
                                    profileImageURL: firebaseUser.photoURL?.absoluteString,
                                    faceIDEnabled: false,
                                    notificationsEnabled: true
                                )
                            }
                        }
                    } else {
                        print("🔵 Skipping currentUser update - signup in progress")
                    }
                    
                    // Check if biometric credentials exist and require authentication
                    if self?.hasBiometricCredentials() == true {
                        print("🔵 Biometric credentials found - requiring biometric auth")
                        self?.requiresBiometricAuth = true
                        self?.isAuthenticated = false // Don't authenticate until biometric check passes
                    } else {
                        print("🔵 No biometric credentials - allowing direct access")
                        self?.requiresBiometricAuth = false
                        self?.isAuthenticated = true
                    }
                    
                    print("🔵 isAuthenticated set to: \(self?.isAuthenticated ?? false)")
                    print("🔵 requiresBiometricAuth set to: \(self?.requiresBiometricAuth ?? false)")
                } else {
                    // User is signed out
                    print("🔵 User signed out - clearing state")
                    self?.currentUser = nil
                    self?.isAuthenticated = false
                    self?.requiresBiometricAuth = false
                    print("🔵 isAuthenticated set to: \(self?.isAuthenticated ?? false)")
                }
            }
        }
    }
    
    func signIn(email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            print("User signed in: \(result.user.uid)")
            
            // Load user data from Firestore after successful sign in
            try await loadUserData()
            
        } catch {
            print("Sign in error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func signUp(email: String, password: String, displayName: String? = nil) async throws {
        do {
            print("🟡 Starting signup with displayName: '\(displayName ?? "nil")'")
            print("🟡 Firebase Auth available: \(Auth.auth() != nil)")
            
            // Set flag to prevent auth listener from overriding our user object
            isSigningUp = true
            
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            print("🟡 User created: \(result.user.uid)")
            
            // Update the display name if provided, otherwise use email prefix
            let changeRequest = result.user.createProfileChangeRequest()
            let nameToSet = displayName ?? email.components(separatedBy: "@").first
            changeRequest.displayName = nameToSet
            print("🟡 About to set displayName to: '\(nameToSet ?? "nil")'")
            
            try await changeRequest.commitChanges()
            print("🟡 DisplayName committed successfully")
            
            // Reload the user to ensure the profile update is reflected
            try await result.user.reload()
            print("🟡 User reloaded after profile update")
            
            // Verify the displayName was set
            if let updatedUser = Auth.auth().currentUser {
                print("🟡 Verification - User displayName after reload: '\(updatedUser.displayName ?? "nil")'")
                
                // Manually update the currentUser with the correct displayName
                DispatchQueue.main.async { [weak self] in
                    print("🟡 Manually updating currentUser with displayName")
                    self?.currentUser = User(
                        id: updatedUser.uid,
                        email: updatedUser.email ?? "",
                        displayName: updatedUser.displayName,
                        profileImageURL: updatedUser.photoURL?.absoluteString,
                        faceIDEnabled: false,
                        notificationsEnabled: true
                    )
                    // Force UI update
                    self?.objectWillChange.send()
                    print("🟡 currentUser updated with displayName: '\(updatedUser.displayName ?? "nil")'")
                    print("🟡 Forced UI update sent")
                    
                    // Clear the signup flag
                    self?.isSigningUp = false
                    print("🟡 isSigningUp flag cleared")
                }
            } else {
                // Clear flag even if user update failed
                isSigningUp = false
            }
            
        } catch {
            // Clear flag on error
            isSigningUp = false
            print("🔴 Sign up error: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Enhanced signUp method with Firestore user data creation
    func signUp(email: String, password: String, displayName: String? = nil, routerNumber: String? = nil, faceIDEnabled: Bool = false) async throws {
        do {
            print("🟡 Starting enhanced signup with displayName: '\(displayName ?? "nil")', routerNumber: '\(routerNumber ?? "nil")', and faceIDEnabled: \(faceIDEnabled)")
            
            // Set flag to prevent auth listener from overriding our user object
            isSigningUp = true
            
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            print("🟡 User created: \(result.user.uid)")
            
            // Update the display name if provided
            let changeRequest = result.user.createProfileChangeRequest()
            let nameToSet = displayName ?? email.components(separatedBy: "@").first
            changeRequest.displayName = nameToSet
            print("🟡 About to set displayName to: '\(nameToSet ?? "nil")'")
            
            try await changeRequest.commitChanges()
            print("🟡 DisplayName committed successfully")
            
            // Reload the user to ensure the profile update is reflected
            try await result.user.reload()
            print("🟡 User reloaded after profile update")
            
            // Create user document in Firestore
            let user = User(
                id: result.user.uid,
                email: email,
                displayName: nameToSet,
                routerNumber: routerNumber,
                faceIDEnabled: faceIDEnabled,
                notificationsEnabled: true
            )
            
            try await createUserDocument(user: user)
            print("🟡 User document created in Firestore")
            
            // Manually update the currentUser
            DispatchQueue.main.async { [weak self] in
                print("🟡 Manually updating currentUser with all data")
                self?.currentUser = user
                self?.objectWillChange.send()
                print("🟡 currentUser updated with routerNumber: '\(routerNumber ?? "nil")'")
                
                // Clear the signup flag
                self?.isSigningUp = false
                print("🟡 isSigningUp flag cleared")
            }
            
        } catch {
            // Clear flag on error
            isSigningUp = false
            print("🔴 Enhanced sign up error: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Create user document in Firestore
    private func createUserDocument(user: User) async throws {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.id)
        
        try await userRef.setData(user.toDictionary())
        print("🟢 User document created successfully in Firestore")
    }
    
    // Load user data from Firestore
    func loadUserData() async throws {
        guard let firebaseUser = Auth.auth().currentUser else {
            throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(firebaseUser.uid)
        
        do {
            let document = try await userRef.getDocument()
            
            if document.exists, let data = document.data() {
                if let user = User.fromDictionary(data, id: firebaseUser.uid) {
                    DispatchQueue.main.async { [weak self] in
                        self?.currentUser = user
                        print("🟢 User data loaded from Firestore: \(user.displayName ?? "No name")")
                    }
                } else {
                    print("🔴 Failed to parse user data from Firestore")
                }
            } else {
                print("⚠️ User document does not exist in Firestore")
                // Create user document if it doesn't exist
                let user = User(
                    id: firebaseUser.uid,
                    email: firebaseUser.email ?? "",
                    displayName: firebaseUser.displayName,
                    faceIDEnabled: false,
                    notificationsEnabled: true
                )
                try await createUserDocument(user: user)
                
                DispatchQueue.main.async { [weak self] in
                    self?.currentUser = user
                }
            }
        } catch {
            print("🔴 Error loading user data: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Method to verify current user's display name
    func getCurrentUserDisplayName() -> String? {
        let displayName = Auth.auth().currentUser?.displayName
        print("🔍 Current user displayName: '\(displayName ?? "nil")'")
        print("🔍 Current user email: '\(Auth.auth().currentUser?.email ?? "nil")'")
        print("🔍 Current user uid: '\(Auth.auth().currentUser?.uid ?? "nil")'")
        return displayName
    }
    
    // Method to refresh user data from Firebase
    func refreshUserProfile() async {
        guard let currentUser = Auth.auth().currentUser else {
            print("🔍 No current user to refresh")
            return
        }
        
        do {
            try await currentUser.reload()
            print("🔍 User profile refreshed successfully")
            print("🔍 Updated displayName: '\(currentUser.displayName ?? "nil")'")
            print("🔍 Updated email: '\(currentUser.email ?? "nil")'")
        } catch {
            print("🔍 Error refreshing user profile: \(error.localizedDescription)")
        }
    }
    
    func signOut() {
        print("🔴 SignOut called - Starting sign out process")
        
        do {
            // Sign out from Firebase
            try Auth.auth().signOut()
            print("🔴 Firebase signOut successful")
            
            // Clear local user data
            currentUser = nil
            isAuthenticated = false
            print("🔴 Local state cleared - isAuthenticated: \(isAuthenticated)")
            
            // Clear any cached data or user defaults
            clearUserData()
            
        } catch {
            print("🔴 Sign out error: \(error.localizedDescription)")
            // Even if Firebase signOut fails, clear local data
            currentUser = nil
            isAuthenticated = false
            clearUserData()
            print("🔴 Local state cleared after error - isAuthenticated: \(isAuthenticated)")
        }
    }
    
    private func clearUserData() {
        // Clear any user-specific cached data
        // Remove any stored preferences that should be cleared on logout
        UserDefaults.standard.removeObject(forKey: "lastKnownLocation")
        UserDefaults.standard.removeObject(forKey: "cachedSpeedTestResults")
        UserDefaults.standard.removeObject(forKey: "userPreferences")
        
        // Clear biometric credentials when signing out completely
        UserDefaults.standard.removeObject(forKey: "biometricEmail")
        UserDefaults.standard.removeObject(forKey: "biometricPassword")
        
        // Clear any other app-specific data that should be removed on logout
        // Note: Don't clear hasSeenWelcome as that's a device-level setting
        
        print("User data cleared successfully")
    }
    
    func completeBiometricAuthentication() {
        print("🔵 Biometric authentication completed - granting access")
        requiresBiometricAuth = false
        isAuthenticated = true
    }
    
    // MARK: - Biometric Authentication Support
    
    func saveBiometricCredentials(email: String, password: String) {
        // In a production app, you should use Keychain for secure storage
        // For demo purposes, we'll use UserDefaults with basic encoding
        UserDefaults.standard.set(email, forKey: "biometricEmail")
        UserDefaults.standard.set(password, forKey: "biometricPassword")
        print("🔐 Biometric credentials saved for: \(email)")
    }
    
    func getBiometricCredentials() -> (email: String, password: String)? {
        guard let email = UserDefaults.standard.string(forKey: "biometricEmail"),
              let password = UserDefaults.standard.string(forKey: "biometricPassword") else {
            print("🔐 No biometric credentials found")
            return nil
        }
        print("🔐 Retrieved biometric credentials for: \(email)")
        return (email: email, password: password)
    }
    
    func hasBiometricCredentials() -> Bool {
        return getBiometricCredentials() != nil
    }
    
    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
    
    func updateUserSettings(faceIDEnabled: Bool, notificationsEnabled: Bool) async throws {
        guard var user = currentUser else { 
            throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }
        
        // Update local user object
        user.faceIDEnabled = faceIDEnabled
        user.notificationsEnabled = notificationsEnabled
        
        // Update Firestore document
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.id)
        
        try await userRef.updateData([
            "faceIDEnabled": faceIDEnabled,
            "notificationsEnabled": notificationsEnabled
        ])
        
        // Update local state after successful Firestore update
        DispatchQueue.main.async { [weak self] in
            self?.currentUser = user
            print("🟢 User settings updated: faceIDEnabled=\(faceIDEnabled), notificationsEnabled=\(notificationsEnabled)")
        }
    }
    
    func deleteAccount() async throws {
        guard let firebaseUser = Auth.auth().currentUser else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        try await firebaseUser.delete()
    }
}
