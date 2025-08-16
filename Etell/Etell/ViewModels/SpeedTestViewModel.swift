//
//  SpeedTestViewModel.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-16.
//

import Foundation

@MainActor
class SpeedTestViewModel: ObservableObject {
    @Published var isRunning = false
    @Published var currentTest: TestPhase = .idle
    @Published var downloadSpeed: Double = 0
    @Published var uploadSpeed: Double = 0
    @Published var ping: Double = 0
    @Published var testResults: [SpeedTestResult] = []
    @Published var progress: Double = 0
    
    enum TestPhase {
        case idle
        case ping
        case download
        case upload
        case completed
        
        var displayText: String {
            switch self {
            case .idle: return "Ready to test"
            case .ping: return "Testing ping..."
            case .download: return "Testing download speed..."
            case .upload: return "Testing upload speed..."
            case .completed: return "Test completed"
            }
        }
    }
    
    init() {
        loadTestHistory()
    }
    
    func startSpeedTest() async {
        guard !isRunning else { return }
        
        isRunning = true
        progress = 0
        downloadSpeed = 0
        uploadSpeed = 0
        ping = 0
        
        // Ping Test
        currentTest = .ping
        await simulateTest(duration: 2, updateValue: { self.ping = Double.random(in: 10...50) })
        
        // Download Test
        currentTest = .download
        await simulateTest(duration: 5, updateValue: { self.downloadSpeed = Double.random(in: 50...200) })
        
        // Upload Test
        currentTest = .upload
        await simulateTest(duration: 5, updateValue: { self.uploadSpeed = Double.random(in: 20...100) })
        
        // Complete
        currentTest = .completed
        progress = 1.0
        
        // Save result
        let result = SpeedTestResult(
            downloadSpeed: downloadSpeed,
            uploadSpeed: uploadSpeed,
            ping: ping,
            timestamp: Date(),
            location: "Current Location"
        )
        testResults.insert(result, at: 0)
        
        // Reset after delay
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        isRunning = false
        currentTest = .idle
        progress = 0
    }
    
    private func simulateTest(duration: Double, updateValue: @escaping () -> Void) async {
        let steps = 20
        let stepDuration = duration / Double(steps)
        
        for i in 0..<steps {
            try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
            updateValue()
            progress = Double(i + 1) / Double(steps * 3) // 3 phases total
        }
    }
    
    private func loadTestHistory() {
        // Mock test history
        testResults = [
            SpeedTestResult(downloadSpeed: 95.5, uploadSpeed: 45.2, ping: 15.3, timestamp: Date().addingTimeInterval(-3600), location: "Home"),
            SpeedTestResult(downloadSpeed: 87.3, uploadSpeed: 42.1, ping: 18.7, timestamp: Date().addingTimeInterval(-86400), location: "Home"),
            SpeedTestResult(downloadSpeed: 102.1, uploadSpeed: 48.9, ping: 12.4, timestamp: Date().addingTimeInterval(-172800), location: "Home")
        ]
    }
    
    func clearHistory() {
        testResults.removeAll()
    }
}
