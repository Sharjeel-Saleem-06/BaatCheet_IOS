//
//  AuthViewModel.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import Foundation
import SwiftUI
import AuthenticationServices

// MARK: - Auth ViewModel
@MainActor
final class AuthViewModel: ObservableObject {
    // MARK: - Published State
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var error: String?
    @Published var pendingEmail: String?
    @Published var authState: AuthState = .idle
    @Published var verificationState: VerificationState = .idle
    
    // Form States
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var verificationCode = ""
    
    @Published var isGoogleLoading = false
    @Published var isAppleLoading = false
    
    // MARK: - Dependencies
    private let signInUseCase: SignInUseCase
    private let signUpUseCase: SignUpUseCase
    private let signInWithGoogleUseCase: SignInWithGoogleUseCase
    private let signInWithAppleUseCase: SignInWithAppleUseCase
    private let verifyEmailUseCase: VerifyEmailUseCase
    private let logoutUseCase: LogoutUseCase
    let authRepository: AuthRepository
    
    // MARK: - Init
    init(
        signInUseCase: SignInUseCase,
        signUpUseCase: SignUpUseCase,
        signInWithGoogleUseCase: SignInWithGoogleUseCase,
        signInWithAppleUseCase: SignInWithAppleUseCase,
        verifyEmailUseCase: VerifyEmailUseCase,
        logoutUseCase: LogoutUseCase,
        authRepository: AuthRepository
    ) {
        self.signInUseCase = signInUseCase
        self.signUpUseCase = signUpUseCase
        self.signInWithGoogleUseCase = signInWithGoogleUseCase
        self.signInWithAppleUseCase = signInWithAppleUseCase
        self.verifyEmailUseCase = verifyEmailUseCase
        self.logoutUseCase = logoutUseCase
        self.authRepository = authRepository
        
        checkAuthentication()
    }
    
    // MARK: - Check Authentication
    func checkAuthentication() {
        isAuthenticated = authRepository.isAuthenticated()
        currentUser = authRepository.getCachedUser()
        pendingEmail = authRepository.getPendingEmail()
        
        if isAuthenticated {
            authState = .authenticated(currentUser!)
        } else if pendingEmail != nil {
            authState = .needsVerification(email: pendingEmail!)
        } else {
            authState = .unauthenticated
        }
    }
    
    // MARK: - Sign In
    func signIn() async {
        guard validateSignInForm() else { return }
        
        isLoading = true
        error = nil
        authState = .loading
        
        do {
            let result = try await signInUseCase.execute(email: email, password: password)
            handleAuthResult(result)
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Sign Up
    func signUp() async {
        guard validateSignUpForm() else { return }
        
        isLoading = true
        error = nil
        authState = .loading
        
        do {
            let result = try await signUpUseCase.execute(
                email: email,
                password: password,
                firstName: firstName.isEmpty ? nil : firstName,
                lastName: lastName.isEmpty ? nil : lastName
            )
            handleAuthResult(result)
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Google Sign-In
    func signInWithGoogle(idToken: String) async {
        isGoogleLoading = true
        error = nil
        
        do {
            let result = try await signInWithGoogleUseCase.execute(idToken: idToken)
            handleAuthResult(result)
        } catch {
            handleError(error)
        }
        
        isGoogleLoading = false
    }
    
    // MARK: - Apple Sign-In
    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        isAppleLoading = true
        error = nil
        
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityTokenData = credential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8),
                  let authorizationCodeData = credential.authorizationCode,
                  let authorizationCode = String(data: authorizationCodeData, encoding: .utf8) else {
                error = "Failed to get Apple credentials"
                isAppleLoading = false
                return
            }
            
            let firstName = credential.fullName?.givenName
            let lastName = credential.fullName?.familyName
            
            do {
                let result = try await signInWithAppleUseCase.execute(
                    idToken: identityToken,
                    authorizationCode: authorizationCode,
                    firstName: firstName,
                    lastName: lastName
                )
                handleAuthResult(result)
            } catch {
                handleError(error)
            }
            
        case .failure(let error):
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                self.error = error.localizedDescription
            }
        }
        
        isAppleLoading = false
    }
    
    // MARK: - Verify Email
    func verifyEmail() async {
        guard let email = pendingEmail, !verificationCode.isEmpty else {
            error = "Please enter the verification code"
            return
        }
        
        verificationState = .loading
        error = nil
        
        do {
            let result = try await verifyEmailUseCase.execute(email: email, code: verificationCode)
            handleAuthResult(result)
            verificationState = .success
        } catch {
            handleError(error)
            verificationState = .error(error.localizedDescription)
        }
    }
    
    // MARK: - Resend Verification Code
    func resendVerificationCode() async {
        guard let email = pendingEmail else { return }
        
        do {
            try await authRepository.resendVerificationCode(email: email)
            // Show success message
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    // MARK: - Logout
    func logout() async {
        do {
            try await logoutUseCase.execute()
            resetState()
        } catch {
            // Still reset state even if server logout fails
            resetState()
        }
    }
    
    // MARK: - Reset State
    func resetState() {
        isAuthenticated = false
        currentUser = nil
        pendingEmail = nil
        authState = .unauthenticated
        clearForms()
    }
    
    func clearForms() {
        email = ""
        password = ""
        confirmPassword = ""
        firstName = ""
        lastName = ""
        verificationCode = ""
        error = nil
    }
    
    func clearError() {
        error = nil
    }
    
    // MARK: - Private Helpers
    private func handleAuthResult(_ result: AuthResult) {
        switch result {
        case .success(_, _, let user):
            isAuthenticated = true
            currentUser = user
            pendingEmail = nil
            authState = user != nil ? .authenticated(user!) : .unauthenticated
            clearForms()
            
        case .needsVerification(let email):
            pendingEmail = email
            authState = .needsVerification(email: email)
            
        case .failure(let error):
            handleError(error)
        }
    }
    
    private func handleError(_ error: Error) {
        self.error = error.localizedDescription
        authState = .error(error.localizedDescription)
    }
    
    private func validateSignInForm() -> Bool {
        guard email.isValidEmail else {
            error = "Please enter a valid email address"
            return false
        }
        
        guard !password.isEmpty else {
            error = "Please enter your password"
            return false
        }
        
        return true
    }
    
    private func validateSignUpForm() -> Bool {
        guard email.isValidEmail else {
            error = "Please enter a valid email address"
            return false
        }
        
        guard password.isValidPassword else {
            error = "Password must be at least 8 characters with uppercase, lowercase, and numbers"
            return false
        }
        
        guard password == confirmPassword else {
            error = "Passwords do not match"
            return false
        }
        
        return true
    }
}
