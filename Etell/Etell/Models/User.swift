//
//  User.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-16.
//

import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let displayName: String?
    let profileImageURL: String?
    let createdAt: Date
    var faceIDEnabled: Bool
    var notificationsEnabled: Bool
    
    init(id: String, email: String, displayName: String? = nil, profileImageURL: String? = nil, faceIDEnabled: Bool = false, notificationsEnabled: Bool = true) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.profileImageURL = profileImageURL
        self.createdAt = Date()
        self.faceIDEnabled = faceIDEnabled
        self.notificationsEnabled = notificationsEnabled
    }
}
