//
//  ChatRepository.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import Foundation

// MARK: - Chat Repository Protocol
protocol ChatRepository {
    // MARK: - Messages
    func sendMessage(
        message: String,
        conversationId: String?,
        model: String?,
        mode: String?,
        imageIds: [String]?,
        projectId: String?,
        isVoiceChat: Bool
    ) async throws -> ChatMessage
    
    func regenerateResponse(conversationId: String) async throws -> ChatMessage
    
    func submitFeedback(
        messageId: String,
        conversationId: String,
        feedback: String,
        comment: String?
    ) async throws
    
    // MARK: - Conversations
    func getConversations(page: Int, limit: Int) async throws -> [Conversation]
    func getConversation(_ id: String) async throws -> (conversation: Conversation, messages: [ChatMessage])
    func createConversation(title: String?, projectId: String?) async throws -> Conversation
    func updateConversation(_ id: String, title: String?, isPinned: Bool?, isArchived: Bool?) async throws -> Conversation
    func deleteConversation(_ id: String) async throws
    func searchConversations(query: String) async throws -> [Conversation]
    
    // MARK: - Sharing
    func createShareLink(conversationId: String, expiresIn: Int?) async throws -> ShareLink
    func getSharedConversation(shareId: String) async throws -> (conversation: Conversation, messages: [ChatMessage])
    func revokeShareLink(shareId: String) async throws
    
    // MARK: - AI Features
    func getAIModes() async throws -> [AIMode]
    func getUsage() async throws -> UsageInfo
    func getSuggestions(conversationId: String?, lastResponse: String?) async throws -> [String]
    func analyzePrompt(_ prompt: String, conversationId: String?) async throws -> PromptAnalysisResult
    
    // MARK: - Models
    func getModels() async throws -> [String]
    func getProvidersHealth() async throws -> [String: Bool]
}
