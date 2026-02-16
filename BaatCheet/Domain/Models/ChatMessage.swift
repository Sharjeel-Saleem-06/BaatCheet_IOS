//
//  ChatMessage.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import Foundation

// MARK: - Message Role
enum MessageRole: String, Codable, CaseIterable {
    case user
    case assistant
    case system
}

// MARK: - Chat Message Model
struct ChatMessage: Identifiable, Equatable {
    let id: String
    var content: String
    let role: MessageRole
    let timestamp: Date
    var isStreaming: Bool
    var conversationId: String?
    var attachments: [MessageAttachment]
    var imageResult: ImageResult?
    
    // MARK: - Init
    init(
        id: String = UUID().uuidString,
        content: String,
        role: MessageRole,
        timestamp: Date = Date(),
        isStreaming: Bool = false,
        conversationId: String? = nil,
        attachments: [MessageAttachment] = [],
        imageResult: ImageResult? = nil
    ) {
        self.id = id
        self.content = content
        self.role = role
        self.timestamp = timestamp
        self.isStreaming = isStreaming
        self.conversationId = conversationId
        self.attachments = attachments
        self.imageResult = imageResult
    }
    
    // MARK: - Computed Properties
    var isUser: Bool {
        role == .user
    }
    
    var isAssistant: Bool {
        role == .assistant
    }
    
    var hasAttachments: Bool {
        !attachments.isEmpty
    }
    
    var hasImageResult: Bool {
        imageResult?.success == true
    }
    
    var formattedTimestamp: String {
        timestamp.chatTimestamp
    }
}

// MARK: - Message Attachment
struct MessageAttachment: Identifiable, Equatable {
    let id: String
    let filename: String
    let mimeType: String
    var url: String?
    var thumbnailUrl: String?
    var status: String
    
    // MARK: - Computed Properties
    var isImage: Bool {
        mimeType.hasPrefix("image/")
    }
    
    var isPDF: Bool {
        mimeType == "application/pdf"
    }
    
    var isDocument: Bool {
        mimeType.contains("document") || mimeType.contains("text/")
    }
    
    var iconName: String {
        if isImage { return "photo" }
        if isPDF { return "doc.text" }
        if isDocument { return "doc" }
        return "paperclip"
    }
}

// MARK: - Image Result
struct ImageResult: Equatable {
    let success: Bool
    let imageUrl: String?
    let imageBase64: String?
    let model: String?
    let originalPrompt: String?
    let enhancedPrompt: String?
    let seed: Int64?
    let generationTime: Int64?
    let style: String?
    let error: String?
    
    // MARK: - Computed Properties
    var displayUrl: String? {
        imageUrl ?? imageBase64.map { "data:image/png;base64,\($0)" }
    }
    
    var generationTimeString: String? {
        guard let time = generationTime else { return nil }
        return "\(time)ms"
    }
}

// MARK: - Conversation
struct Conversation: Identifiable, Equatable {
    let id: String
    var title: String
    let messageCount: Int
    var isPinned: Bool
    var isArchived: Bool
    let projectId: String?
    let createdAt: String?
    let updatedAt: String?
    
    // MARK: - Computed Properties
    var formattedDate: String {
        guard let dateString = updatedAt ?? createdAt,
              let date = dateString.iso8601Date else {
            return ""
        }
        return date.conversationTimestamp
    }
    
    var isInProject: Bool {
        projectId != nil
    }
}

// MARK: - Share Link
struct ShareLink: Equatable {
    let shareId: String
    let url: String
    let expiresAt: String?
    
    var fullUrl: String {
        url.isEmpty ? "https://baatcheet-web.netlify.app/share/\(shareId)" : url
    }
}
