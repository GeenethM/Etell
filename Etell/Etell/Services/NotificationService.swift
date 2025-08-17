//
//  NotificationService.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-16.
//

import Foundation
import UserNotifications
import LocalAuthentication

class NotificationService: ObservableObject {
    @Published var isAuthorized = false
    @Published var isFaceIDAvailable = false
    @Published var isFaceIDEnabled = false
    @Published var biometryType: LABiometryType = .none
    
    private let authContext = LAContext()
    
    init() {
        checkNotificationAuthorization()
        checkBiometricAvailability()
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
        }
    }
    
    private func checkNotificationAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func sendLocalNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func checkBiometricAvailability() {
        var error: NSError?
        
        if authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometryType = authContext.biometryType
            isFaceIDAvailable = authContext.biometryType == .faceID || authContext.biometryType == .touchID
        } else {
            biometryType = .none
            isFaceIDAvailable = false
        }
    }
    
    func authenticateWithBiometrics() async -> Bool {
        guard isFaceIDAvailable else { 
            print("🔐 Biometrics not available")
            return false 
        }
        
        // Create a fresh context for each authentication attempt
        let context = LAContext()
        context.localizedFallbackTitle = "Use Password"
        
        do {
            let biometricType = context.biometryType == .faceID ? "Face ID" : "Touch ID"
            print("🔐 Attempting \(biometricType) authentication")
            
            let result = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Use \(biometricType) to sign in to Etell"
            )
            
            print("🔐 Biometric authentication result: \(result)")
            return result
        } catch let error as LAError {
            print("🔐 Biometric authentication error: \(error.localizedDescription)")
            
            switch error.code {
            case .biometryNotAvailable:
                DispatchQueue.main.async {
                    self.isFaceIDAvailable = false
                }
            case .userCancel, .userFallback:
                // User cancelled or chose to use password
                break
            case .biometryLockout:
                print("🔐 Biometry locked out - too many failed attempts")
            default:
                break
            }
            return false
        } catch {
            print("🔐 Unexpected biometric error: \(error.localizedDescription)")
            return false
        }
    }
    
    func enableFaceID() {
        isFaceIDEnabled = true
    }
    
    func disableFaceID() {
        isFaceIDEnabled = false
    }
}
