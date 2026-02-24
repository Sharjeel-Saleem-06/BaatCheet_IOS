//
//  ProfileRepositoryImpl.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import Foundation

// MARK: - Profile Repository Implementation
final class ProfileRepositoryImpl: ProfileRepository {
    // MARK: - Properties
    private let apiClient: APIClient
    private let authRepository: AuthRepository
    
    // MARK: - Init
    init(apiClient: APIClient, authRepository: AuthRepository) {
        self.apiClient = apiClient
        self.authRepository = authRepository
    }
    
    // MARK: - Get Profile
    func getProfile() async throws -> UserProfile {
        if let cachedUser = authRepository.getCachedUser() {
            return UserProfile(from: cachedUser)
        }
        
        struct ProfileResponseDTO: Decodable {
            let success: Bool
            let data: ProfileDataDTO?
        }
        
        struct ProfileDataDTO: Decodable {
            let profile: ProfileInfoDTO?
        }
        
        struct ProfileInfoDTO: Decodable {
            let id: String?
            let userId: String?
            let fullName: String?
            let preferredName: String?
        }
        
        let response: ProfileResponseDTO = try await apiClient.get(endpoint: .profileMe)
        
        guard response.success, let profileData = response.data?.profile else {
            throw ProfileError.notFound
        }
        
        let name = profileData.preferredName ?? profileData.fullName
        let user = User(
            id: profileData.userId ?? profileData.id ?? "",
            email: "",
            firstName: name,
            lastName: nil,
            avatar: nil,
            role: nil,
            tier: nil
        )
        return UserProfile(from: user)
    }
    
    // MARK: - Update Profile
    func updateProfile(firstName: String?, lastName: String?) async throws -> UserProfile {
        struct UpdateProfileRequestDTO: Encodable {
            let firstName: String?
            let lastName: String?
        }
        
        struct ProfileResponseDTO: Decodable {
            let success: Bool
            let data: UserDTO?
        }
        
        let request = UpdateProfileRequestDTO(firstName: firstName, lastName: lastName)
        let response: ProfileResponseDTO = try await apiClient.patch(
            endpoint: .profileSettings,
            body: request
        )
        
        guard response.success, let user = response.data else {
            throw ProfileError.updateFailed
        }
        
        let domainUser = user.toDomain()
        return UserProfile(from: domainUser)
    }
    
    // MARK: - Upload Avatar
    func uploadAvatar(imageData: Data, fileName: String) async throws -> String {
        struct AvatarResponseDTO: Decodable {
            let success: Bool
            let data: AvatarDataDTO?
        }
        
        struct AvatarDataDTO: Decodable {
            let url: String?
            let avatarUrl: String?
        }
        
        let response: AvatarResponseDTO = try await apiClient.upload(
            endpoint: .imageAvatar,
            fileData: imageData,
            fileName: fileName,
            mimeType: "image/jpeg",
            fieldName: "avatar"
        )
        
        guard response.success, let url = response.data?.url ?? response.data?.avatarUrl else {
            throw ProfileError.uploadFailed
        }
        
        return url
    }
    
    // MARK: - Get Facts
    func getFacts() async throws -> [LearnedFact] {
        struct FactsResponseDTO: Decodable {
            let success: Bool
            let data: FactsDataDTO?
        }
        
        struct FactsDataDTO: Decodable {
            let facts: [FactDTO]?
        }
        
        struct FactDTO: Decodable {
            let id: String
            let content: String
            let category: String?
            let createdAt: String?
        }
        
        let response: FactsResponseDTO = try await apiClient.get(endpoint: .profileFacts)
        
        guard response.success else {
            return []
        }
        
        return response.data?.facts?.map { dto in
            LearnedFact(
                id: dto.id,
                content: dto.content,
                category: dto.category,
                createdAt: dto.createdAt ?? ""
            )
        } ?? []
    }
    
    // MARK: - Teach Fact
    func teachFact(_ fact: String) async throws -> LearnedFact {
        struct TeachRequestDTO: Encodable {
            let fact: String
        }
        
        struct TeachResponseDTO: Decodable {
            let success: Bool
            let data: FactDataDTO?
        }
        
        struct FactDataDTO: Decodable {
            let id: String
            let content: String
            let category: String?
            let createdAt: String?
        }
        
        let request = TeachRequestDTO(fact: fact)
        let response: TeachResponseDTO = try await apiClient.post(
            endpoint: .profileTeach,
            body: request
        )
        
        guard response.success, let data = response.data else {
            throw ProfileError.teachFailed
        }
        
        return LearnedFact(
            id: data.id,
            content: data.content,
            category: data.category,
            createdAt: data.createdAt ?? ""
        )
    }
    
    // MARK: - Delete Fact
    func deleteFact(_ id: String) async throws {
        let _: SuccessResponse = try await apiClient.delete(endpoint: .profileFact(id: id))
    }
    
    // MARK: - Ask About Profile
    func askAboutProfile(_ question: String) async throws -> String {
        struct AskRequestDTO: Encodable {
            let question: String
        }
        
        struct AskResponseDTO: Decodable {
            let success: Bool
            let data: AskDataDTO?
        }
        
        struct AskDataDTO: Decodable {
            let answer: String?
        }
        
        let request = AskRequestDTO(question: question)
        let response: AskResponseDTO = try await apiClient.post(
            endpoint: .profileAsk,
            body: request
        )
        
        return response.data?.answer ?? "I don't have enough information to answer that."
    }
    
    // MARK: - Get Profile Summary
    func getProfileSummary() async throws -> ProfileSummary {
        struct SummaryResponseDTO: Decodable {
            let success: Bool
            let data: SummaryDataDTO?
        }
        
        struct SummaryDataDTO: Decodable {
            let summary: String?
            let keyFacts: [String]?
            let preferences: [String: String]?
            let totalFacts: Int?
        }
        
        let response: SummaryResponseDTO = try await apiClient.get(endpoint: .profileSummary)
        
        guard response.success, let data = response.data else {
            return ProfileSummary(summary: "", keyFacts: [], preferences: [:], totalFacts: 0)
        }
        
        return ProfileSummary(
            summary: data.summary ?? "",
            keyFacts: data.keyFacts ?? [],
            preferences: data.preferences ?? [:],
            totalFacts: data.totalFacts ?? 0
        )
    }
    
    // MARK: - Settings
    func getSettings() async throws -> UserSettings {
        // Return default settings for now
        return UserSettings(
            language: "en",
            theme: "system",
            notifications: true,
            autoPlayAudio: false,
            defaultModel: nil,
            defaultMode: nil
        )
    }
    
    func updateSettings(_ settings: UserSettings) async throws {
        // Settings update implementation
    }
    
    // MARK: - Analytics
    func getDashboard() async throws -> AnalyticsDashboard {
        struct DashboardResponseDTO: Decodable {
            let success: Bool
            let data: DashboardDataDTO?
        }
        
        struct DashboardDataDTO: Decodable {
            let totalConversations: Int?
            let totalMessages: Int?
            let totalTokens: Int?
            let averageResponseTime: Double?
        }
        
        let response: DashboardResponseDTO = try await apiClient.get(endpoint: .analyticsDashboard)
        
        guard response.success, let data = response.data else {
            return AnalyticsDashboard(
                totalConversations: 0,
                totalMessages: 0,
                totalTokens: 0,
                averageResponseTime: 0,
                topModes: [],
                activityByDay: []
            )
        }
        
        return AnalyticsDashboard(
            totalConversations: data.totalConversations ?? 0,
            totalMessages: data.totalMessages ?? 0,
            totalTokens: data.totalTokens ?? 0,
            averageResponseTime: data.averageResponseTime ?? 0,
            topModes: [],
            activityByDay: []
        )
    }
    
    func getUsageStats() async throws -> UsageStats {
        return UsageStats(
            period: "This Month",
            messages: 0,
            tokens: 0,
            images: 0,
            audioMinutes: 0
        )
    }
    
    func getTokenStats() async throws -> TokenStats {
        return TokenStats(
            totalPromptTokens: 0,
            totalCompletionTokens: 0,
            totalTokens: 0,
            averagePerMessage: 0
        )
    }
}

// MARK: - Profile Error
enum ProfileError: LocalizedError {
    case notFound
    case updateFailed
    case uploadFailed
    case teachFailed
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Profile not found"
        case .updateFailed:
            return "Failed to update profile"
        case .uploadFailed:
            return "Failed to upload avatar"
        case .teachFailed:
            return "Failed to save fact"
        }
    }
}
