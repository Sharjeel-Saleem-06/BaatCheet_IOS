//
//  ConversationDTOs.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import Foundation

// MARK: - Conversations List Response
struct ConversationsResponseDTO: Decodable {
    let success: Bool
    let data: ConversationsDataDTO?
    let error: String?
}

struct ConversationsDataDTO: Decodable {
    let items: [ConversationDTO]?
    let pagination: PaginationDTO?
    
    let conversations: [ConversationDTO]?
    let total: Int?
    let page: Int?
    let limit: Int?
    
    var allConversations: [ConversationDTO] {
        items ?? conversations ?? []
    }
}

struct PaginationDTO: Decodable {
    let page: Int?
    let limit: Int?
    let total: Int?
    let totalPages: Int?
}

// MARK: - Single Conversation Response
struct ConversationResponseDTO: Decodable {
    let success: Bool
    let data: ConversationDetailDTO?
    let error: String?
}

struct ConversationDetailDTO: Decodable {
    let id: String?
    let title: String?
    let userId: String?
    let projectId: String?
    let systemPrompt: String?
    let model: String?
    let tags: [String]?
    let isArchived: Bool?
    let isPinned: Bool?
    let totalTokens: Int?
    let createdAt: String?
    let updatedAt: String?
    let messages: [MessageDTO]?
    let conversation: ConversationDTO?
    
    var resolvedConversation: ConversationDTO {
        if let conversation = conversation {
            return conversation
        }
        return ConversationDTO(
            id: id ?? "",
            title: title,
            userId: userId,
            projectId: projectId,
            messageCount: messages?.count,
            isPinned: isPinned,
            isArchived: isArchived,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastMessage: nil,
            tags: tags
        )
    }
}

// MARK: - Conversation DTO
struct ConversationDTO: Decodable {
    let id: String
    let title: String?
    let userId: String?
    let projectId: String?
    let messageCount: Int?
    let isPinned: Bool?
    let isArchived: Bool?
    let createdAt: String?
    let updatedAt: String?
    let lastMessage: MessageDTO?
    let tags: [String]?
    
    func toDomain() -> Conversation {
        Conversation(
            id: id,
            title: title ?? "New Chat",
            messageCount: messageCount ?? 0,
            isPinned: isPinned ?? false,
            isArchived: isArchived ?? false,
            projectId: projectId,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

// MARK: - Message DTO
struct MessageDTO: Decodable {
    let id: String
    let conversationId: String?
    let role: String
    let content: String
    let timestamp: String?
    let createdAt: String?
    let attachments: [AttachmentDTO]?
    let imageResult: ImageResultDTO?
    let feedback: String?
    let tokens: TokenInfoDTO?
    
    enum CodingKeys: String, CodingKey {
        case id, conversationId, role, content, timestamp, createdAt
        case attachments, imageResult, feedback, tokens
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        conversationId = try container.decodeIfPresent(String.self, forKey: .conversationId)
        role = try container.decode(String.self, forKey: .role)
        content = try container.decode(String.self, forKey: .content)
        timestamp = try container.decodeIfPresent(String.self, forKey: .timestamp)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        attachments = try container.decodeIfPresent([AttachmentDTO].self, forKey: .attachments)
        imageResult = try container.decodeIfPresent(ImageResultDTO.self, forKey: .imageResult)
        feedback = try container.decodeIfPresent(String.self, forKey: .feedback)
        
        if let tokenInfo = try? container.decodeIfPresent(TokenInfoDTO.self, forKey: .tokens) {
            tokens = tokenInfo
        } else if let tokenCount = try? container.decodeIfPresent(Int.self, forKey: .tokens) {
            tokens = TokenInfoDTO(prompt: nil, completion: nil, total: tokenCount)
        } else {
            tokens = nil
        }
    }
    
    func toDomain() -> ChatMessage {
        ChatMessage(
            id: id,
            content: content,
            role: MessageRole(rawValue: role) ?? .assistant,
            timestamp: (timestamp ?? createdAt)?.iso8601Date ?? Date(),
            isStreaming: false,
            conversationId: conversationId,
            attachments: attachments?.map { $0.toDomain() } ?? [],
            imageResult: imageResult?.toDomain()
        )
    }
}

// MARK: - Attachment DTO
struct AttachmentDTO: Decodable {
    let id: String?
    let filename: String?
    let mimeType: String?
    let url: String?
    let thumbnailUrl: String?
    let size: Int?
    let status: String?
    
    func toDomain() -> MessageAttachment {
        MessageAttachment(
            id: id ?? UUID().uuidString,
            filename: filename ?? "file",
            mimeType: mimeType ?? "application/octet-stream",
            url: url,
            thumbnailUrl: thumbnailUrl,
            status: status ?? "unknown"
        )
    }
}

// MARK: - Create/Update Conversation
struct CreateConversationRequestDTO: Encodable {
    let title: String?
    let projectId: String?
}

struct UpdateConversationRequestDTO: Encodable {
    let title: String?
    let isPinned: Bool?
    let isArchived: Bool?
}

// MARK: - Search Response
struct SearchConversationsResponseDTO: Decodable {
    let success: Bool
    let data: SearchResultsDTO?
}

struct SearchResultsDTO: Decodable {
    let conversations: [ConversationDTO]?
    let messages: [MessageDTO]?
    let total: Int?
}

// MARK: - Share Response
struct ShareResponseDTO: Decodable {
    let success: Bool
    let data: ShareDataDTO?
}

struct ShareDataDTO: Decodable {
    let shareId: String?
    let url: String?
    let expiresAt: String?
    
    func toDomain() -> ShareLink {
        ShareLink(
            shareId: shareId ?? "",
            url: url ?? "",
            expiresAt: expiresAt
        )
    }
}

struct CreateShareRequestDTO: Encodable {
    let conversationId: String
    let expiresIn: Int?  // hours
}

// MARK: - Shared Conversation Response
struct SharedConversationResponseDTO: Decodable {
    let success: Bool
    let data: SharedConversationDataDTO?
}

struct SharedConversationDataDTO: Decodable {
    let conversation: ConversationDTO?
    let messages: [MessageDTO]?
    let sharedBy: UserDTO?
    let expiresAt: String?
}
