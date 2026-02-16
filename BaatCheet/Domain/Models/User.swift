//
//  User.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import Foundation

// MARK: - User Model
struct User: Identifiable, Codable, Equatable {
    let id: String
    let email: String
    var firstName: String?
    var lastName: String?
    var avatar: String?
    var role: String?
    var tier: String?
    
    // MARK: - Computed Properties
    var displayName: String {
        if let first = firstName, let last = lastName, !first.isEmpty, !last.isEmpty {
            return "\(first) \(last)"
        } else if let first = firstName, !first.isEmpty {
            return first
        } else if let last = lastName, !last.isEmpty {
            return last
        }
        return email.components(separatedBy: "@").first ?? email
    }
    
    var initials: String {
        if let first = firstName?.first, let last = lastName?.first {
            return "\(first)\(last)".uppercased()
        } else if let first = firstName, !first.isEmpty {
            return String(first.prefix(2)).uppercased()
        }
        return String(email.prefix(2)).uppercased()
    }
    
    var isFreeTier: Bool {
        tier == "free" || tier == nil
    }
    
    var isPro: Bool {
        tier == "pro"
    }
    
    var isAdmin: Bool {
        role == "admin"
    }
}

// MARK: - User Summary Model
struct UserSummary: Identifiable, Codable, Equatable {
    let id: String
    var username: String?
    var firstName: String?
    var lastName: String?
    var email: String?
    var avatar: String?
    
    // MARK: - Computed Properties
    var displayName: String {
        if let first = firstName, let last = lastName, !first.isEmpty, !last.isEmpty {
            return "\(first) \(last)"
        } else if let first = firstName, !first.isEmpty {
            return first
        } else if let username = username, !username.isEmpty {
            return username
        } else if let email = email {
            return email.components(separatedBy: "@").first ?? email
        }
        return "Unknown"
    }
    
    var initials: String {
        if let first = firstName?.first, let last = lastName?.first {
            return "\(first)\(last)".uppercased()
        } else if let first = firstName, !first.isEmpty {
            return String(first.prefix(2)).uppercased()
        } else if let username = username, !username.isEmpty {
            return String(username.prefix(2)).uppercased()
        }
        return "??"
    }
}

// MARK: - User Profile Model
struct UserProfile: Identifiable, Codable, Equatable {
    let id: String
    let email: String
    var firstName: String?
    var lastName: String?
    var avatar: String?
    
    // MARK: - Computed Properties
    var displayName: String {
        if let first = firstName, let last = lastName, !first.isEmpty, !last.isEmpty {
            return "\(first) \(last)"
        } else if let first = firstName, !first.isEmpty {
            return first
        }
        return email.components(separatedBy: "@").first ?? email
    }
    
    var initials: String {
        if let first = firstName?.first, let last = lastName?.first {
            return "\(first)\(last)".uppercased()
        } else if let first = firstName, !first.isEmpty {
            return String(first.prefix(2)).uppercased()
        }
        return String(email.prefix(2)).uppercased()
    }
    
    // MARK: - Init from User
    init(id: String, email: String, firstName: String?, lastName: String?, avatar: String?) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.avatar = avatar
    }
    
    init(from user: User) {
        self.id = user.id
        self.email = user.email
        self.firstName = user.firstName
        self.lastName = user.lastName
        self.avatar = user.avatar
    }
}
