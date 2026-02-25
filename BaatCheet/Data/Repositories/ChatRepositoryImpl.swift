//
//  ChatRepositoryImpl.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import Foundation

// MARK: - Chat Repository Implementation
final class ChatRepositoryImpl: ChatRepository {
    // MARK: - Properties
    private let apiClient: APIClient
    
    // MARK: - Init
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    // MARK: - Send Message
    func sendMessage(
        message: String,
        conversationId: String?,
        model: String?,
        mode: String?,
        imageIds: [String]?,
        projectId: String?,
        isVoiceChat: Bool
    ) async throws -> ChatMessage {
        let request = ChatRequestDTO(
            message: message,
            conversationId: conversationId,
            model: model,
            stream: false,
            imageIds: imageIds,
            mode: mode,
            projectId: projectId,
            isVoiceChat: isVoiceChat
        )
        
        let response: ChatResponseDTO = try await apiClient.post(
            endpoint: .chatCompletions,
            body: request
        )
        
        guard response.success, let data = response.data else {
            throw ChatError.serverError(response.error ?? "Failed to send message")
        }
        
        var chatMessage = data.message?.toDomain(conversationId: data.conversationId) ?? ChatMessage(
            content: "",
            role: .assistant,
            conversationId: data.conversationId
        )
        
        // Attach image result if present
        if let imageResult = data.imageResult {
            chatMessage.imageResult = imageResult.toDomain()
        }
        
        return chatMessage
    }
    
    // MARK: - Regenerate Response
    func regenerateResponse(conversationId: String) async throws -> ChatMessage {
        let request = RegenerateRequestDTO(conversationId: conversationId)
        let response: ChatResponseDTO = try await apiClient.post(
            endpoint: .chatRegenerate,
            body: request
        )
        
        guard response.success, let data = response.data else {
            throw ChatError.serverError(response.error ?? "Failed to regenerate response")
        }
        
        return data.message?.toDomain(conversationId: conversationId) ?? ChatMessage(
            content: "",
            role: .assistant,
            conversationId: conversationId
        )
    }
    
    // MARK: - Submit Feedback
    func submitFeedback(messageId: String, conversationId: String, feedback: String, comment: String?) async throws {
        let request = FeedbackRequestDTO(
            messageId: messageId,
            conversationId: conversationId,
            feedback: feedback,
            comment: comment
        )
        let _: SuccessResponse = try await apiClient.post(
            endpoint: .chatFeedback,
            body: request
        )
    }
    
    // MARK: - Get Conversations
    func getConversations(page: Int = 1, limit: Int = 50) async throws -> [Conversation] {
        let queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        
        let response: ConversationsResponseDTO = try await apiClient.get(
            endpoint: .conversations,
            queryItems: queryItems
        )
        
        guard response.success else {
            throw ChatError.serverError(response.error ?? "Failed to load conversations")
        }
        
        return response.data?.allConversations.map { $0.toDomain() } ?? []
    }
    
    // MARK: - Get Conversation
    func getConversation(_ id: String) async throws -> (conversation: Conversation, messages: [ChatMessage]) {
        let response: ConversationResponseDTO = try await apiClient.get(
            endpoint: .conversation(id: id)
        )
        
        guard response.success, let data = response.data else {
            throw ChatError.conversationNotFound
        }
        
        let messages = data.messages?.map { $0.toDomain() } ?? []
        
        return (data.resolvedConversation.toDomain(), messages)
    }
    
    // MARK: - Create Conversation
    func createConversation(title: String?, projectId: String?) async throws -> Conversation {
        let request = CreateConversationRequestDTO(title: title, projectId: projectId)
        let response: ConversationResponseDTO = try await apiClient.post(
            endpoint: .conversations,
            body: request
        )
        
        guard response.success, let data = response.data else {
            throw ChatError.serverError("Failed to create conversation")
        }
        
        return data.resolvedConversation.toDomain()
    }
    
    // MARK: - Update Conversation
    func updateConversation(_ id: String, title: String?, isPinned: Bool?, isArchived: Bool?) async throws -> Conversation {
        let request = UpdateConversationRequestDTO(
            title: title,
            isPinned: isPinned,
            isArchived: isArchived
        )
        let response: ConversationResponseDTO = try await apiClient.put(
            endpoint: .conversation(id: id),
            body: request
        )
        
        guard response.success, let data = response.data else {
            throw ChatError.serverError("Failed to update conversation")
        }
        
        return data.resolvedConversation.toDomain()
    }
    
    // MARK: - Delete Conversation
    func deleteConversation(_ id: String) async throws {
        let _: SuccessResponse = try await apiClient.delete(
            endpoint: .conversation(id: id)
        )
    }
    
    // MARK: - Search Conversations
    func searchConversations(query: String) async throws -> [Conversation] {
        let queryItems = [URLQueryItem(name: "q", value: query)]
        
        let response: SearchConversationsResponseDTO = try await apiClient.get(
            endpoint: .conversationSearch,
            queryItems: queryItems
        )
        
        guard response.success else {
            return []
        }
        
        return response.data?.conversations?.map { $0.toDomain() } ?? []
    }
    
    // MARK: - Share
    func createShareLink(conversationId: String, expiresIn: Int?) async throws -> ShareLink {
        let request = CreateShareRequestDTO(conversationId: conversationId, expiresIn: expiresIn)
        let response: ShareResponseDTO = try await apiClient.post(
            endpoint: .chatShare,
            body: request
        )
        
        guard response.success, let data = response.data else {
            throw ChatError.serverError("Failed to create share link")
        }
        
        return data.toDomain()
    }
    
    func getSharedConversation(shareId: String) async throws -> (conversation: Conversation, messages: [ChatMessage]) {
        let response: SharedConversationResponseDTO = try await apiClient.get(
            endpoint: .sharedChat(shareId: shareId),
            requiresAuth: false
        )
        
        guard response.success, let data = response.data, let conversation = data.conversation else {
            throw ChatError.conversationNotFound
        }
        
        let messages = data.messages?.map { $0.toDomain() } ?? []
        
        return (conversation.toDomain(), messages)
    }
    
    func revokeShareLink(shareId: String) async throws {
        let _: SuccessResponse = try await apiClient.delete(
            endpoint: .revokeShare(shareId: shareId)
        )
    }
    
    // MARK: - AI Modes
    func getAIModes() async throws -> [AIMode] {
        let response: ModesResponseDTO = try await apiClient.get(
            endpoint: .chatModes,
            requiresAuth: false
        )
        
        guard response.success else {
            return AIMode.defaultModes
        }
        
        return response.data?.modes.map { $0.toDomain() } ?? AIMode.defaultModes
    }
    
    // MARK: - Usage
    func getUsage() async throws -> UsageInfo {
        let response: UsageResponseDTO = try await apiClient.get(
            endpoint: .chatUsage
        )
        
        guard response.success, let data = response.data else {
            return UsageInfo.default
        }
        
        return data.toDomain()
    }
    
    // MARK: - Suggestions
    func getSuggestions(conversationId: String?, lastResponse: String?) async throws -> [String] {
        let request = SuggestRequestDTO(
            conversationId: conversationId,
            lastResponse: lastResponse
        )
        let response: SuggestionsResponseDTO = try await apiClient.post(
            endpoint: .chatSuggest,
            body: request
        )
        
        return response.data?.suggestions ?? defaultSuggestions
    }
    
    private var defaultSuggestions: [String] {
        [
            "Tell me more about this",
            "Can you explain in simpler terms?",
            "What are some examples?",
            "What are the alternatives?"
        ]
    }
    
    // MARK: - Analyze Prompt
    func analyzePrompt(_ prompt: String, conversationId: String?) async throws -> PromptAnalysisResult {
        let request = AnalyzeRequestDTO(prompt: prompt, conversationId: conversationId)
        let response: AnalyzeResponseDTO = try await apiClient.post(
            endpoint: .chatAnalyze,
            body: request
        )
        
        guard response.success, let data = response.data else {
            throw ChatError.serverError("Failed to analyze prompt")
        }
        
        return data.toDomain()
    }
    
    // MARK: - Models
    func getModels() async throws -> [String] {
        // Return default models for now
        return ["gpt-4", "gpt-3.5-turbo", "claude-3"]
    }
    
    func getProvidersHealth() async throws -> [String: Bool] {
        // Return default health status
        return ["openai": true, "anthropic": true]
    }
}
