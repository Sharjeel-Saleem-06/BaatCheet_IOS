//
//  GetProjectsUseCase.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import Foundation

// MARK: - Get Projects Use Case Protocol
protocol GetProjectsUseCase {
    func execute() async throws -> [Project]
}

// MARK: - Get Projects Use Case Implementation
final class GetProjectsUseCaseImpl: GetProjectsUseCase {
    private let repository: ProjectRepository
    
    init(repository: ProjectRepository) {
        self.repository = repository
    }
    
    func execute() async throws -> [Project] {
        return try await repository.getProjects()
    }
}

// MARK: - Create Project Use Case Protocol
protocol CreateProjectUseCase {
    func execute(name: String, description: String?, color: String?, emoji: String?, instructions: String?) async throws -> Project
}

// MARK: - Create Project Use Case Implementation
final class CreateProjectUseCaseImpl: CreateProjectUseCase {
    private let repository: ProjectRepository
    
    init(repository: ProjectRepository) {
        self.repository = repository
    }
    
    func execute(name: String, description: String?, color: String?, emoji: String?, instructions: String?) async throws -> Project {
        // Validate name
        guard !name.trimmed.isEmpty else {
            throw ProjectError.invalidName
        }
        
        return try await repository.createProject(
            name: name.trimmed,
            description: description?.trimmed,
            color: color,
            emoji: emoji,
            instructions: instructions?.trimmed
        )
    }
}

// MARK: - Get Project Use Case Protocol
protocol GetProjectUseCase {
    func execute(id: String) async throws -> Project
}

// MARK: - Get Project Use Case Implementation
final class GetProjectUseCaseImpl: GetProjectUseCase {
    private let repository: ProjectRepository
    
    init(repository: ProjectRepository) {
        self.repository = repository
    }
    
    func execute(id: String) async throws -> Project {
        guard !id.isEmpty else {
            throw ProjectError.invalidId
        }
        
        return try await repository.getProject(id)
    }
}

// MARK: - Delete Project Use Case Protocol
protocol DeleteProjectUseCase {
    func execute(id: String) async throws
}

// MARK: - Delete Project Use Case Implementation
final class DeleteProjectUseCaseImpl: DeleteProjectUseCase {
    private let repository: ProjectRepository
    
    init(repository: ProjectRepository) {
        self.repository = repository
    }
    
    func execute(id: String) async throws {
        guard !id.isEmpty else {
            throw ProjectError.invalidId
        }
        
        try await repository.deleteProject(id)
    }
}

// MARK: - Project Error
enum ProjectError: LocalizedError {
    case invalidName
    case invalidId
    case notFound
    case permissionDenied
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidName:
            return "Please enter a project name"
        case .invalidId:
            return "Invalid project"
        case .notFound:
            return "Project not found"
        case .permissionDenied:
            return "You don't have permission to perform this action"
        case .serverError(let message):
            return message
        }
    }
}
