//
//  AuthResult.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import Foundation

// MARK: - Auth Result
enum AuthResult {
    case success(token: String, userId: String, user: User?)
    case needsVerification(email: String)
    case failure(Error)
    
    // MARK: - Properties
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
    
    var isFailure: Bool {
        if case .failure = self { return true }
        return false
    }
    
    var needsVerification: Bool {
        if case .needsVerification = self { return true }
        return false
    }
    
    // MARK: - Getters
    var token: String? {
        if case .success(let token, _, _) = self {
            return token
        }
        return nil
    }
    
    var userId: String? {
        if case .success(_, let userId, _) = self {
            return userId
        }
        return nil
    }
    
    var user: User? {
        if case .success(_, _, let user) = self {
            return user
        }
        return nil
    }
    
    var verificationEmail: String? {
        if case .needsVerification(let email) = self {
            return email
        }
        return nil
    }
    
    var error: Error? {
        if case .failure(let error) = self {
            return error
        }
        return nil
    }
}

// MARK: - Auth Error
enum AuthError: LocalizedError {
    case invalidCredentials
    case emailNotVerified
    case emailAlreadyExists
    case invalidVerificationCode
    case verificationCodeExpired
    case passwordTooWeak
    case networkError(Error)
    case serverError(String)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .emailNotVerified:
            return "Please verify your email address"
        case .emailAlreadyExists:
            return "An account with this email already exists"
        case .invalidVerificationCode:
            return "Invalid verification code"
        case .verificationCodeExpired:
            return "Verification code has expired. Please request a new one."
        case .passwordTooWeak:
            return "Password must be at least 8 characters with uppercase, lowercase, and numbers"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let message):
            return message
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

// MARK: - Auth State
enum AuthState: Equatable {
    case idle
    case loading
    case authenticated(User)
    case unauthenticated
    case needsVerification(email: String)
    case error(String)
}

// MARK: - Verification State
enum VerificationState: Equatable {
    case idle
    case loading
    case success
    case error(String)
}
