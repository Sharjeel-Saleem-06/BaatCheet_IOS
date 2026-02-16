//
//  SignInUseCase.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import Foundation

// MARK: - Sign In Use Case Protocol
protocol SignInUseCase {
    func execute(email: String, password: String) async throws -> AuthResult
}

// MARK: - Sign In Use Case Implementation
final class SignInUseCaseImpl: SignInUseCase {
    private let repository: AuthRepository
    
    init(repository: AuthRepository) {
        self.repository = repository
    }
    
    func execute(email: String, password: String) async throws -> AuthResult {
        // Validate inputs
        guard email.isValidEmail else {
            throw AuthError.invalidCredentials
        }
        
        guard !password.isEmpty else {
            throw AuthError.invalidCredentials
        }
        
        return try await repository.signIn(email: email, password: password)
    }
}

// MARK: - Sign Up Use Case Protocol
protocol SignUpUseCase {
    func execute(email: String, password: String, firstName: String?, lastName: String?) async throws -> AuthResult
}

// MARK: - Sign Up Use Case Implementation
final class SignUpUseCaseImpl: SignUpUseCase {
    private let repository: AuthRepository
    
    init(repository: AuthRepository) {
        self.repository = repository
    }
    
    func execute(email: String, password: String, firstName: String?, lastName: String?) async throws -> AuthResult {
        // Validate inputs
        guard email.isValidEmail else {
            throw AuthError.invalidCredentials
        }
        
        guard password.isValidPassword else {
            throw AuthError.passwordTooWeak
        }
        
        return try await repository.signUp(
            email: email,
            password: password,
            firstName: firstName?.trimmed,
            lastName: lastName?.trimmed
        )
    }
}

// MARK: - Sign In With Google Use Case Protocol
protocol SignInWithGoogleUseCase {
    func execute(idToken: String) async throws -> AuthResult
}

// MARK: - Sign In With Google Use Case Implementation
final class SignInWithGoogleUseCaseImpl: SignInWithGoogleUseCase {
    private let repository: AuthRepository
    
    init(repository: AuthRepository) {
        self.repository = repository
    }
    
    func execute(idToken: String) async throws -> AuthResult {
        guard !idToken.isEmpty else {
            throw AuthError.invalidCredentials
        }
        
        return try await repository.signInWithGoogle(idToken: idToken)
    }
}

// MARK: - Sign In With Apple Use Case Protocol
protocol SignInWithAppleUseCase {
    func execute(idToken: String, authorizationCode: String, firstName: String?, lastName: String?) async throws -> AuthResult
}

// MARK: - Sign In With Apple Use Case Implementation
final class SignInWithAppleUseCaseImpl: SignInWithAppleUseCase {
    private let repository: AuthRepository
    
    init(repository: AuthRepository) {
        self.repository = repository
    }
    
    func execute(idToken: String, authorizationCode: String, firstName: String?, lastName: String?) async throws -> AuthResult {
        guard !idToken.isEmpty, !authorizationCode.isEmpty else {
            throw AuthError.invalidCredentials
        }
        
        return try await repository.signInWithApple(
            idToken: idToken,
            authorizationCode: authorizationCode,
            firstName: firstName,
            lastName: lastName
        )
    }
}

// MARK: - Verify Email Use Case Protocol
protocol VerifyEmailUseCase {
    func execute(email: String, code: String) async throws -> AuthResult
}

// MARK: - Verify Email Use Case Implementation
final class VerifyEmailUseCaseImpl: VerifyEmailUseCase {
    private let repository: AuthRepository
    
    init(repository: AuthRepository) {
        self.repository = repository
    }
    
    func execute(email: String, code: String) async throws -> AuthResult {
        guard email.isValidEmail else {
            throw AuthError.invalidCredentials
        }
        
        guard code.count >= 4 else {
            throw AuthError.invalidVerificationCode
        }
        
        return try await repository.verifyEmail(email: email, code: code)
    }
}

// MARK: - Logout Use Case Protocol
protocol LogoutUseCase {
    func execute() async throws
}

// MARK: - Logout Use Case Implementation
final class LogoutUseCaseImpl: LogoutUseCase {
    private let repository: AuthRepository
    
    init(repository: AuthRepository) {
        self.repository = repository
    }
    
    func execute() async throws {
        try await repository.logout()
        repository.clearSession()
    }
}
