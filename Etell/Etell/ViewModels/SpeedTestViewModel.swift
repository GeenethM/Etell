//
//  SpeedTestViewModel.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-16.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore

@MainActor
class SpeedTestViewModel: ObservableObject {
    @Published var isRunning = false
    @Published var currentTest: TestPhase = .idle
    @Published var downloadSpeed: Double = 0
    @Published var uploadSpeed: Double = 0
    @Published var ping: Double = 0
    @Published var testResults: [SpeedTestResult] = []
    @Published var progress: Double = 0
    
    private let db = Firestore.firestore()
    
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
        // Initialize with empty state - will load data when view appears and user is authenticated
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
        
        // Save result to Firebase
        let result = SpeedTestResult(
            downloadSpeed: downloadSpeed,
            uploadSpeed: uploadSpeed,
            ping: ping,
            timestamp: Date(),
            location: "Current Location"
        )
        
        // Save to Firebase and update local array
        await saveSpeedTestResult(result)
        
        // Add to local array for immediate UI update
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
    
    // MARK: - Firebase Methods
    
    private func saveSpeedTestResult(_ result: SpeedTestResult) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user found - cannot save speed test result")
            return
        }
        
        do {
            let data = result.toDictionary()
            print("💾 Saving speed test result for user: \(userId)")
            print("💾 Result data: \(data)")
            
            try await db.collection("users")
                .document(userId)
                .collection("speedTests")
                .document(result.id.uuidString)
                .setData(data)
            
            print("✅ Speed test result saved successfully")
        } catch {
            print("❌ Error saving speed test result: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    private func loadUserSpeedTestHistory() async {
        // Wait a bit for authentication state to stabilize if needed
        var retryCount = 0
        let maxRetries = 3
        
        while retryCount < maxRetries {
            guard let userId = Auth.auth().currentUser?.uid else {
                print("❌ No authenticated user found (attempt \(retryCount + 1)/\(maxRetries)) - cannot load speed test history")
                
                if retryCount < maxRetries - 1 {
                    // Wait a bit for auth state to update
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    retryCount += 1
                    continue
                } else {
                    testResults = []
                    return
                }
            }
            
            // User is authenticated, proceed with loading
            break
        }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            testResults = []
            return
        }
        
        do {
            print("📱 Loading speed test history for user: \(userId)")
            
            let querySnapshot = try await db.collection("users")
                .document(userId)
                .collection("speedTests")
                .order(by: "timestamp", descending: true)
                .limit(to: 50) // Limit to last 50 tests
                .getDocuments()
            
            var loadedResults: [SpeedTestResult] = []
            
            for document in querySnapshot.documents {
                let data = document.data()
                print("📄 Document data: \(data)")
                
                if let result = SpeedTestResult(from: data) {
                    loadedResults.append(result)
                } else {
                    print("⚠️ Failed to parse speed test result from document: \(document.documentID)")
                    print("⚠️ Document data: \(data)")
                }
            }
            
            self.testResults = loadedResults
            print("✅ Loaded \(loadedResults.count) speed test results from Firebase")
            
        } catch {
            print("❌ Error loading speed test history: \(error.localizedDescription)")
            print("❌ Full error: \(error)")
            self.testResults = []
        }
    }
    
    func refreshHistory() async {
        await loadUserSpeedTestHistory()
    }
    
    func clearHistory() {
        testResults.removeAll()
    }
}
