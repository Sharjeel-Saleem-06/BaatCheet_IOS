//
//  ProjectRepository.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import Foundation

// MARK: - Project Repository Protocol
protocol ProjectRepository {
    // MARK: - Projects
    func getProjects() async throws -> [Project]
    func getProject(_ id: String) async throws -> Project
    func createProject(name: String, description: String?, color: String?, emoji: String?, instructions: String?) async throws -> Project
    func updateProject(_ id: String, name: String?, description: String?, color: String?, emoji: String?, instructions: String?, customInstructions: String?) async throws -> Project
    func deleteProject(_ id: String) async throws
    
    // MARK: - Project Conversations
    func getProjectConversations(_ projectId: String) async throws -> [Conversation]
    func refreshProjectContext(_ projectId: String) async throws
    
    // MARK: - Collaboration
    func checkEmail(_ email: String) async throws -> (exists: Bool, user: UserSummary?)
    func inviteCollaborator(projectId: String, email: String, role: String, message: String?) async throws
    func getPendingInvitations() async throws -> [PendingInvitation]
    func respondToInvitation(_ invitationId: String, accept: Bool) async throws
    func getCollaborations() async throws -> [Project]
    func getCollaborators(_ projectId: String) async throws -> [Collaborator]
    func removeCollaborator(projectId: String, collaboratorId: String) async throws
    func changeCollaboratorRole(projectId: String, collaboratorId: String, role: String) async throws
    
    // MARK: - Team Chat
    func getTeamChatMessages(_ projectId: String, page: Int, limit: Int) async throws -> [TeamChatMessage]
    func sendTeamMessage(_ projectId: String, content: String) async throws -> TeamChatMessage
    func editTeamMessage(projectId: String, messageId: String, content: String) async throws -> TeamChatMessage
    func deleteTeamMessage(projectId: String, messageId: String) async throws
    func getUnreadCount(_ projectId: String) async throws -> Int
    func markAllAsRead(_ projectId: String) async throws
}
