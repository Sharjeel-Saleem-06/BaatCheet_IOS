//
//  APIConfig.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import Foundation

/// API Configuration
enum APIConfig {
    // MARK: - Base URLs
    #if DEBUG
    static let baseURL = "https://sharry121-baatcheet.hf.space/api/v1"
    #else
    static let baseURL = "https://sharry121-baatcheet.hf.space/api/v1"
    #endif
    
    static let mobileAuthURL = "\(baseURL)/mobile/auth"
    
    // MARK: - Timeouts
    static let defaultTimeout: TimeInterval = 30
    static let uploadTimeout: TimeInterval = 120
    static let imageGenTimeout: TimeInterval = 180
    
    // MARK: - Headers
    static let contentTypeJSON = "application/json"
    static let contentTypeMultipart = "multipart/form-data"
    
    // MARK: - API Versions
    static let apiVersion = "v1"
}

// MARK: - HTTP Methods
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - API Endpoints
enum APIEndpoint {
    // Auth
    case signIn
    case signUp
    case verifyEmail
    case resendCode
    case logout
    case forgotPassword
    case resetPassword
    case changePassword
    case googleSignIn
    case appleSignIn
    case me
    case deleteAccount
    
    // Chat
    case chatCompletions
    case chatRegenerate
    case chatFeedback
    case chatModels
    case chatModes
    case chatUsage
    case chatSuggest
    case chatAnalyze
    case providersHealth
    
    // Conversations
    case conversations
    case conversation(id: String)
    case conversationSearch
    
    // Projects
    case projects
    case project(id: String)
    case projectConversations(id: String)
    case projectContextRefresh(id: String)
    
    // Project Collaboration
    case projectCheckEmail(email: String)
    case projectInvite(id: String)
    case projectInvitationsPending
    case projectInvitationRespond(id: String)
    case projectCollaborations
    case projectCollaborators(id: String)
    case projectRemoveCollaborator(projectId: String, collaboratorId: String)
    case projectChangeRole(projectId: String, collaboratorId: String)
    
    // Project Chat
    case projectChatMessages(id: String)
    case projectChatMessage(projectId: String, messageId: String)
    case projectChatSettings(id: String)
    case projectChatUnreadCount(id: String)
    case projectChatReadAll(id: String)
    
    // Audio
    case audioUpload
    case audioTranscribe
    case audioTranscribeUpload
    case audioVoiceChat
    case audioTranslate
    
    // TTS
    case ttsGenerate
    case ttsVoices
    case ttsStatus
    
    // Images
    case imagesUpload
    case image(id: String)
    case imageStatus(id: String)
    case imageOCR
    case imageAnalyze
    case imageAvatar
    
    // Image Generation
    case imageGenGenerate
    case imageGenVariations(id: String)
    case imageGenEnhancePrompt
    case imageGenModels
    case imageGenStyles
    case imageGenAspectRatios
    case imageGenStatus
    case imageGenHistory
    
    // Files
    case filesUpload
    case filesUploadStatus
    case file(id: String)
    case fileStatus(id: String)
    case fileContent(id: String)
    
    // Profile
    case profileMe
    case profileSettings
    case profileFacts
    case profileTeach
    case profileFact(id: String)
    case profileAsk
    case profileSummary
    
    // Share
    case chatShare
    case sharedChat(shareId: String)
    case revokeShare(shareId: String)
    
    // Analytics
    case analyticsDashboard
    case analyticsUsage
    case analyticsTokens
    
    // Search
    case search
    
    // Tags
    case tags
    case tag(id: String)
    
    // Modes
    case modes
    
    // Templates
    case templates
    case template(id: String)
    
    // Webhooks
    case webhooks
    case webhook(id: String)
    
    // API Keys
    case apiKeys
    case apiKey(id: String)
    
    // GDPR
    case gdprExport
    case gdprDelete
    case gdprDownload(exportId: String)
    
    // Health
    case health
    
    // MARK: - Path
    var path: String {
        switch self {
        // Auth
        case .signIn: return "/mobile/auth/signin"
        case .signUp: return "/mobile/auth/signup"
        case .verifyEmail: return "/mobile/auth/verify-email"
        case .resendCode: return "/mobile/auth/resend-code"
        case .logout: return "/mobile/auth/logout"
        case .forgotPassword: return "/mobile/auth/forgot-password"
        case .resetPassword: return "/mobile/auth/reset-password"
        case .changePassword: return "/mobile/auth/change-password"
        case .googleSignIn: return "/auth/google"
        case .appleSignIn: return "/auth/apple"
        case .me: return "/auth/me"
        case .deleteAccount: return "/auth/account"
            
        // Chat
        case .chatCompletions: return "/chat/completions"
        case .chatRegenerate: return "/chat/regenerate"
        case .chatFeedback: return "/chat/feedback"
        case .chatModels: return "/chat/models"
        case .chatModes: return "/chat/modes"
        case .chatUsage: return "/chat/usage"
        case .chatSuggest: return "/chat/suggest"
        case .chatAnalyze: return "/chat/analyze"
        case .providersHealth: return "/chat/providers/health"
            
        // Conversations
        case .conversations: return "/conversations"
        case .conversation(let id): return "/conversations/\(id)"
        case .conversationSearch: return "/conversations/search"
            
        // Projects
        case .projects: return "/projects"
        case .project(let id): return "/projects/\(id)"
        case .projectConversations(let id): return "/projects/\(id)/conversations"
        case .projectContextRefresh(let id): return "/projects/\(id)/context/refresh"
            
        // Project Collaboration
        case .projectCheckEmail(let email): return "/projects/check-email/\(email)"
        case .projectInvite(let id): return "/projects/\(id)/invite"
        case .projectInvitationsPending: return "/projects/invitations/pending"
        case .projectInvitationRespond(let id): return "/projects/invitations/\(id)/respond"
        case .projectCollaborations: return "/projects/collaborations"
        case .projectCollaborators(let id): return "/projects/\(id)/collaborators"
        case .projectRemoveCollaborator(let projectId, let collaboratorId): return "/projects/\(projectId)/collaborators/\(collaboratorId)"
        case .projectChangeRole(let projectId, let collaboratorId): return "/projects/\(projectId)/collaborators/\(collaboratorId)/role"
            
        // Project Chat
        case .projectChatMessages(let id): return "/projects/\(id)/chat/messages"
        case .projectChatMessage(let projectId, let messageId): return "/projects/\(projectId)/chat/messages/\(messageId)"
        case .projectChatSettings(let id): return "/projects/\(id)/chat/settings"
        case .projectChatUnreadCount(let id): return "/projects/\(id)/chat/unread-count"
        case .projectChatReadAll(let id): return "/projects/\(id)/chat/read-all"
            
        // Audio
        case .audioUpload: return "/audio/upload"
        case .audioTranscribe: return "/audio/transcribe"
        case .audioTranscribeUpload: return "/audio/transcribe-upload"
        case .audioVoiceChat: return "/audio/voice-chat"
        case .audioTranslate: return "/audio/translate"
            
        // TTS
        case .ttsGenerate: return "/tts/generate"
        case .ttsVoices: return "/tts/voices"
        case .ttsStatus: return "/tts/status"
            
        // Images
        case .imagesUpload: return "/images/upload"
        case .image(let id): return "/images/\(id)"
        case .imageStatus(let id): return "/images/\(id)/status"
        case .imageOCR: return "/images/ocr"
        case .imageAnalyze: return "/images/analyze"
        case .imageAvatar: return "/images/avatar"
            
        // Image Generation
        case .imageGenGenerate: return "/image-gen/generate"
        case .imageGenVariations(let id): return "/image-gen/variations/\(id)"
        case .imageGenEnhancePrompt: return "/image-gen/enhance-prompt"
        case .imageGenModels: return "/image-gen/models"
        case .imageGenStyles: return "/image-gen/styles"
        case .imageGenAspectRatios: return "/image-gen/aspect-ratios"
        case .imageGenStatus: return "/image-gen/status"
        case .imageGenHistory: return "/image-gen/history"
            
        // Files
        case .filesUpload: return "/files/upload"
        case .filesUploadStatus: return "/files/upload-status"
        case .file(let id): return "/files/\(id)"
        case .fileStatus(let id): return "/files/\(id)/status"
        case .fileContent(let id): return "/files/\(id)/content"
            
        // Profile
        case .profileMe: return "/profile/me"
        case .profileSettings: return "/profile/settings"
        case .profileFacts: return "/profile/facts"
        case .profileTeach: return "/profile/teach"
        case .profileFact(let id): return "/profile/facts/\(id)"
        case .profileAsk: return "/profile/ask"
        case .profileSummary: return "/profile/summary"
            
        // Share
        case .chatShare: return "/chat/share"
        case .sharedChat(let shareId): return "/chat/share/\(shareId)"
        case .revokeShare(let shareId): return "/chat/share/\(shareId)"
            
        // Analytics
        case .analyticsDashboard: return "/analytics/dashboard"
        case .analyticsUsage: return "/analytics/usage"
        case .analyticsTokens: return "/analytics/tokens"
            
        // Search
        case .search: return "/search"
            
        // Tags
        case .tags: return "/tags"
        case .tag(let id): return "/tags/\(id)"
            
        // Modes
        case .modes: return "/modes"
            
        // Templates
        case .templates: return "/templates"
        case .template(let id): return "/templates/\(id)"
            
        // Webhooks
        case .webhooks: return "/webhooks"
        case .webhook(let id): return "/webhooks/\(id)"
            
        // API Keys
        case .apiKeys: return "/api-keys"
        case .apiKey(let id): return "/api-keys/\(id)"
            
        // GDPR
        case .gdprExport: return "/gdpr/export"
        case .gdprDelete: return "/gdpr/delete"
        case .gdprDownload(let exportId): return "/gdpr/download/\(exportId)"
            
        // Health
        case .health: return "/health"
        }
    }
    
    // MARK: - Full URL
    var url: URL {
        URL(string: APIConfig.baseURL + path)!
    }
}
