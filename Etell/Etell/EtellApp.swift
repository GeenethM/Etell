//
//  EtellApp.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-16.
//

import SwiftUI
import Firebase
import UserNotifications

@main
struct EtellApp: App {
    @StateObject private var authService = FirebaseAuthService()
    @StateObject private var notificationService = NotificationService()
    
    init() {
        FirebaseApp.configure()
        
        // Configure local notifications
        UNUserNotificationCenter.current().delegate = notificationService
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(notificationService)
        }
    }
}




//wift
////  Etell
////
////  Created by Geeneth 013 on 2025-08-16.
////
//
//import SwiftUI
//
//@main
//struct EtellApp: App {
//    var body: some Scene {
//        WindowGroup {
//            FrontPageView()
//        }
//    }
//}
