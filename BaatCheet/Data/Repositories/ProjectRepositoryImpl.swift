//
//  ProjectRepositoryImpl.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import Foundation

// MARK: - Project Repository Implementation
final class ProjectRepositoryImpl: ProjectRepository {
    // MARK: - Properties
    private let apiClient: APIClient
    
    // MARK: - Init
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    // MARK: - Get Projects
    func getProjects() async throws -> [Project] {
        let response: ProjectsResponseDTO = try await apiClient.get(endpoint: .projects)
        
        guard response.success else {
            throw ProjectError.serverError(response.error ?? "Failed to load projects")
        }
        
        return response.data?.projects?.map { $0.toDomain() } ?? []
    }
    
    // MARK: - Get Project
    func getProject(_ id: String) async throws -> Project {
        let response: ProjectResponseDTO = try await apiClient.get(endpoint: .project(id: id))
        
        guard response.success, let project = response.data else {
            throw ProjectError.notFound
        }
        
        return project.toDomain()
    }
    
    // MARK: - Create Project
    func createProject(name: String, description: String?, color: String?, emoji: String?, instructions: String?) async throws -> Project {
        let request = CreateProjectRequestDTO(
            name: name,
            description: description,
            color: color,
            emoji: emoji,
            instructions: instructions
        )
        let response: ProjectResponseDTO = try await apiClient.post(
            endpoint: .projects,
            body: request
        )
        
        guard response.success, let project = response.data else {
            throw ProjectError.serverError("Failed to create project")
        }
        
        return project.toDomain()
    }
    
    // MARK: - Update Project
    func updateProject(_ id: String, name: String?, description: String?, color: String?, emoji: String?, instructions: String?, customInstructions: String?) async throws -> Project {
        let request = UpdateProjectRequestDTO(
            name: name,
            description: description,
            color: color,
            emoji: emoji,
            instructions: instructions,
            customInstructions: customInstructions
        )
        let response: ProjectResponseDTO = try await apiClient.put(
            endpoint: .project(id: id),
            body: request
        )
        
        guard response.success, let project = response.data else {
            throw ProjectError.serverError("Failed to update project")
        }
        
        return project.toDomain()
    }
    
    // MARK: - Delete Project
    func deleteProject(_ id: String) async throws {
        let _: SuccessResponse = try await apiClient.delete(endpoint: .project(id: id))
    }
    
    // MARK: - Get Project Conversations
    func getProjectConversations(_ projectId: String) async throws -> [Conversation] {
        let response: ProjectConversationsResponseDTO = try await apiClient.get(
            endpoint: .projectConversations(id: projectId)
        )
        
        guard response.success else {
            return []
        }
        
        return response.data?.conversations?.map { $0.toDomain() } ?? []
    }
    
    // MARK: - Refresh Project Context
    func refreshProjectContext(_ projectId: String) async throws {
        let _: SuccessResponse = try await apiClient.post(
            endpoint: .projectContextRefresh(id: projectId)
        )
    }
    
    // MARK: - Check Email
    func checkEmail(_ email: String) async throws -> (exists: Bool, user: UserSummary?) {
        let response: CheckEmailResponseDTO = try await apiClient.get(
            endpoint: .projectCheckEmail(email: email)
        )
        
        let exists = response.data?.exists ?? false
        let user = response.data?.user?.toDomain()
        
        return (exists, user)
    }
    
    // MARK: - Invite Collaborator
    func inviteCollaborator(projectId: String, email: String, role: String, message: String?) async throws {
        let request = InviteCollaboratorRequestDTO(
            email: email,
            role: role,
            message: message
        )
        let _: SuccessResponse = try await apiClient.post(
            endpoint: .projectInvite(id: projectId),
            body: request
        )
    }
    
    // MARK: - Get Pending Invitations
    func getPendingInvitations() async throws -> [PendingInvitation] {
        let response: PendingInvitationsResponseDTO = try await apiClient.get(
            endpoint: .projectInvitationsPending
        )
        
        guard response.success else {
            return []
        }
        
        return response.data?.invitations?.map { $0.toDomain() } ?? []
    }
    
    // MARK: - Respond to Invitation
    func respondToInvitation(_ invitationId: String, accept: Bool) async throws {
        let request = InvitationResponseRequestDTO(accept: accept)
        let _: SuccessResponse = try await apiClient.post(
            endpoint: .projectInvitationRespond(id: invitationId),
            body: request
        )
    }
    
    // MARK: - Get Collaborations
    func getCollaborations() async throws -> [Project] {
        let response: CollaborationsResponseDTO = try await apiClient.get(
            endpoint: .projectCollaborations
        )
        
        guard response.success else {
            return []
        }
        
        return response.data?.projects?.map { $0.toDomain() } ?? []
    }
    
    // MARK: - Get Collaborators
    func getCollaborators(_ projectId: String) async throws -> [Collaborator] {
        struct CollaboratorsResponseDTO: Decodable {
            let success: Bool
            let data: CollaboratorsDataDTO?
        }
        
        struct CollaboratorsDataDTO: Decodable {
            let collaborators: [CollaboratorDTO]?
        }
        
        let response: CollaboratorsResponseDTO = try await apiClient.get(
            endpoint: .projectCollaborators(id: projectId)
        )
        
        guard response.success else {
            return []
        }
        
        return response.data?.collaborators?.map { $0.toDomain() } ?? []
    }
    
    // MARK: - Remove Collaborator
    func removeCollaborator(projectId: String, collaboratorId: String) async throws {
        let _: SuccessResponse = try await apiClient.delete(
            endpoint: .projectRemoveCollaborator(projectId: projectId, collaboratorId: collaboratorId)
        )
    }
    
    // MARK: - Change Collaborator Role
    func changeCollaboratorRole(projectId: String, collaboratorId: String, role: String) async throws {
        let request = ChangeRoleRequestDTO(role: role)
        let _: SuccessResponse = try await apiClient.put(
            endpoint: .projectChangeRole(projectId: projectId, collaboratorId: collaboratorId),
            body: request
        )
    }
    
    // MARK: - Team Chat Messages
    func getTeamChatMessages(_ projectId: String, page: Int = 1, limit: Int = 50) async throws -> [TeamChatMessage] {
        let queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        
        let response: ProjectChatMessagesResponseDTO = try await apiClient.get(
            endpoint: .projectChatMessages(id: projectId),
            queryItems: queryItems
        )
        
        guard response.success else {
            return []
        }
        
        return response.data?.messages?.map { $0.toDomain() } ?? []
    }
    
    // MARK: - Send Team Message
    func sendTeamMessage(_ projectId: String, content: String) async throws -> TeamChatMessage {
        struct TeamMessageResponseDTO: Decodable {
            let success: Bool
            let data: TeamChatMessageDTO?
        }
        
        let request = SendTeamMessageRequestDTO(content: content)
        let response: TeamMessageResponseDTO = try await apiClient.post(
            endpoint: .projectChatMessages(id: projectId),
            body: request
        )
        
        guard response.success, let message = response.data else {
            throw ProjectError.serverError("Failed to send message")
        }
        
        return message.toDomain()
    }
    
    // MARK: - Edit Team Message
    func editTeamMessage(projectId: String, messageId: String, content: String) async throws -> TeamChatMessage {
        struct TeamMessageResponseDTO: Decodable {
            let success: Bool
            let data: TeamChatMessageDTO?
        }
        
        let request = EditTeamMessageRequestDTO(content: content)
        let response: TeamMessageResponseDTO = try await apiClient.put(
            endpoint: .projectChatMessage(projectId: projectId, messageId: messageId),
            body: request
        )
        
        guard response.success, let message = response.data else {
            throw ProjectError.serverError("Failed to edit message")
        }
        
        return message.toDomain()
    }
    
    // MARK: - Delete Team Message
    func deleteTeamMessage(projectId: String, messageId: String) async throws {
        let _: SuccessResponse = try await apiClient.delete(
            endpoint: .projectChatMessage(projectId: projectId, messageId: messageId)
        )
    }
    
    // MARK: - Get Unread Count
    func getUnreadCount(_ projectId: String) async throws -> Int {
        struct UnreadResponseDTO: Decodable {
            let success: Bool
            let data: UnreadDataDTO?
        }
        
        struct UnreadDataDTO: Decodable {
            let count: Int?
        }
        
        let response: UnreadResponseDTO = try await apiClient.get(
            endpoint: .projectChatUnreadCount(id: projectId)
        )
        
        return response.data?.count ?? 0
    }
    
    // MARK: - Mark All As Read
    func markAllAsRead(_ projectId: String) async throws {
        let _: SuccessResponse = try await apiClient.post(
            endpoint: .projectChatReadAll(id: projectId)
        )
    }
}
