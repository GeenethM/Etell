//
//  FAQ.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-16.
//

import Foundation

struct FAQ: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
    
    static let mockFAQs: [FAQ] = [
        FAQ(question: "How do I reset my router?", answer: "Unplug the router for 30 seconds, then plug it back in. Wait 2-3 minutes for it to fully restart."),
        FAQ(question: "Why is my internet slow?", answer: "Check if multiple devices are using bandwidth, restart your router, or contact support for a speed test."),
        FAQ(question: "How do I change my WiFi password?", answer: "Access your router's admin panel through your browser, navigate to WiFi settings, and update the password."),
        FAQ(question: "What should I do if I have no internet connection?", answer: "Check all cable connections, restart your modem and router, and contact support if the issue persists."),
        FAQ(question: "How can I improve my WiFi signal?", answer: "Position your router centrally, away from obstacles, and consider using our signal calibration tool for optimal placement.")
    ]
}

struct ContactForm {
    var name: String = ""
    var email: String = ""
    var subject: String = ""
    var message: String = ""
}
