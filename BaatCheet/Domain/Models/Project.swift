//
//  Project.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import Foundation

// MARK: - Project Model
struct Project: Identifiable, Equatable {
    let id: String
    var name: String
    var description: String?
    var color: String?
    var icon: String?
    var emoji: String?
    let conversationCount: Int
    var instructions: String?
    var customInstructions: String?
    
    // Collaboration fields
    var myRole: String?
    var isOwner: Bool
    var canEdit: Bool
    var canDelete: Bool
    var canInvite: Bool
    var canManageRoles: Bool
    var collaboratorCount: Int
    var owner: UserSummary?
    var collaborators: [Collaborator]
    
    // AI Context
    var context: String?
    var keyTopics: [String]
    var techStack: [String]
    var goals: [String]
    var lastContextUpdate: String?
    
    // MARK: - Computed Properties
    var displayEmoji: String {
        emoji ?? "📁"
    }
    
    var displayName: String {
        name.isEmpty ? "Untitled Project" : name
    }
    
    var roleDisplayName: String {
        switch myRole {
        case "admin": return "Admin"
        case "moderator": return "Moderator"
        case "viewer": return "Viewer"
        default: return isOwner ? "Owner" : "Member"
        }
    }
    
    var isShared: Bool {
        collaboratorCount > 0 || !isOwner
    }
    
    var hasCustomInstructions: Bool {
        customInstructions?.isEmpty == false
    }
    
    var hasContext: Bool {
        context?.isEmpty == false
    }
    
    // MARK: - Permission Helpers
    func hasPermission(_ permission: ProjectPermission) -> Bool {
        switch permission {
        case .view:
            return true
        case .edit:
            return canEdit
        case .delete:
            return canDelete
        case .invite:
            return canInvite
        case .manageRoles:
            return canManageRoles
        }
    }
}

// MARK: - Project Permission
enum ProjectPermission {
    case view
    case edit
    case delete
    case invite
    case manageRoles
}

// MARK: - Collaborator Model
struct Collaborator: Identifiable, Equatable {
    let id: String
    let userId: String
    var role: String
    var user: UserSummary
    var addedAt: String?
    var lastAccessedAt: String?
    var accessCount: Int
    var canEdit: Bool
    var canDelete: Bool
    var canInvite: Bool
    var canManageRoles: Bool
    
    // MARK: - Computed Properties
    var roleDisplayName: String {
        switch role {
        case "admin": return "Admin"
        case "moderator": return "Moderator"
        case "viewer": return "Viewer"
        default: return role.capitalized
        }
    }
    
    var isAdmin: Bool {
        role == "admin"
    }
    
    var isModerator: Bool {
        role == "moderator"
    }
    
    var isViewer: Bool {
        role == "viewer"
    }
}

// MARK: - Pending Invitation Model
struct PendingInvitation: Identifiable, Equatable {
    let id: String
    let projectId: String
    let projectName: String
    var projectDescription: String?
    let role: String
    let inviterName: String
    var inviterEmail: String?
    var message: String?
    var expiresAt: String?
    var createdAt: String?
    
    // MARK: - Computed Properties
    var roleDisplayName: String {
        switch role {
        case "admin": return "Admin"
        case "moderator": return "Moderator"
        case "viewer": return "Viewer"
        default: return role.capitalized
        }
    }
    
    var isExpired: Bool {
        guard let expiresAt = expiresAt,
              let expiryDate = expiresAt.iso8601Date else {
            return false
        }
        return expiryDate < Date()
    }
    
    var formattedExpiryDate: String {
        guard let expiresAt = expiresAt,
              let date = expiresAt.iso8601Date else {
            return ""
        }
        return date.relativeString
    }
}

// MARK: - Team Chat Message
struct TeamChatMessage: Identifiable, Equatable {
    let id: String
    let content: String
    let userId: String
    var user: UserSummary?
    let createdAt: String
    var updatedAt: String?
    var isEdited: Bool
    
    // MARK: - Computed Properties
    var formattedTimestamp: String {
        guard let date = createdAt.iso8601Date else { return "" }
        return date.chatTimestamp
    }
    
    var senderName: String {
        user?.displayName ?? "Unknown"
    }
    
    var senderInitials: String {
        user?.initials ?? "??"
    }
}

// MARK: - Project Collaboration Role
enum CollaboratorRole: String, CaseIterable {
    case admin
    case moderator
    case viewer
    
    var displayName: String {
        switch self {
        case .admin: return "Admin"
        case .moderator: return "Moderator"
        case .viewer: return "Viewer"
        }
    }
    
    var description: String {
        switch self {
        case .admin:
            return "Can manage project settings, invite members, and manage roles"
        case .moderator:
            return "Can edit project and invite members"
        case .viewer:
            return "Can only view project content"
        }
    }
}
