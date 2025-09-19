//
//  NotificationService.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-16.
//

import Foundation
import UserNotifications
import LocalAuthentication

@MainActor
class NotificationService: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var isFaceIDAvailable = false
    @Published var isTouchIDAvailable = false
    @Published var isOtherBiometricAvailable = false
    @Published var isFaceIDEnabled = false
    @Published var biometryType: LABiometryType = .none
    
    private let authContext = LAContext()
    
    override init() {
        super.init()
        checkNotificationAuthorization()
        checkBiometricAvailability()
        requestNotificationPermission()
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            Task { @MainActor in
                self.isAuthorized = granted
            }
        }
    }
    
    private func checkNotificationAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
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
        Task {
            let context = LAContext()
            var error: NSError?
            
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                let biometryType = context.biometryType
                
                self.isFaceIDAvailable = (biometryType == .faceID)
                self.isTouchIDAvailable = (biometryType == .touchID)
                self.isOtherBiometricAvailable = (biometryType == .opticID)
            } else {
                self.isFaceIDAvailable = false
                self.isTouchIDAvailable = false
                self.isOtherBiometricAvailable = false
            }
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
                self.isFaceIDAvailable = false
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
    
    // MARK: - Local Notification Helpers
    
    func scheduleAppointmentReminder(appointmentId: String, appointmentDateTime: Date, appointmentType: String) {
        // Calculate notification times
        let fifteenMinutesBefore = appointmentDateTime.addingTimeInterval(-15 * 60) // 15 minutes before
        let oneDayBefore = appointmentDateTime.addingTimeInterval(-24 * 60 * 60) // 1 day before
        
        // Schedule 1 day before notification
        if oneDayBefore > Date() {
            scheduleLocalNotification(
                identifier: "\(appointmentId)_day_before",
                title: "Appointment Reminder",
                body: "You have a \(appointmentType) appointment tomorrow at \(appointmentDateTime.formatted(date: .omitted, time: .shortened))",
                date: oneDayBefore
            )
        }
        
        // Schedule 15 minutes before notification
        if fifteenMinutesBefore > Date() {
            scheduleLocalNotification(
                identifier: "\(appointmentId)_fifteen_minutes",
                title: "Appointment Starting Soon",
                body: "Your \(appointmentType) appointment starts in 15 minutes",
                date: fifteenMinutesBefore
            )
        }
        
        print("✅ Scheduled local notifications for appointment: \(appointmentId)")
    }
    
    private func scheduleLocalNotification(identifier: String, title: String, body: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        
        // Create date components for the trigger
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("✅ Local notification scheduled: \(identifier) for \(date)")
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate  
extension NotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification tap
        print("📱 Local notification tapped: \(response.notification.request.content.title)")
        completionHandler()
    }
    
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        // Handle banner notifications by showing them as alerts
        completionHandler([.banner, .sound, .badge])
    }
}
