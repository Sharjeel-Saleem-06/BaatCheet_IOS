//
//  ChatViewModel.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import Foundation
import SwiftUI

// MARK: - Chat ViewModel
@MainActor
final class ChatViewModel: ObservableObject {
    // MARK: - Published State
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var isSending = false
    @Published var error: String?
    @Published var currentConversationId: String?
    @Published var currentLoadingMode: String?
    
    // Conversations
    @Published var conversations: [Conversation] = []
    @Published var isLoadingConversations = false
    @Published var searchQuery = ""
    
    // User Profile
    @Published var userProfile: UserProfile?
    
    // AI Modes
    @Published var aiModes: [AIMode] = AIMode.defaultModes
    @Published var currentAIMode: AIMode?
    @Published var usageInfo = UsageInfo.default
    
    // Suggestions
    @Published var suggestions: [String] = []
    
    // Input
    @Published var inputText = ""
    @Published var selectedMode: String?
    
    // Upload
    @Published var uploadedFiles: [UploadedFileState] = []
    @Published var isUploading = false
    
    // Share
    @Published var shareUrl: String?
    @Published var isSharing = false
    
    // Image Generation
    @Published var isGeneratingImage = false
    
    // Speaking
    @Published var speakingMessageId: String?
    
    // Project Context
    @Published var currentProjectId: String?
    
    // MARK: - Dependencies
    private let sendMessageUseCase: SendMessageUseCase
    private let getConversationsUseCase: GetConversationsUseCase
    private let getConversationUseCase: GetConversationUseCase
    private let chatRepository: ChatRepository
    private let profileRepository: ProfileRepository
    
    // MARK: - Init
    init(
        sendMessageUseCase: SendMessageUseCase,
        getConversationsUseCase: GetConversationsUseCase,
        getConversationUseCase: GetConversationUseCase,
        chatRepository: ChatRepository,
        profileRepository: ProfileRepository
    ) {
        self.sendMessageUseCase = sendMessageUseCase
        self.getConversationsUseCase = getConversationsUseCase
        self.getConversationUseCase = getConversationUseCase
        self.chatRepository = chatRepository
        self.profileRepository = profileRepository
        
        loadInitialData()
    }
    
    // MARK: - Initial Data Load
    private func loadInitialData() {
        Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.loadUserProfile() }
                group.addTask { await self.loadConversations() }
                group.addTask { await self.loadAIModes() }
                group.addTask { await self.loadUsage() }
            }
        }
    }
    
    // MARK: - Send Message
    func sendMessage() async {
        let content = inputText.trimmed
        guard !content.isEmpty else { return }
        
        let isImageRequest = selectedMode == "image-generation" ||
            content.lowercased().contains("create image") ||
            content.lowercased().contains("generate image") ||
            content.lowercased().contains("draw")
        
        if isImageRequest {
            isGeneratingImage = true
            currentLoadingMode = "image-generation"
        }
        
        // Get uploaded file IDs
        let uploadedFileIds = uploadedFiles
            .filter { $0.status == .ready }
            .compactMap { $0.remoteId }
        
        // Create user message
        let userMessage = ChatMessage(
            content: content,
            role: .user,
            conversationId: currentConversationId,
            attachments: uploadedFiles.filter { $0.status == .ready }.map { file in
                MessageAttachment(
                    id: file.remoteId ?? file.id,
                    filename: file.filename,
                    mimeType: file.mimeType,
                    thumbnailUrl: file.previewUrl,
                    status: "ready"
                )
            }
        )
        
        messages.append(userMessage)
        
        // Clear input
        inputText = ""
        let savedUploadedFiles = uploadedFiles
        uploadedFiles.removeAll()
        
        // Add streaming placeholder
        let streamingMessage = ChatMessage(
            content: "",
            role: .assistant,
            isStreaming: true
        )
        messages.append(streamingMessage)
        
        isSending = true
        error = nil
        
        do {
            let result = try await sendMessageUseCase.execute(
                message: content,
                conversationId: currentConversationId,
                model: nil,
                mode: selectedMode,
                imageIds: uploadedFileIds.isEmpty ? nil : uploadedFileIds,
                projectId: currentProjectId,
                isVoiceChat: false
            )
            
            // Update streaming message with response
            if let lastIndex = messages.indices.last,
               messages[lastIndex].isStreaming {
                messages[lastIndex] = result
                messages[lastIndex].isStreaming = false
            }
            
            currentConversationId = result.conversationId ?? currentConversationId
            
            // Load follow-up data
            loadConversations()
            loadSuggestions(lastResponse: result.content)
            loadUsage()
            
        } catch {
            // Handle error
            if let lastIndex = messages.indices.last,
               messages[lastIndex].isStreaming {
                messages[lastIndex] = ChatMessage(
                    content: "Sorry, I couldn't process your request. Please try again.",
                    role: .assistant,
                    isStreaming: false
                )
            }
            self.error = error.localizedDescription
        }
        
        isSending = false
        isGeneratingImage = false
        currentLoadingMode = nil
    }
    
    // MARK: - Conversations
    func loadConversations() {
        Task {
            isLoadingConversations = true
            do {
                conversations = try await getConversationsUseCase.execute(page: 1, limit: 50)
            } catch {
                print("Failed to load conversations: \(error)")
            }
            isLoadingConversations = false
        }
    }
    
    func loadConversation(_ conversationId: String) {
        Task {
            isLoading = true
            do {
                let result = try await getConversationUseCase.execute(id: conversationId)
                messages = result.messages
                currentConversationId = conversationId
            } catch {
                self.error = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    func loadSharedConversation(shareId: String) {
        Task {
            isLoading = true
            do {
                let result = try await chatRepository.getSharedConversation(shareId: shareId)
                messages = result.messages
                // Don't set currentConversationId for shared conversations
            } catch {
                self.error = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    func startNewChat() {
        messages.removeAll()
        currentConversationId = nil
        currentProjectId = nil
        error = nil
        suggestions = []
        inputText = ""
        uploadedFiles.removeAll()
    }
    
    func deleteConversation(_ conversationId: String) {
        Task {
            do {
                try await chatRepository.deleteConversation(conversationId)
                if currentConversationId == conversationId {
                    startNewChat()
                }
                loadConversations()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
    
    func togglePinConversation(_ conversationId: String) {
        Task {
            guard let conversation = conversations.first(where: { $0.id == conversationId }) else { return }
            
            do {
                _ = try await chatRepository.updateConversation(
                    conversationId,
                    title: nil,
                    isPinned: !conversation.isPinned,
                    isArchived: nil
                )
                loadConversations()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
    
    func renameConversation(_ conversationId: String, title: String) {
        Task {
            do {
                _ = try await chatRepository.updateConversation(
                    conversationId,
                    title: title,
                    isPinned: nil,
                    isArchived: nil
                )
                loadConversations()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
    
    func searchConversations(_ query: String) {
        Task {
            guard !query.isEmpty else {
                loadConversations()
                return
            }
            
            do {
                conversations = try await chatRepository.searchConversations(query: query)
            } catch {
                print("Search failed: \(error)")
            }
        }
    }
    
    // MARK: - AI Modes
    func loadAIModes() {
        Task {
            do {
                aiModes = try await chatRepository.getAIModes()
                currentAIMode = aiModes.first
            } catch {
                aiModes = AIMode.defaultModes
            }
        }
    }
    
    func selectAIMode(_ mode: AIMode) {
        currentAIMode = mode
        selectedMode = mode.id
    }
    
    // MARK: - Usage
    func loadUsage() {
        Task {
            do {
                usageInfo = try await chatRepository.getUsage()
            } catch {
                print("Failed to load usage: \(error)")
            }
        }
    }
    
    // MARK: - Suggestions
    func loadSuggestions(lastResponse: String? = nil) {
        Task {
            do {
                suggestions = try await chatRepository.getSuggestions(
                    conversationId: currentConversationId,
                    lastResponse: lastResponse
                )
            } catch {
                suggestions = defaultSuggestions
            }
        }
    }
    
    private var defaultSuggestions: [String] {
        [
            "Tell me more about this",
            "Can you explain in simpler terms?",
            "What are some examples?",
            "What are the alternatives?"
        ]
    }
    
    func useSuggestion(_ suggestion: String) {
        inputText = suggestion
        Task {
            await sendMessage()
        }
    }
    
    // MARK: - User Profile
    func loadUserProfile() {
        Task {
            do {
                userProfile = try await profileRepository.getProfile()
            } catch {
                print("Failed to load profile: \(error)")
            }
        }
    }
    
    // MARK: - Sharing
    func createShareLink() {
        guard let conversationId = currentConversationId else { return }
        
        isSharing = true
        Task {
            do {
                let shareLink = try await chatRepository.createShareLink(
                    conversationId: conversationId,
                    expiresIn: nil
                )
                shareUrl = shareLink.fullUrl
            } catch {
                self.error = error.localizedDescription
            }
            isSharing = false
        }
    }
    
    // MARK: - Feedback
    func submitFeedback(messageId: String, isLike: Bool) {
        Task {
            guard let conversationId = currentConversationId else { return }
            
            do {
                try await chatRepository.submitFeedback(
                    messageId: messageId,
                    conversationId: conversationId,
                    feedback: isLike ? "like" : "dislike",
                    comment: nil
                )
            } catch {
                print("Failed to submit feedback: \(error)")
            }
        }
    }
    
    // MARK: - Regenerate
    func regenerateResponse() {
        guard let conversationId = currentConversationId else { return }
        
        Task {
            // Remove last assistant message
            if let lastMessage = messages.last, lastMessage.role == .assistant {
                messages.removeLast()
            }
            
            // Add streaming placeholder
            let streamingMessage = ChatMessage(
                content: "",
                role: .assistant,
                isStreaming: true
            )
            messages.append(streamingMessage)
            
            isSending = true
            
            do {
                let result = try await chatRepository.regenerateResponse(conversationId: conversationId)
                
                // Update streaming message
                if let lastIndex = messages.indices.last,
                   messages[lastIndex].isStreaming {
                    messages[lastIndex] = result
                    messages[lastIndex].isStreaming = false
                }
            } catch {
                if let lastIndex = messages.indices.last,
                   messages[lastIndex].isStreaming {
                    messages[lastIndex] = ChatMessage(
                        content: "Failed to regenerate response. Please try again.",
                        role: .assistant,
                        isStreaming: false
                    )
                }
            }
            
            isSending = false
        }
    }
    
    // MARK: - Clear Error
    func clearError() {
        error = nil
    }
}

// MARK: - Uploaded File State
struct UploadedFileState: Identifiable, Equatable {
    let id: String
    let url: URL
    let filename: String
    let mimeType: String
    var status: FileUploadStatus = .pending
    var remoteId: String?
    var previewUrl: String?
    var extractedText: String?
}

enum FileUploadStatus: String, Equatable {
    case pending
    case uploading
    case processing
    case ready
    case failed
}
