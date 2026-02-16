//
//  AuthRepository.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import Foundation

// MARK: - Auth Repository Protocol
protocol AuthRepository {
    // MARK: - Authentication
    func signIn(email: String, password: String) async throws -> AuthResult
    func signUp(email: String, password: String, firstName: String?, lastName: String?) async throws -> AuthResult
    func signInWithGoogle(idToken: String) async throws -> AuthResult
    func signInWithApple(idToken: String, authorizationCode: String, firstName: String?, lastName: String?) async throws -> AuthResult
    
    // MARK: - Verification
    func verifyEmail(email: String, code: String) async throws -> AuthResult
    func resendVerificationCode(email: String) async throws
    
    // MARK: - Password
    func forgotPassword(email: String) async throws
    func resetPassword(email: String, code: String, newPassword: String) async throws
    func changePassword(currentPassword: String, newPassword: String) async throws
    
    // MARK: - Session
    func logout() async throws
    func getCurrentUser() async throws -> User
    func getAuthToken() -> String?
    func isAuthenticated() -> Bool
    func clearSession()
    
    // MARK: - Account
    func deleteAccount() async throws
    
    // MARK: - Local Storage
    func getPendingEmail() -> String?
    func savePendingEmail(_ email: String)
    func clearPendingEmail()
    func saveUser(_ user: User)
    func getCachedUser() -> User?
}
