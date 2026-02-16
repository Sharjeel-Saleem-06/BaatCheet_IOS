//
//  AuthRepositoryImpl.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import Foundation

// MARK: - Auth Repository Implementation
final class AuthRepositoryImpl: AuthRepository {
    // MARK: - Properties
    private let apiClient: APIClient
    private let keychainHelper: KeychainHelper
    private let userDefaults: UserDefaults
    
    // MARK: - Keys
    private enum Keys {
        static let authToken = "auth_token"
        static let userData = "user_data"
        static let pendingEmail = "pending_email"
    }
    
    // MARK: - Init
    init(
        apiClient: APIClient,
        keychainHelper: KeychainHelper,
        userDefaults: UserDefaults
    ) {
        self.apiClient = apiClient
        self.keychainHelper = keychainHelper
        self.userDefaults = userDefaults
    }
    
    // MARK: - Sign In
    func signIn(email: String, password: String) async throws -> AuthResult {
        let request = SignInRequestDTO(email: email, password: password)
        let response: AuthResponseDTO = try await apiClient.post(
            endpoint: .signIn,
            body: request,
            requiresAuth: false
        )
        
        return processAuthResponse(response)
    }
    
    // MARK: - Sign Up
    func signUp(email: String, password: String, firstName: String?, lastName: String?) async throws -> AuthResult {
        let request = SignUpRequestDTO(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName
        )
        let response: AuthResponseDTO = try await apiClient.post(
            endpoint: .signUp,
            body: request,
            requiresAuth: false
        )
        
        return processAuthResponse(response, pendingEmail: email)
    }
    
    // MARK: - Sign In With Google
    func signInWithGoogle(idToken: String) async throws -> AuthResult {
        let request = GoogleSignInRequestDTO(idToken: idToken)
        let response: AuthResponseDTO = try await apiClient.post(
            endpoint: .googleSignIn,
            body: request,
            requiresAuth: false
        )
        
        return processAuthResponse(response)
    }
    
    // MARK: - Sign In With Apple
    func signInWithApple(idToken: String, authorizationCode: String, firstName: String?, lastName: String?) async throws -> AuthResult {
        let request = AppleSignInRequestDTO(
            idToken: idToken,
            authorizationCode: authorizationCode,
            firstName: firstName,
            lastName: lastName
        )
        let response: AuthResponseDTO = try await apiClient.post(
            endpoint: .appleSignIn,
            body: request,
            requiresAuth: false
        )
        
        return processAuthResponse(response)
    }
    
    // MARK: - Verify Email
    func verifyEmail(email: String, code: String) async throws -> AuthResult {
        let request = VerifyEmailRequestDTO(email: email, code: code)
        let response: AuthResponseDTO = try await apiClient.post(
            endpoint: .verifyEmail,
            body: request,
            requiresAuth: false
        )
        
        let result = processAuthResponse(response)
        
        if result.isSuccess {
            clearPendingEmail()
        }
        
        return result
    }
    
    // MARK: - Resend Verification Code
    func resendVerificationCode(email: String) async throws {
        let request = ResendCodeRequestDTO(email: email)
        let _: SuccessResponse = try await apiClient.post(
            endpoint: .resendCode,
            body: request,
            requiresAuth: false
        )
    }
    
    // MARK: - Forgot Password
    func forgotPassword(email: String) async throws {
        let request = ForgotPasswordRequestDTO(email: email)
        let _: SuccessResponse = try await apiClient.post(
            endpoint: .forgotPassword,
            body: request,
            requiresAuth: false
        )
    }
    
    // MARK: - Reset Password
    func resetPassword(email: String, code: String, newPassword: String) async throws {
        let request = ResetPasswordRequestDTO(
            email: email,
            code: code,
            newPassword: newPassword
        )
        let _: SuccessResponse = try await apiClient.post(
            endpoint: .resetPassword,
            body: request,
            requiresAuth: false
        )
    }
    
    // MARK: - Change Password
    func changePassword(currentPassword: String, newPassword: String) async throws {
        let request = ChangePasswordRequestDTO(
            currentPassword: currentPassword,
            newPassword: newPassword
        )
        let _: SuccessResponse = try await apiClient.post(
            endpoint: .changePassword,
            body: request,
            requiresAuth: true
        )
    }
    
    // MARK: - Logout
    func logout() async throws {
        do {
            let _: SuccessResponse = try await apiClient.post(
                endpoint: .logout,
                requiresAuth: true
            )
        } catch {
            // Continue with local logout even if server call fails
            print("Logout API call failed: \(error)")
        }
        
        clearSession()
    }
    
    // MARK: - Get Current User
    func getCurrentUser() async throws -> User {
        let response: AuthResponseDTO = try await apiClient.get(
            endpoint: .me,
            requiresAuth: true
        )
        
        guard response.success, let userData = response.data?.user else {
            throw AuthError.invalidCredentials
        }
        
        let user = userData.toDomain()
        saveUser(user)
        return user
    }
    
    // MARK: - Delete Account
    func deleteAccount() async throws {
        let _: SuccessResponse = try await apiClient.delete(
            endpoint: .deleteAccount,
            requiresAuth: true
        )
        
        clearSession()
    }
    
    // MARK: - Token Management
    func getAuthToken() -> String? {
        keychainHelper.get(key: Keys.authToken)
    }
    
    func isAuthenticated() -> Bool {
        getAuthToken() != nil
    }
    
    func clearSession() {
        keychainHelper.delete(key: Keys.authToken)
        userDefaults.removeObject(forKey: Keys.userData)
        clearPendingEmail()
    }
    
    // MARK: - Pending Email
    func getPendingEmail() -> String? {
        userDefaults.string(forKey: Keys.pendingEmail)
    }
    
    func savePendingEmail(_ email: String) {
        userDefaults.set(email, forKey: Keys.pendingEmail)
    }
    
    func clearPendingEmail() {
        userDefaults.removeObject(forKey: Keys.pendingEmail)
    }
    
    // MARK: - User Cache
    func saveUser(_ user: User) {
        if let data = try? JSONEncoder().encode(user) {
            userDefaults.set(data, forKey: Keys.userData)
        }
    }
    
    func getCachedUser() -> User? {
        guard let data = userDefaults.data(forKey: Keys.userData) else { return nil }
        return try? JSONDecoder().decode(User.self, from: data)
    }
    
    // MARK: - Private Helpers
    private func processAuthResponse(_ response: AuthResponseDTO, pendingEmail: String? = nil) -> AuthResult {
        guard response.success else {
            return .failure(AuthError.serverError(response.error ?? "Authentication failed"))
        }
        
        guard let data = response.data else {
            return .failure(AuthError.unknown)
        }
        
        // Check if verification is required
        if data.status == "verification_required" || data.status == "needs_verification" {
            let email = pendingEmail ?? data.email ?? ""
            savePendingEmail(email)
            return .needsVerification(email: email)
        }
        
        // Check for token and user
        guard let token = data.token, let userDTO = data.user else {
            return .failure(AuthError.invalidCredentials)
        }
        
        // Save token and user
        keychainHelper.save(key: Keys.authToken, value: token)
        let user = userDTO.toDomain()
        saveUser(user)
        
        return .success(token: token, userId: user.id, user: user)
    }
}
