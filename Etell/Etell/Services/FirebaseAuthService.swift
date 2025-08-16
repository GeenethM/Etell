//
//  FirebaseAuthService.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-16.
//

import Foundation
import Combine

// Mock Firebase Auth Service
class FirebaseAuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Mock authentication state
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        // Mock implementation - in real app, this would listen to Firebase auth state
        $currentUser
            .map { $0 != nil }
            .assign(to: \.isAuthenticated, on: self)
            .store(in: &cancellables)
    }
    
    func signIn(email: String, password: String) async throws {
        // Mock sign in delay
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Mock user creation
        let mockUser = User(
            id: UUID().uuidString,
            email: email,
            displayName: email.components(separatedBy: "@").first,
            faceIDEnabled: false,
            notificationsEnabled: true
        )
        
        DispatchQueue.main.async {
            self.currentUser = mockUser
        }
    }
    
    func signUp(email: String, password: String) async throws {
        // Mock sign up delay
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Mock user creation
        let mockUser = User(
            id: UUID().uuidString,
            email: email,
            displayName: email.components(separatedBy: "@").first,
            faceIDEnabled: false,
            notificationsEnabled: true
        )
        
        DispatchQueue.main.async {
            self.currentUser = mockUser
        }
    }
    
    func signOut() {
        currentUser = nil
    }
    
    func updateUserSettings(faceIDEnabled: Bool, notificationsEnabled: Bool) {
        guard var user = currentUser else { return }
        user.faceIDEnabled = faceIDEnabled
        user.notificationsEnabled = notificationsEnabled
        currentUser = user
    }
}
