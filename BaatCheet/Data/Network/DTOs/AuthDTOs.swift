//
//  AuthDTOs.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import Foundation

// MARK: - Auth Response
struct AuthResponseDTO: Decodable {
    let success: Bool
    let data: AuthDataDTO?
    let error: String?
}

struct AuthDataDTO: Decodable {
    let user: UserDTO?
    let token: String?
    let status: String?
    let message: String?
    let email: String?
}

// MARK: - User DTO
struct UserDTO: Decodable {
    let id: String
    let email: String
    let firstName: String?
    let lastName: String?
    let avatar: String?
    let role: String?
    let tier: String?
    let username: String?
    let createdAt: String?
    let updatedAt: String?
    let emailVerified: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, email, firstName, lastName, avatar, role, tier, username
        case createdAt, updatedAt, emailVerified
    }
    
    // MARK: - To Domain
    func toDomain() -> User {
        User(
            id: id,
            email: email,
            firstName: firstName,
            lastName: lastName,
            avatar: avatar,
            role: role,
            tier: tier
        )
    }
}

// MARK: - Request DTOs

struct SignInRequestDTO: Encodable {
    let email: String
    let password: String
}

struct SignUpRequestDTO: Encodable {
    let email: String
    let password: String
    let firstName: String?
    let lastName: String?
}

struct VerifyEmailRequestDTO: Encodable {
    let email: String
    let code: String
}

struct ResendCodeRequestDTO: Encodable {
    let email: String
}

struct ForgotPasswordRequestDTO: Encodable {
    let email: String
}

struct ResetPasswordRequestDTO: Encodable {
    let email: String
    let code: String
    let newPassword: String
}

struct ChangePasswordRequestDTO: Encodable {
    let currentPassword: String
    let newPassword: String
}

struct GoogleSignInRequestDTO: Encodable {
    let idToken: String
}

struct AppleSignInRequestDTO: Encodable {
    let idToken: String
    let authorizationCode: String
    let firstName: String?
    let lastName: String?
}

// MARK: - Auth Status
enum AuthStatus: String, Decodable {
    case success
    case verificationRequired = "verification_required"
    case needsVerification = "needs_verification"
    case error
}
