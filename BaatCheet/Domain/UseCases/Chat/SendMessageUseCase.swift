//
//  SendMessageUseCase.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import Foundation

// MARK: - Send Message Use Case Protocol
protocol SendMessageUseCase {
    func execute(
        message: String,
        conversationId: String?,
        model: String?,
        mode: String?,
        imageIds: [String]?,
        projectId: String?,
        isVoiceChat: Bool
    ) async throws -> ChatMessage
}

// MARK: - Send Message Use Case Implementation
final class SendMessageUseCaseImpl: SendMessageUseCase {
    private let repository: ChatRepository
    
    init(repository: ChatRepository) {
        self.repository = repository
    }
    
    func execute(
        message: String,
        conversationId: String?,
        model: String?,
        mode: String?,
        imageIds: [String]?,
        projectId: String?,
        isVoiceChat: Bool
    ) async throws -> ChatMessage {
        // Validate message
        guard !message.trimmed.isEmpty else {
            throw ChatError.emptyMessage
        }
        
        return try await repository.sendMessage(
            message: message.trimmed,
            conversationId: conversationId,
            model: model,
            mode: mode,
            imageIds: imageIds,
            projectId: projectId,
            isVoiceChat: isVoiceChat
        )
    }
}

// MARK: - Get Conversations Use Case Protocol
protocol GetConversationsUseCase {
    func execute(page: Int, limit: Int) async throws -> [Conversation]
}

// MARK: - Get Conversations Use Case Implementation
final class GetConversationsUseCaseImpl: GetConversationsUseCase {
    private let repository: ChatRepository
    
    init(repository: ChatRepository) {
        self.repository = repository
    }
    
    func execute(page: Int = 1, limit: Int = 50) async throws -> [Conversation] {
        return try await repository.getConversations(page: page, limit: limit)
    }
}

// MARK: - Get Conversation Use Case Protocol
protocol GetConversationUseCase {
    func execute(id: String) async throws -> (conversation: Conversation, messages: [ChatMessage])
}

// MARK: - Get Conversation Use Case Implementation
final class GetConversationUseCaseImpl: GetConversationUseCase {
    private let repository: ChatRepository
    
    init(repository: ChatRepository) {
        self.repository = repository
    }
    
    func execute(id: String) async throws -> (conversation: Conversation, messages: [ChatMessage]) {
        guard !id.isEmpty else {
            throw ChatError.invalidConversationId
        }
        
        return try await repository.getConversation(id)
    }
}

// MARK: - Chat Error
enum ChatError: LocalizedError {
    case emptyMessage
    case invalidConversationId
    case conversationNotFound
    case rateLimited
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .emptyMessage:
            return "Please enter a message"
        case .invalidConversationId:
            return "Invalid conversation"
        case .conversationNotFound:
            return "Conversation not found"
        case .rateLimited:
            return "You've reached your message limit. Please try again later."
        case .serverError(let message):
            return message
        }
    }
}
