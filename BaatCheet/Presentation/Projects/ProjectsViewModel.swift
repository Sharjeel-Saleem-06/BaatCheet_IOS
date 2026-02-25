//
//  ProjectsViewModel.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import Foundation
import SwiftUI

// MARK: - Projects ViewModel
@MainActor
final class ProjectsViewModel: ObservableObject {
    // MARK: - Published State
    @Published var projects: [Project] = []
    @Published var isLoading = false
    @Published var error: String?
    
    // Selected Project
    @Published var selectedProject: Project?
    @Published var projectConversations: [Conversation] = []
    @Published var isLoadingProject = false
    
    // Team Chat
    @Published var teamMessages: [TeamChatMessage] = []
    @Published var isLoadingTeamChat = false
    @Published var teamChatInput = ""
    @Published var isSendingTeamMessage = false
    
    // Collaboration
    @Published var collaborators: [Collaborator] = []
    @Published var pendingInvitations: [PendingInvitation] = []
    @Published var sharedProjects: [Project] = []
    
    // Create Project
    @Published var showCreateSheet = false
    @Published var newProjectName = ""
    @Published var newProjectDescription = ""
    @Published var newProjectEmoji = "📁"
    @Published var isCreating = false
    
    // Invite
    @Published var showInviteSheet = false
    @Published var inviteEmail = ""
    @Published var inviteRole = "viewer"
    @Published var inviteMessage = ""
    @Published var isInviting = false
    
    // MARK: - Dependencies
    private let getProjectsUseCase: GetProjectsUseCase
    private let createProjectUseCase: CreateProjectUseCase
    private let projectRepository: ProjectRepository
    
    // MARK: - Init
    init(
        getProjectsUseCase: GetProjectsUseCase,
        createProjectUseCase: CreateProjectUseCase,
        projectRepository: ProjectRepository
    ) {
        self.getProjectsUseCase = getProjectsUseCase
        self.createProjectUseCase = createProjectUseCase
        self.projectRepository = projectRepository
        
        loadProjects()
    }
    
    // MARK: - Load Projects
    func loadProjects() {
        Task {
            isLoading = true
            do {
                projects = try await getProjectsUseCase.execute()
            } catch {
                self.error = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    // MARK: - Load Project Details
    func loadProject(_ projectId: String) {
        selectedProject = nil
        projectConversations = []
        collaborators = []
        teamMessages = []
        
        Task {
            isLoadingProject = true
            do {
                selectedProject = try await projectRepository.getProject(projectId)
                projectConversations = try await projectRepository.getProjectConversations(projectId)
                collaborators = try await projectRepository.getCollaborators(projectId)
            } catch {
                self.error = error.localizedDescription
            }
            isLoadingProject = false
        }
    }
    
    // MARK: - Create Project
    func createProject() {
        guard !newProjectName.trimmed.isEmpty else {
            error = "Please enter a project name"
            return
        }
        
        isCreating = true
        Task {
            do {
                let project = try await createProjectUseCase.execute(
                    name: newProjectName.trimmed,
                    description: newProjectDescription.isEmpty ? nil : newProjectDescription.trimmed,
                    color: nil,
                    emoji: newProjectEmoji,
                    instructions: nil
                )
                
                projects.insert(project, at: 0)
                clearCreateForm()
                showCreateSheet = false
            } catch {
                self.error = error.localizedDescription
            }
            isCreating = false
        }
    }
    
    // MARK: - Delete Project
    func deleteProject(_ projectId: String) {
        Task {
            do {
                try await projectRepository.deleteProject(projectId)
                projects.removeAll { $0.id == projectId }
                
                if selectedProject?.id == projectId {
                    selectedProject = nil
                    projectConversations = []
                }
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
    
    // MARK: - Collaboration
    func loadPendingInvitations() {
        Task {
            do {
                pendingInvitations = try await projectRepository.getPendingInvitations()
            } catch {
                print("Failed to load invitations: \(error)")
            }
        }
    }
    
    func loadSharedProjects() {
        Task {
            do {
                sharedProjects = try await projectRepository.getCollaborations()
            } catch {
                print("Failed to load shared projects: \(error)")
            }
        }
    }
    
    func inviteCollaborator() {
        guard let projectId = selectedProject?.id else { return }
        guard inviteEmail.isValidEmail else {
            error = "Please enter a valid email address"
            return
        }
        
        isInviting = true
        Task {
            do {
                try await projectRepository.inviteCollaborator(
                    projectId: projectId,
                    email: inviteEmail,
                    role: inviteRole,
                    message: inviteMessage.isEmpty ? nil : inviteMessage
                )
                
                clearInviteForm()
                showInviteSheet = false
                
                // Reload collaborators
                collaborators = try await projectRepository.getCollaborators(projectId)
            } catch {
                self.error = error.localizedDescription
            }
            isInviting = false
        }
    }
    
    func respondToInvitation(_ invitationId: String, accept: Bool) {
        Task {
            do {
                try await projectRepository.respondToInvitation(invitationId, accept: accept)
                pendingInvitations.removeAll { $0.id == invitationId }
                
                if accept {
                    loadProjects()
                }
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
    
    func removeCollaborator(_ collaboratorId: String) {
        guard let projectId = selectedProject?.id else { return }
        
        Task {
            do {
                try await projectRepository.removeCollaborator(
                    projectId: projectId,
                    collaboratorId: collaboratorId
                )
                collaborators.removeAll { $0.id == collaboratorId }
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
    
    func changeCollaboratorRole(_ collaboratorId: String, newRole: String) {
        guard let projectId = selectedProject?.id else { return }
        
        Task {
            do {
                try await projectRepository.changeCollaboratorRole(
                    projectId: projectId,
                    collaboratorId: collaboratorId,
                    role: newRole
                )
                
                // Update local state
                if let index = collaborators.firstIndex(where: { $0.id == collaboratorId }) {
                    collaborators[index].role = newRole
                }
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
    
    // MARK: - Team Chat
    func loadTeamChat() {
        guard let projectId = selectedProject?.id else { return }
        
        isLoadingTeamChat = true
        Task {
            do {
                teamMessages = try await projectRepository.getTeamChatMessages(projectId, page: 1, limit: 50)
            } catch {
                print("Failed to load team chat: \(error)")
            }
            isLoadingTeamChat = false
        }
    }
    
    func sendTeamMessage() {
        guard let projectId = selectedProject?.id else { return }
        guard !teamChatInput.trimmed.isEmpty else { return }
        
        let content = teamChatInput.trimmed
        teamChatInput = ""
        
        isSendingTeamMessage = true
        Task {
            do {
                let message = try await projectRepository.sendTeamMessage(projectId, content: content)
                teamMessages.append(message)
            } catch {
                self.error = error.localizedDescription
                teamChatInput = content // Restore input on error
            }
            isSendingTeamMessage = false
        }
    }
    
    func deleteTeamMessage(_ messageId: String) {
        guard let projectId = selectedProject?.id else { return }
        
        Task {
            do {
                try await projectRepository.deleteTeamMessage(projectId: projectId, messageId: messageId)
                teamMessages.removeAll { $0.id == messageId }
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
    
    // MARK: - Clear Forms
    func clearCreateForm() {
        newProjectName = ""
        newProjectDescription = ""
        newProjectEmoji = "📁"
    }
    
    func clearInviteForm() {
        inviteEmail = ""
        inviteRole = "viewer"
        inviteMessage = ""
    }
    
    func clearError() {
        error = nil
    }
}
