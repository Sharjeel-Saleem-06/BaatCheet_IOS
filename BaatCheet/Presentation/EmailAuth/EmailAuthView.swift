//
//  EmailAuthView.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import SwiftUI

enum AuthMode {
    case signin
    case signup
}

struct EmailAuthView: View {
    // MARK: - Properties
    let mode: AuthMode
    
    // MARK: - Environment
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password, confirmPassword, firstName, lastName
    }
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: BCSpacing.xl) {
                // Header
                headerView
                
                // Form
                formView
                
                // Submit Button
                submitButton
                
                // Switch Mode
                switchModeView
            }
            .padding(.horizontal, BCSpacing.horizontalPadding)
            .padding(.vertical, BCSpacing.xl)
        }
        .background(Color(UIColor.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.primary)
                }
            }
        }
        .alert("Error", isPresented: .constant(authViewModel.error != nil)) {
            Button("OK") {
                authViewModel.clearError()
            }
        } message: {
            Text(authViewModel.error ?? "")
        }
        .onChange(of: authViewModel.authState) { _, newState in
            if case .needsVerification = newState {
                // Navigate to verification
            } else if case .authenticated = newState {
                dismiss()
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: BCSpacing.sm) {
            Text(mode == .signin ? "Welcome Back" : "Create Account")
                .font(.bcTitle1)
                .foregroundColor(.primary)
            
            Text(mode == .signin ? "Sign in to continue" : "Sign up to get started")
                .font(.bcBody)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Form
    private var formView: some View {
        VStack(spacing: BCSpacing.md) {
            if mode == .signup {
                // Name Fields
                HStack(spacing: BCSpacing.sm) {
                    BCTextField(
                        placeholder: "First Name",
                        text: $authViewModel.firstName,
                        icon: "person"
                    )
                    .focused($focusedField, equals: .firstName)
                    
                    BCTextField(
                        placeholder: "Last Name",
                        text: $authViewModel.lastName,
                        icon: "person"
                    )
                    .focused($focusedField, equals: .lastName)
                }
            }
            
            // Email
            BCTextField(
                placeholder: "Email",
                text: $authViewModel.email,
                icon: "envelope",
                keyboardType: .emailAddress,
                autocapitalization: .never
            )
            .focused($focusedField, equals: .email)
            
            // Password
            BCSecureField(
                placeholder: "Password",
                text: $authViewModel.password,
                icon: "lock"
            )
            .focused($focusedField, equals: .password)
            
            if mode == .signup {
                // Confirm Password
                BCSecureField(
                    placeholder: "Confirm Password",
                    text: $authViewModel.confirmPassword,
                    icon: "lock"
                )
                .focused($focusedField, equals: .confirmPassword)
            }
            
            if mode == .signin {
                // Forgot Password
                HStack {
                    Spacer()
                    NavigationLink(destination: ForgotPasswordView()) {
                        Text("Forgot Password?")
                            .font(.bcLabelLarge)
                            .foregroundColor(.bcPrimary)
                    }
                }
            }
        }
    }
    
    // MARK: - Submit Button
    private var submitButton: some View {
        BCLoadingButton(
            title: mode == .signin ? "Sign In" : "Sign Up",
            isLoading: authViewModel.isLoading
        ) {
            focusedField = nil
            Task {
                if mode == .signin {
                    await authViewModel.signIn()
                } else {
                    await authViewModel.signUp()
                }
            }
        }
    }
    
    // MARK: - Switch Mode
    private var switchModeView: some View {
        HStack(spacing: BCSpacing.xs) {
            Text(mode == .signin ? "Don't have an account?" : "Already have an account?")
                .font(.bcBody)
                .foregroundColor(.secondary)
            
            NavigationLink(destination: EmailAuthView(mode: mode == .signin ? .signup : .signin)) {
                Text(mode == .signin ? "Sign Up" : "Sign In")
                    .font(.bcBodyMedium)
                    .foregroundColor(.bcPrimary)
            }
        }
    }
}

// MARK: - Forgot Password View
struct ForgotPasswordView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    
    var body: some View {
        VStack(spacing: BCSpacing.xl) {
            // Header
            VStack(spacing: BCSpacing.sm) {
                Image(systemName: "lock.rotation")
                    .font(.system(size: 60))
                    .foregroundColor(.bcPrimary)
                
                Text("Reset Password")
                    .font(.bcTitle1)
                
                Text("Enter your email to receive a reset link")
                    .font(.bcBody)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, BCSpacing.xxl)
            
            // Email Field
            BCTextField(
                placeholder: "Email",
                text: $email,
                icon: "envelope",
                keyboardType: .emailAddress,
                autocapitalization: .never
            )
            
            // Submit Button
            BCLoadingButton(
                title: "Send Reset Link",
                isLoading: isLoading
            ) {
                // Handle forgot password
            }
            
            Spacer()
        }
        .padding(.horizontal, BCSpacing.horizontalPadding)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Success", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Password reset link sent to your email")
        }
    }
}

// MARK: - Text Field Component
struct BCTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    
    var body: some View {
        HStack(spacing: BCSpacing.sm) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .frame(width: 20)
            }
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled()
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(BCCornerRadius.md)
    }
}

// MARK: - Secure Field Component
struct BCSecureField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    
    @State private var isSecure = true
    
    var body: some View {
        HStack(spacing: BCSpacing.sm) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .frame(width: 20)
            }
            
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            
            Button(action: { isSecure.toggle() }) {
                Image(systemName: isSecure ? "eye.slash" : "eye")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(BCCornerRadius.md)
    }
}

#Preview {
    NavigationStack {
        EmailAuthView(mode: .signup)
            .environmentObject(DependencyContainer.shared.authViewModel)
    }
}
