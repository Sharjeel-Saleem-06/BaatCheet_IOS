//
//  ProjectDTOs.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import Foundation

// MARK: - Projects List Response (API returns data as array directly)
struct ProjectsResponseDTO: Decodable {
    let success: Bool
    let data: [ProjectDTO]?
    let error: String?
}

// MARK: - Single Project Response
struct ProjectResponseDTO: Decodable {
    let success: Bool
    let data: ProjectDTO?
    let error: String?
}

// MARK: - Project DTO
struct ProjectDTO: Decodable {
    let id: String
    let name: String
    let description: String?
    let color: String?
    let icon: String?
    let emoji: String?
    let conversationCount: Int?
    let instructions: String?
    let customInstructions: String?
    
    // Collaboration fields
    let myRole: String?
    let isOwner: Bool?
    let canEdit: Bool?
    let canDelete: Bool?
    let canInvite: Bool?
    let canManageRoles: Bool?
    let collaboratorCount: Int?
    let owner: UserSummaryDTO?
    let collaborators: [CollaboratorDTO]?
    
    // AI Context
    let context: String?
    let keyTopics: [String]?
    let techStack: [String]?
    let goals: [String]?
    let lastContextUpdate: String?
    
    let createdAt: String?
    let updatedAt: String?
    
    func toDomain() -> Project {
        Project(
            id: id,
            name: name,
            description: description,
            color: color,
            icon: icon,
            emoji: emoji,
            conversationCount: conversationCount ?? 0,
            instructions: instructions,
            customInstructions: customInstructions,
            myRole: myRole,
            isOwner: isOwner ?? true,
            canEdit: canEdit ?? true,
            canDelete: canDelete ?? true,
            canInvite: canInvite ?? false,
            canManageRoles: canManageRoles ?? false,
            collaboratorCount: collaboratorCount ?? 0,
            owner: owner?.toDomain(),
            collaborators: collaborators?.map { $0.toDomain() } ?? [],
            context: context,
            keyTopics: keyTopics ?? [],
            techStack: techStack ?? [],
            goals: goals ?? [],
            lastContextUpdate: lastContextUpdate
        )
    }
}

// MARK: - User Summary DTO
struct UserSummaryDTO: Decodable {
    let id: String
    let username: String?
    let firstName: String?
    let lastName: String?
    let email: String?
    let avatar: String?
    
    func toDomain() -> UserSummary {
        UserSummary(
            id: id,
            username: username,
            firstName: firstName,
            lastName: lastName,
            email: email,
            avatar: avatar
        )
    }
}

// MARK: - Collaborator DTO
struct CollaboratorDTO: Decodable {
    let id: String
    let userId: String
    let role: String
    let user: UserSummaryDTO?
    let addedAt: String?
    let lastAccessedAt: String?
    let accessCount: Int?
    let canEdit: Bool?
    let canDelete: Bool?
    let canInvite: Bool?
    let canManageRoles: Bool?
    
    func toDomain() -> Collaborator {
        Collaborator(
            id: id,
            userId: userId,
            role: role,
            user: user?.toDomain() ?? UserSummary(id: userId, username: nil, firstName: nil, lastName: nil, email: nil, avatar: nil),
            addedAt: addedAt,
            lastAccessedAt: lastAccessedAt,
            accessCount: accessCount ?? 0,
            canEdit: canEdit ?? false,
            canDelete: canDelete ?? false,
            canInvite: canInvite ?? false,
            canManageRoles: canManageRoles ?? false
        )
    }
}

// MARK: - Request DTOs

struct CreateProjectRequestDTO: Encodable {
    let name: String
    let description: String?
    let color: String?
    let emoji: String?
    let instructions: String?
}

struct UpdateProjectRequestDTO: Encodable {
    let name: String?
    let description: String?
    let color: String?
    let emoji: String?
    let instructions: String?
    let customInstructions: String?
}

// MARK: - Invitation DTOs
struct InviteCollaboratorRequestDTO: Encodable {
    let email: String
    let role: String
    let message: String?
}

struct InvitationResponseRequestDTO: Encodable {
    let accept: Bool
}

struct ChangeRoleRequestDTO: Encodable {
    let role: String
}

// MARK: - Pending Invitations Response (API returns data as array directly)
struct PendingInvitationsResponseDTO: Decodable {
    let success: Bool
    let data: [PendingInvitationDTO]?
}

struct PendingInvitationDTO: Decodable {
    let id: String
    let projectId: String
    let projectName: String?
    let projectDescription: String?
    let role: String
    let inviterName: String?
    let inviterEmail: String?
    let message: String?
    let expiresAt: String?
    let createdAt: String?
    
    func toDomain() -> PendingInvitation {
        PendingInvitation(
            id: id,
            projectId: projectId,
            projectName: projectName ?? "Unknown Project",
            projectDescription: projectDescription,
            role: role,
            inviterName: inviterName ?? "Someone",
            inviterEmail: inviterEmail,
            message: message,
            expiresAt: expiresAt,
            createdAt: createdAt
        )
    }
}

// MARK: - Collaborations Response
struct CollaborationsResponseDTO: Decodable {
    let success: Bool
    let data: CollaborationsDataDTO?
}

struct CollaborationsDataDTO: Decodable {
    let projects: [ProjectDTO]?
}

// MARK: - Check Email Response
struct CheckEmailResponseDTO: Decodable {
    let success: Bool
    let data: CheckEmailDataDTO?
}

struct CheckEmailDataDTO: Decodable {
    let exists: Bool?
    let user: UserSummaryDTO?
}

// MARK: - Project Chat DTOs
struct ProjectChatMessagesResponseDTO: Decodable {
    let success: Bool
    let data: ProjectChatMessagesDataDTO?
}

struct ProjectChatMessagesDataDTO: Decodable {
    let messages: [TeamChatMessageDTO]?
    let total: Int?
}

struct TeamChatMessageDTO: Decodable {
    let id: String
    let content: String
    let userId: String
    let user: UserSummaryDTO?
    let createdAt: String?
    let updatedAt: String?
    let isEdited: Bool?
    
    func toDomain() -> TeamChatMessage {
        TeamChatMessage(
            id: id,
            content: content,
            userId: userId,
            user: user?.toDomain(),
            createdAt: createdAt ?? "",
            updatedAt: updatedAt,
            isEdited: isEdited ?? false
        )
    }
}

struct SendTeamMessageRequestDTO: Encodable {
    let content: String
}

struct EditTeamMessageRequestDTO: Encodable {
    let content: String
}

// MARK: - Project Conversations Response (API returns data as array directly)
struct ProjectConversationsResponseDTO: Decodable {
    let success: Bool
    let data: [ConversationDTO]?
}
