//
//  AIMode.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import Foundation

// MARK: - AI Mode Model
struct AIMode: Identifiable, Equatable {
    let id: String
    let displayName: String
    let icon: String
    let description: String
    let capabilities: [String]
    let requiresSpecialAPI: Bool
    let freeDailyLimit: Int
    let proDailyLimit: Int
    
    // MARK: - Computed Properties
    var isLimited: Bool {
        requiresSpecialAPI || freeDailyLimit <= 10
    }
    
    var isPremium: Bool {
        requiresSpecialAPI
    }
    
    // MARK: - Default Modes
    static let defaultModes: [AIMode] = [
        AIMode(
            id: "chat",
            displayName: "Chat",
            icon: "💬",
            description: "General conversation",
            capabilities: ["conversation", "questions", "advice"],
            requiresSpecialAPI: false,
            freeDailyLimit: 1000,
            proDailyLimit: 10000
        ),
        AIMode(
            id: "code",
            displayName: "Code",
            icon: "💻",
            description: "Programming assistance",
            capabilities: ["coding", "debugging", "algorithms"],
            requiresSpecialAPI: false,
            freeDailyLimit: 100,
            proDailyLimit: 1000
        ),
        AIMode(
            id: "image-generation",
            displayName: "Create Image",
            icon: "🎨",
            description: "Generate images from text",
            capabilities: ["image-generation", "art", "design"],
            requiresSpecialAPI: true,
            freeDailyLimit: 1,
            proDailyLimit: 50
        ),
        AIMode(
            id: "vision",
            displayName: "Analyze Image",
            icon: "👁️",
            description: "Analyze and describe images",
            capabilities: ["image-analysis", "ocr", "description"],
            requiresSpecialAPI: true,
            freeDailyLimit: 10,
            proDailyLimit: 200
        ),
        AIMode(
            id: "web-search",
            displayName: "Browse",
            icon: "🌐",
            description: "Search the web for current info",
            capabilities: ["web-search", "current-events", "real-time"],
            requiresSpecialAPI: true,
            freeDailyLimit: 10,
            proDailyLimit: 200
        ),
        AIMode(
            id: "creative",
            displayName: "Write",
            icon: "✍️",
            description: "Creative writing",
            capabilities: ["stories", "poems", "scripts"],
            requiresSpecialAPI: false,
            freeDailyLimit: 50,
            proDailyLimit: 500
        ),
        AIMode(
            id: "math",
            displayName: "Math",
            icon: "🔢",
            description: "Mathematical problem solving",
            capabilities: ["calculations", "equations", "proofs"],
            requiresSpecialAPI: false,
            freeDailyLimit: 50,
            proDailyLimit: 500
        ),
        AIMode(
            id: "translate",
            displayName: "Translate",
            icon: "🌍",
            description: "Language translation",
            capabilities: ["translation", "languages"],
            requiresSpecialAPI: false,
            freeDailyLimit: 50,
            proDailyLimit: 500
        ),
        AIMode(
            id: "summarize",
            displayName: "Summarize",
            icon: "📝",
            description: "Summarize long content",
            capabilities: ["summarization", "key-points"],
            requiresSpecialAPI: false,
            freeDailyLimit: 50,
            proDailyLimit: 500
        ),
        AIMode(
            id: "tutor",
            displayName: "Tutor",
            icon: "👨‍🏫",
            description: "Patient teaching mode",
            capabilities: ["teaching", "step-by-step", "learning"],
            requiresSpecialAPI: false,
            freeDailyLimit: 50,
            proDailyLimit: 500
        )
    ]
}

// MARK: - Usage Info Model
struct UsageInfo: Equatable {
    let tier: String
    let messagesUsed: Int
    let messagesLimit: Int
    let messagesRemaining: Int
    let messagesPercentage: Int
    let imagesUsed: Int
    let imagesLimit: Int
    let imagesRemaining: Int
    let imagesPercentage: Int
    let resetAt: String
    
    // MARK: - Computed Properties
    var isMessageLimitReached: Bool {
        messagesRemaining <= 0
    }
    
    var isImageLimitReached: Bool {
        imagesRemaining <= 0
    }
    
    var quotaDescription: String {
        "\(messagesRemaining)/\(messagesLimit) messages • \(imagesRemaining)/\(imagesLimit) images"
    }
    
    var isFreeTier: Bool {
        tier == "free"
    }
    
    var isPro: Bool {
        tier == "pro"
    }
    
    var messageUsagePercentage: Double {
        guard messagesLimit > 0 else { return 0 }
        return Double(messagesUsed) / Double(messagesLimit)
    }
    
    var imageUsagePercentage: Double {
        guard imagesLimit > 0 else { return 0 }
        return Double(imagesUsed) / Double(imagesLimit)
    }
    
    // MARK: - Default
    static let `default` = UsageInfo(
        tier: "free",
        messagesUsed: 0,
        messagesLimit: 50,
        messagesRemaining: 50,
        messagesPercentage: 0,
        imagesUsed: 0,
        imagesLimit: 1,
        imagesRemaining: 1,
        imagesPercentage: 0,
        resetAt: ""
    )
}

// MARK: - Prompt Analysis Result
struct PromptAnalysisResult: Equatable {
    let detectedMode: String
    let modeDisplayName: String
    let modeIcon: String
    let modeConfidence: Double
    let alternatives: [String]
    let intent: String
    let format: String
    let complexity: String
    let language: String
    let suggestedTemperature: Double
    let suggestedMaxTokens: Int
    let formattingHints: String
    let shouldMakeTable: Bool
    let shouldUseCode: Bool
    let codeLanguage: String?
    
    // MARK: - Computed Properties
    var isHighConfidence: Bool {
        modeConfidence >= 0.7
    }
    
    var needsSpecialRendering: Bool {
        shouldMakeTable || shouldUseCode || format == "table" || format == "code"
    }
    
    var isImageRequest: Bool {
        detectedMode == "image-generation"
    }
    
    var isCodeRequest: Bool {
        detectedMode == "code" || shouldUseCode
    }
}

// MARK: - Suggestion Model
struct Suggestion: Identifiable, Equatable {
    let id: String
    let text: String
    
    init(text: String) {
        self.id = UUID().uuidString
        self.text = text
    }
}
