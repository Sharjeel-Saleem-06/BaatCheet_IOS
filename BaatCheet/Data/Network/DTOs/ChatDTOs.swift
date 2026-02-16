//
//  ChatDTOs.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import Foundation

// MARK: - Chat Request
struct ChatRequestDTO: Encodable {
    let message: String
    let conversationId: String?
    let model: String?
    let systemPrompt: String?
    let stream: Bool
    let imageIds: [String]?
    let maxTokens: Int?
    let temperature: Float?
    let mode: String?
    let projectId: String?
    let isVoiceChat: Bool
    
    init(
        message: String,
        conversationId: String? = nil,
        model: String? = nil,
        systemPrompt: String? = nil,
        stream: Bool = false,
        imageIds: [String]? = nil,
        maxTokens: Int? = nil,
        temperature: Float? = nil,
        mode: String? = nil,
        projectId: String? = nil,
        isVoiceChat: Bool = false
    ) {
        self.message = message
        self.conversationId = conversationId
        self.model = model
        self.systemPrompt = systemPrompt
        self.stream = stream
        self.imageIds = imageIds
        self.maxTokens = maxTokens
        self.temperature = temperature
        self.mode = mode
        self.projectId = projectId
        self.isVoiceChat = isVoiceChat
    }
}

// MARK: - Chat Response
struct ChatResponseDTO: Decodable {
    let success: Bool
    let data: ChatDataDTO?
    let error: String?
}

struct ChatDataDTO: Decodable {
    let message: ChatMessageDTO?
    let conversationId: String?
    let model: String?
    let provider: String?
    let tokens: TokenInfoDTO?
    let imageResult: ImageResultDTO?
    let modeDetected: String?
    let tagDetected: String?
}

struct ChatMessageDTO: Decodable {
    let id: String?
    let role: String?
    let content: String?
    let timestamp: String?
    let attachments: [MessageAttachmentDTO]?
    
    func toDomain(conversationId: String?) -> ChatMessage {
        ChatMessage(
            id: id ?? UUID().uuidString,
            content: content ?? "",
            role: MessageRole(rawValue: role ?? "assistant") ?? .assistant,
            timestamp: timestamp?.iso8601Date ?? Date(),
            isStreaming: false,
            conversationId: conversationId,
            attachments: attachments?.map { $0.toDomain() } ?? []
        )
    }
}

struct MessageAttachmentDTO: Decodable {
    let id: String?
    let filename: String?
    let mimeType: String?
    let url: String?
    let thumbnailUrl: String?
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

struct TokenInfoDTO: Decodable {
    let prompt: Int?
    let completion: Int?
    let total: Int?
}

struct ImageResultDTO: Decodable {
    let success: Bool?
    let imageUrl: String?
    let imageBase64: String?
    let model: String?
    let originalPrompt: String?
    let enhancedPrompt: String?
    let seed: Int64?
    let generationTime: Int64?
    let style: String?
    let error: String?
    
    func toDomain() -> ImageResult {
        ImageResult(
            success: success ?? false,
            imageUrl: imageUrl,
            imageBase64: imageBase64,
            model: model,
            originalPrompt: originalPrompt,
            enhancedPrompt: enhancedPrompt,
            seed: seed,
            generationTime: generationTime,
            style: style,
            error: error
        )
    }
}

// MARK: - Regenerate Request
struct RegenerateRequestDTO: Encodable {
    let conversationId: String
}

// MARK: - Feedback Request
struct FeedbackRequestDTO: Encodable {
    let messageId: String
    let conversationId: String
    let feedback: String  // "like" or "dislike"
    let comment: String?
}

// MARK: - Modes Response
struct ModesResponseDTO: Decodable {
    let success: Bool
    let data: ModesDataDTO?
}

struct ModesDataDTO: Decodable {
    let modes: [AIModeDTO]
    let total: Int?
}

struct AIModeDTO: Decodable {
    let id: String
    let displayName: String
    let icon: String
    let description: String
    let capabilities: [String]
    let requiresSpecialAPI: Bool
    let dailyLimits: DailyLimitsDTO?
    
    func toDomain() -> AIMode {
        AIMode(
            id: id,
            displayName: displayName,
            icon: icon,
            description: description,
            capabilities: capabilities,
            requiresSpecialAPI: requiresSpecialAPI,
            freeDailyLimit: dailyLimits?.free ?? 50,
            proDailyLimit: dailyLimits?.pro ?? 500
        )
    }
}

struct DailyLimitsDTO: Decodable {
    let free: Int?
    let pro: Int?
    let enterprise: Int?
}

// MARK: - Usage Response
struct UsageResponseDTO: Decodable {
    let success: Bool
    let data: UsageDataDTO?
}

struct UsageDataDTO: Decodable {
    let tier: String?
    let messagesUsed: Int?
    let messagesLimit: Int?
    let messagesRemaining: Int?
    let messagesPercentage: Int?
    let imagesUsed: Int?
    let imagesLimit: Int?
    let imagesRemaining: Int?
    let imagesPercentage: Int?
    let resetAt: String?
    
    func toDomain() -> UsageInfo {
        UsageInfo(
            tier: tier ?? "free",
            messagesUsed: messagesUsed ?? 0,
            messagesLimit: messagesLimit ?? 50,
            messagesRemaining: messagesRemaining ?? 50,
            messagesPercentage: messagesPercentage ?? 0,
            imagesUsed: imagesUsed ?? 0,
            imagesLimit: imagesLimit ?? 1,
            imagesRemaining: imagesRemaining ?? 1,
            imagesPercentage: imagesPercentage ?? 0,
            resetAt: resetAt ?? ""
        )
    }
}

// MARK: - Suggestions Response
struct SuggestionsResponseDTO: Decodable {
    let success: Bool
    let data: SuggestionsDataDTO?
}

struct SuggestionsDataDTO: Decodable {
    let suggestions: [String]?
}

struct SuggestRequestDTO: Encodable {
    let conversationId: String?
    let lastResponse: String?
}

// MARK: - Analyze Prompt
struct AnalyzeRequestDTO: Encodable {
    let prompt: String
    let conversationId: String?
}

struct AnalyzeResponseDTO: Decodable {
    let success: Bool
    let data: PromptAnalysisDTO?
}

struct PromptAnalysisDTO: Decodable {
    let detectedMode: String?
    let modeDisplayName: String?
    let modeIcon: String?
    let modeConfidence: Double?
    let alternatives: [String]?
    let intent: String?
    let format: String?
    let complexity: String?
    let language: String?
    let suggestedTemperature: Double?
    let suggestedMaxTokens: Int?
    let formattingHints: String?
    let shouldMakeTable: Bool?
    let shouldUseCode: Bool?
    let codeLanguage: String?
    
    func toDomain() -> PromptAnalysisResult {
        PromptAnalysisResult(
            detectedMode: detectedMode ?? "chat",
            modeDisplayName: modeDisplayName ?? "Chat",
            modeIcon: modeIcon ?? "💬",
            modeConfidence: modeConfidence ?? 0.5,
            alternatives: alternatives ?? [],
            intent: intent ?? "unknown",
            format: format ?? "text",
            complexity: complexity ?? "simple",
            language: language ?? "en",
            suggestedTemperature: suggestedTemperature ?? 0.7,
            suggestedMaxTokens: suggestedMaxTokens ?? 1024,
            formattingHints: formattingHints ?? "",
            shouldMakeTable: shouldMakeTable ?? false,
            shouldUseCode: shouldUseCode ?? false,
            codeLanguage: codeLanguage
        )
    }
}
