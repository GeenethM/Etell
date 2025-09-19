//
//  User.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-16.
//

import Foundation
import FirebaseFirestore

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let displayName: String?
    let routerNumber: String?
    let profileImageURL: String?
    let createdAt: Date
    var faceIDEnabled: Bool
    var notificationsEnabled: Bool
    
    init(id: String, email: String, displayName: String? = nil, routerNumber: String? = nil, profileImageURL: String? = nil, faceIDEnabled: Bool = false, notificationsEnabled: Bool = true) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.routerNumber = routerNumber
        self.profileImageURL = profileImageURL
        self.createdAt = Date()
        self.faceIDEnabled = faceIDEnabled
        self.notificationsEnabled = notificationsEnabled
    }
    
    // Convert to dictionary for Firestore
    func toDictionary() -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "email": email,
            "createdAt": Timestamp(date: createdAt),
            "faceIDEnabled": faceIDEnabled,
            "notificationsEnabled": notificationsEnabled
        ]
        
        if let displayName = displayName {
            data["displayName"] = displayName
        }
        
        if let routerNumber = routerNumber {
            data["routerNumber"] = routerNumber
        }
        
        if let profileImageURL = profileImageURL {
            data["profileImageURL"] = profileImageURL
        }
        
        return data
    }
    
    // Create from Firestore document
    static func fromDictionary(_ data: [String: Any], id: String) -> User? {
        guard let email = data["email"] as? String else { return nil }
        
        let displayName = data["displayName"] as? String
        let routerNumber = data["routerNumber"] as? String
        let profileImageURL = data["profileImageURL"] as? String
        let faceIDEnabled = data["faceIDEnabled"] as? Bool ?? false
        let notificationsEnabled = data["notificationsEnabled"] as? Bool ?? true
        
        let createdAt: Date
        if let timestamp = data["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = Date()
        }
        
        return User(
            id: id,
            email: email,
            displayName: displayName,
            routerNumber: routerNumber,
            profileImageURL: profileImageURL,
            faceIDEnabled: faceIDEnabled,
            notificationsEnabled: notificationsEnabled
        )
    }
}
