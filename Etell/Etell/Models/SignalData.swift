//
//  SignalData.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-16.
//

import Foundation
import CoreLocation
import FirebaseFirestore

struct Tower: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let signalStrength: Double // 0.0 to 1.0
}

struct RoomCalibration: Identifiable {
    let id = UUID()
    let roomName: String
    let location: CLLocationCoordinate2D
    let signalStrength: Double
    let orientation: Double // compass heading
    let timestamp: Date
}

struct CalibrationResult {
    let averageSignalStrength: Double
    let weakAreas: [RoomCalibration]
    let optimalRouterLocation: CLLocationCoordinate2D?
    let recommendedProducts: [Product]
}

struct SpeedTestResult: Identifiable, Codable {
    var id = UUID()
    let downloadSpeed: Double // Mbps
    let uploadSpeed: Double // Mbps
    let ping: Double // ms
    let timestamp: Date
    let location: String?
    
    // Firestore conversion methods
    func toDictionary() -> [String: Any] {
        return [
            "id": id.uuidString,
            "downloadSpeed": downloadSpeed,
            "uploadSpeed": uploadSpeed,
            "ping": ping,
            "timestamp": timestamp,
            "location": location ?? ""
        ]
    }
    
    init(downloadSpeed: Double, uploadSpeed: Double, ping: Double, timestamp: Date, location: String?) {
        self.id = UUID()
        self.downloadSpeed = downloadSpeed
        self.uploadSpeed = uploadSpeed
        self.ping = ping
        self.timestamp = timestamp
        self.location = location
    }
    
    init?(from dictionary: [String: Any]) {
        guard let idString = dictionary["id"] as? String,
              let id = UUID(uuidString: idString),
              let downloadSpeed = dictionary["downloadSpeed"] as? Double,
              let uploadSpeed = dictionary["uploadSpeed"] as? Double,
              let ping = dictionary["ping"] as? Double else {
            return nil
        }
        
        // Handle timestamp - can be either Date or Firestore Timestamp
        let timestamp: Date
        if let date = dictionary["timestamp"] as? Date {
            timestamp = date
        } else if let firestoreTimestamp = dictionary["timestamp"] as? Timestamp {
            timestamp = firestoreTimestamp.dateValue()
        } else {
            print("⚠️ Could not parse timestamp from: \(dictionary["timestamp"] ?? "nil")")
            return nil
        }
        
        self.id = id
        self.downloadSpeed = downloadSpeed
        self.uploadSpeed = uploadSpeed
        self.ping = ping
        self.timestamp = timestamp
        self.location = dictionary["location"] as? String
    }
}
