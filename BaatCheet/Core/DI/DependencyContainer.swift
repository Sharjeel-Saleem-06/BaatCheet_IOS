//
//  DependencyContainer.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import Foundation

/// Dependency Container for managing app-wide dependencies
/// Following the Dependency Injection pattern for MVVM + Clean Architecture
@MainActor
final class DependencyContainer {
    // MARK: - Singleton
    static let shared = DependencyContainer()
    
    private init() {}
    
    // MARK: - Network Layer
    lazy var apiClient: APIClient = {
        APIClient(
            baseURL: APIConfig.baseURL,
            authProvider: authProvider
        )
    }()
    
    // MARK: - Auth Provider
    lazy var authProvider: AuthTokenProvider = {
        KeychainAuthProvider()
    }()
    
    // MARK: - Local Storage
    lazy var keychainHelper: KeychainHelper = {
        KeychainHelper()
    }()
    
    lazy var userDefaults: UserDefaults = {
        UserDefaults.standard
    }()
    
    // MARK: - Repositories
    lazy var authRepository: AuthRepository = {
        AuthRepositoryImpl(
            apiClient: apiClient,
            keychainHelper: keychainHelper,
            userDefaults: userDefaults
        )
    }()
    
    lazy var chatRepository: ChatRepository = {
        ChatRepositoryImpl(apiClient: apiClient)
    }()
    
    lazy var projectRepository: ProjectRepository = {
        ProjectRepositoryImpl(apiClient: apiClient)
    }()
    
    lazy var profileRepository: ProfileRepository = {
        ProfileRepositoryImpl(apiClient: apiClient, authRepository: authRepository)
    }()
    
    // MARK: - Use Cases
    // Auth Use Cases
    lazy var signInUseCase: SignInUseCase = {
        SignInUseCaseImpl(repository: authRepository)
    }()
    
    lazy var signUpUseCase: SignUpUseCase = {
        SignUpUseCaseImpl(repository: authRepository)
    }()
    
    lazy var signInWithGoogleUseCase: SignInWithGoogleUseCase = {
        SignInWithGoogleUseCaseImpl(repository: authRepository)
    }()
    
    lazy var signInWithAppleUseCase: SignInWithAppleUseCase = {
        SignInWithAppleUseCaseImpl(repository: authRepository)
    }()
    
    lazy var verifyEmailUseCase: VerifyEmailUseCase = {
        VerifyEmailUseCaseImpl(repository: authRepository)
    }()
    
    lazy var logoutUseCase: LogoutUseCase = {
        LogoutUseCaseImpl(repository: authRepository)
    }()
    
    // Chat Use Cases
    lazy var sendMessageUseCase: SendMessageUseCase = {
        SendMessageUseCaseImpl(repository: chatRepository)
    }()
    
    lazy var getConversationsUseCase: GetConversationsUseCase = {
        GetConversationsUseCaseImpl(repository: chatRepository)
    }()
    
    lazy var getConversationUseCase: GetConversationUseCase = {
        GetConversationUseCaseImpl(repository: chatRepository)
    }()
    
    // Project Use Cases
    lazy var getProjectsUseCase: GetProjectsUseCase = {
        GetProjectsUseCaseImpl(repository: projectRepository)
    }()
    
    lazy var createProjectUseCase: CreateProjectUseCase = {
        CreateProjectUseCaseImpl(repository: projectRepository)
    }()
    
    // MARK: - ViewModels
    lazy var authViewModel: AuthViewModel = {
        AuthViewModel(
            signInUseCase: signInUseCase,
            signUpUseCase: signUpUseCase,
            signInWithGoogleUseCase: signInWithGoogleUseCase,
            signInWithAppleUseCase: signInWithAppleUseCase,
            verifyEmailUseCase: verifyEmailUseCase,
            logoutUseCase: logoutUseCase,
            authRepository: authRepository
        )
    }()
    
    lazy var chatViewModel: ChatViewModel = {
        ChatViewModel(
            sendMessageUseCase: sendMessageUseCase,
            getConversationsUseCase: getConversationsUseCase,
            getConversationUseCase: getConversationUseCase,
            chatRepository: chatRepository,
            profileRepository: profileRepository
        )
    }()
    
    lazy var projectsViewModel: ProjectsViewModel = {
        ProjectsViewModel(
            getProjectsUseCase: getProjectsUseCase,
            createProjectUseCase: createProjectUseCase,
            projectRepository: projectRepository
        )
    }()
}

// MARK: - Auth Token Provider Protocol
protocol AuthTokenProvider {
    func getToken() -> String?
    func saveToken(_ token: String)
    func clearToken()
}

// MARK: - Keychain Auth Provider
final class KeychainAuthProvider: AuthTokenProvider {
    private let keychainHelper = KeychainHelper()
    private let tokenKey = "auth_token"
    
    func getToken() -> String? {
        keychainHelper.get(key: tokenKey)
    }
    
    func saveToken(_ token: String) {
        keychainHelper.save(key: tokenKey, value: token)
    }
    
    func clearToken() {
        keychainHelper.delete(key: tokenKey)
    }
}
