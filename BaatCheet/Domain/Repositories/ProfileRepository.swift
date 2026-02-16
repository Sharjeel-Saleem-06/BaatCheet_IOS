//
//  ProfileRepository.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import Foundation

// MARK: - Profile Repository Protocol
protocol ProfileRepository {
    // MARK: - Profile
    func getProfile() async throws -> UserProfile
    func updateProfile(firstName: String?, lastName: String?) async throws -> UserProfile
    func uploadAvatar(imageData: Data, fileName: String) async throws -> String
    
    // MARK: - Memory/Facts
    func getFacts() async throws -> [LearnedFact]
    func teachFact(_ fact: String) async throws -> LearnedFact
    func deleteFact(_ id: String) async throws
    func askAboutProfile(_ question: String) async throws -> String
    func getProfileSummary() async throws -> ProfileSummary
    
    // MARK: - Settings
    func getSettings() async throws -> UserSettings
    func updateSettings(_ settings: UserSettings) async throws
    
    // MARK: - Analytics
    func getDashboard() async throws -> AnalyticsDashboard
    func getUsageStats() async throws -> UsageStats
    func getTokenStats() async throws -> TokenStats
}

// MARK: - Learned Fact Model
struct LearnedFact: Identifiable, Equatable {
    let id: String
    let content: String
    let category: String?
    let createdAt: String
    
    var formattedDate: String {
        guard let date = createdAt.iso8601Date else { return "" }
        return date.relativeString
    }
}

// MARK: - Profile Summary Model
struct ProfileSummary: Equatable {
    let summary: String
    let keyFacts: [String]
    let preferences: [String: String]
    let totalFacts: Int
}

// MARK: - User Settings Model
struct UserSettings: Codable, Equatable {
    var language: String
    var theme: String
    var notifications: Bool
    var autoPlayAudio: Bool
    var defaultModel: String?
    var defaultMode: String?
}

// MARK: - Analytics Models
struct AnalyticsDashboard: Equatable {
    let totalConversations: Int
    let totalMessages: Int
    let totalTokens: Int
    let averageResponseTime: Double
    let topModes: [ModeUsage]
    let activityByDay: [DayActivity]
}

struct ModeUsage: Identifiable, Equatable {
    let id: String
    let mode: String
    let count: Int
    let percentage: Double
}

struct DayActivity: Identifiable, Equatable {
    let id: String
    let date: String
    let messageCount: Int
    let tokenCount: Int
}

struct UsageStats: Equatable {
    let period: String
    let messages: Int
    let tokens: Int
    let images: Int
    let audioMinutes: Double
}

struct TokenStats: Equatable {
    let totalPromptTokens: Int
    let totalCompletionTokens: Int
    let totalTokens: Int
    let averagePerMessage: Int
}
