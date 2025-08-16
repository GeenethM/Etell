//
//  FirebaseAuthService.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-16.
//

import Foundation
import Combine
import Firebase
import FirebaseAuth

class FirebaseAuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    private var cancellables = Set<AnyCancellable>()
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    init() {
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
            DispatchQueue.main.async {
                if let firebaseUser = firebaseUser {
                    // User is signed in
                    print("🔵 User signed in: \(firebaseUser.email ?? "unknown")")
                    self?.currentUser = User(
                        id: firebaseUser.uid,
                        email: firebaseUser.email ?? "",
                        displayName: firebaseUser.displayName,
                        profileImageURL: firebaseUser.photoURL?.absoluteString,
                        faceIDEnabled: false, // You can store this in Firestore
                        notificationsEnabled: true
                    )
                    self?.isAuthenticated = true
                    print("🔵 isAuthenticated set to: \(self?.isAuthenticated ?? false)")
                } else {
                    // User is signed out
                    print("🔵 User signed out - clearing state")
                    self?.currentUser = nil
                    self?.isAuthenticated = false
                    print("🔵 isAuthenticated set to: \(self?.isAuthenticated ?? false)")
                }
            }
        }
    }
    
    func signIn(email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            print("User signed in: \(result.user.uid)")
        } catch {
            print("Sign in error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func signUp(email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            print("User created: \(result.user.uid)")
            
            // Optionally update the display name
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = email.components(separatedBy: "@").first
            try await changeRequest.commitChanges()
            
        } catch {
            print("Sign up error: \(error.localizedDescription)")
            throw error
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
        
        // Clear any other app-specific data that should be removed on logout
        // Note: Don't clear hasSeenWelcome as that's a device-level setting
        
        print("User data cleared successfully")
    }
    
    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
    
    func updateUserSettings(faceIDEnabled: Bool, notificationsEnabled: Bool) {
        guard var user = currentUser else { return }
        user.faceIDEnabled = faceIDEnabled
        user.notificationsEnabled = notificationsEnabled
        currentUser = user
        
        // TODO: Save these settings to Firestore
        // You can implement Firestore storage for user preferences here
    }
    
    func deleteAccount() async throws {
        guard let firebaseUser = Auth.auth().currentUser else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        try await firebaseUser.delete()
    }
}
