//
//  EmailAuthView.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import SwiftUI
import GoogleSignIn

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
    @State private var showVerification = false
    
    enum Field {
        case firstName, lastName, email, password, confirmPassword
    }
    
    // MARK: - Body
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Spacer().frame(height: 16)
                
                Image("SplashLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 160, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 32))
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
                
                Spacer().frame(height: 32)
                
                // Title (matching Android: 26sp Bold)
                Text(mode == .signup ? "Create your account" : "Welcome back")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.black)
                
                Spacer().frame(height: 12)
                
                // Subtitle (matching Android: 15sp gray center)
                Text(mode == .signup
                     ? "Sign up to get smarter responses and access all features."
                     : "Sign in to continue your conversations.")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                
                Spacer().frame(height: 40)
                
                // Form
                formView
                
                Spacer().frame(height: 24)
                
                // Primary Button (matching Android: 52dp, radius 12, black bg)
                Button(action: {
                    focusedField = nil
                    Task {
                        if mode == .signin {
                            await authViewModel.signIn()
                        } else {
                            await authViewModel.signUp()
                        }
                    }
                }) {
                    HStack {
                        if authViewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(mode == .signup ? "Create Account" : "Sign In")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(authViewModel.isLoading ? Color.gray.opacity(0.15) : Color.black)
                    )
                }
                .disabled(authViewModel.isLoading)
                
                Spacer().frame(height: 24)
                
                // Divider (matching Android: "OR" with lines)
                HStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                    Text("OR")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 12)
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                }
                
                Spacer().frame(height: 24)
                
                // Google button (matching Android: outlined, 52dp, radius 12)
                Button(action: handleGoogleSignIn) {
                    HStack(spacing: 10) {
                        Image("GoogleIcon")
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text("Continue with Google")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                
                Spacer().frame(height: 24)
                
                // Mode toggle (matching Android: 14sp)
                HStack(spacing: 4) {
                    Text(mode == .signin ? "Don't have an account?" : "Already have an account?")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    NavigationLink(destination: EmailAuthView(mode: mode == .signin ? .signup : .signin)) {
                        Text(mode == .signin ? "Sign Up" : "Sign In")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black)
                    }
                }
                
                Spacer().frame(height: 24)
                
                // Footer links (matching Android: 13sp gray underline)
                HStack(spacing: 4) {
                    Link("Terms of Use", destination: URL(string: "https://baatcheet.app/terms")!)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .underline()
                    Text("and")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                    Link("Privacy Policy", destination: URL(string: "https://baatcheet.app/privacy")!)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .underline()
                }
                
                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 24)
        }
        .background(Color.white)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(width: 40, height: 40)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { focusedField = nil }
        .alert("Error", isPresented: .constant(authViewModel.error != nil)) {
            Button("OK") { authViewModel.clearError() }
        } message: {
            Text(authViewModel.error ?? "")
        }
        .onChange(of: authViewModel.authState) { _, newState in
            if case .needsVerification = newState {
                showVerification = true
            }
        }
        .navigationDestination(isPresented: $showVerification) {
            EmailVerificationView()
        }
    }
    
    // MARK: - Form (matching Android field styling)
    private var formView: some View {
        VStack(spacing: 16) {
            if mode == .signup {
                // Name fields in row (matching Android: Row with 12dp spacing)
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("First Name *")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                        AuthTextField(
                            placeholder: "First",
                            text: $authViewModel.firstName,
                            focused: $focusedField,
                            field: .firstName
                        )
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Last Name")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                        AuthTextField(
                            placeholder: "Last",
                            text: $authViewModel.lastName,
                            focused: $focusedField,
                            field: .lastName
                        )
                    }
                }
            }
            
            // Email field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                AuthTextField(
                    placeholder: "Enter your email",
                    text: $authViewModel.email,
                    focused: $focusedField,
                    field: .email,
                    keyboardType: .emailAddress,
                    autocapitalization: .never
                )
            }
            
            // Password field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                AuthSecureField(
                    placeholder: "Enter your password",
                    text: $authViewModel.password,
                    focused: $focusedField,
                    field: .password
                )
                
                // Forgot password (sign in only, matching Android: 14sp, #007AFF)
                if mode == .signin {
                    HStack {
                        Spacer()
                        NavigationLink(destination: ForgotPasswordView()) {
                            Text("Forgot Password?")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(hex: "007AFF"))
                        }
                    }
                }
            }
            
            if mode == .signup {
                // Confirm Password
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confirm Password")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                    AuthSecureField(
                        placeholder: "Confirm your password",
                        text: $authViewModel.confirmPassword,
                        focused: $focusedField,
                        field: .confirmPassword
                    )
                }
            }
        }
    }
    
    // MARK: - Google Sign-In
    private func handleGoogleSignIn() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { result, error in
            Task { @MainActor in
                if let error = error {
                    if (error as NSError).code != GIDSignInError.canceled.rawValue {
                        authViewModel.error = error.localizedDescription
                    }
                    return
                }
                guard let idToken = result?.user.idToken?.tokenString else {
                    authViewModel.error = "Failed to get Google ID token"
                    return
                }
                await authViewModel.signInWithGoogle(idToken: idToken)
            }
        }
    }
}

// MARK: - Auth Text Field (matching Android: RoundedCornerShape(12.dp), focused black border)
struct AuthTextField: View {
    let placeholder: String
    @Binding var text: String
    var focused: FocusState<EmailAuthView.Field?>.Binding
    var field: EmailAuthView.Field
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    
    var body: some View {
        TextField(placeholder, text: $text)
            .font(.system(size: 16))
            .keyboardType(keyboardType)
            .textInputAutocapitalization(autocapitalization)
            .autocorrectionDisabled()
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        focused.wrappedValue == field ? Color.black : Color.gray.opacity(0.3),
                        lineWidth: focused.wrappedValue == field ? 1.5 : 1
                    )
            )
            .focused(focused, equals: field)
    }
}

// MARK: - Auth Secure Field (matching Android: visibility toggle, gray icons)
struct AuthSecureField: View {
    let placeholder: String
    @Binding var text: String
    var focused: FocusState<EmailAuthView.Field?>.Binding
    var field: EmailAuthView.Field
    @State private var isSecure = true
    
    var body: some View {
        HStack {
            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(.system(size: 16))
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            
            Button(action: { isSecure.toggle() }) {
                Image(systemName: isSecure ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.gray)
                    .font(.system(size: 16))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    focused.wrappedValue == field ? Color.black : Color.gray.opacity(0.3),
                    lineWidth: focused.wrappedValue == field ? 1.5 : 1
                )
        )
        .focused(focused, equals: field)
    }
}

// MARK: - Email Verification View (matching Android exactly)
struct EmailVerificationView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var resendCountdown = 0
    @State private var resendTimer: Timer?
    @FocusState private var isCodeFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 40)
            
            // Mail icon (matching Android: 80dp, black tint)
            Image(systemName: "envelope.fill")
                .font(.system(size: 60))
                .foregroundColor(.black)
            
            Spacer().frame(height: 32)
            
            // Title (matching Android: 26sp Bold)
            Text("Check your email")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.black)
            
            Spacer().frame(height: 12)
            
            // Subtitle
            Text("We sent a verification code to")
                .font(.system(size: 15))
                .foregroundColor(.gray)
            
            Text(authViewModel.pendingEmail ?? authViewModel.email)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.black)
            
            Spacer().frame(height: 40)
            
            // Code input (matching Android: label + field)
            VStack(alignment: .leading, spacing: 8) {
                Text("Verification Code")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                
                TextField("Enter 6-digit code", text: $authViewModel.verificationCode)
                    .font(.system(size: 18, weight: .medium))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isCodeFocused ? Color.black : Color.gray.opacity(0.3),
                                lineWidth: isCodeFocused ? 1.5 : 1
                            )
                    )
                    .focused($isCodeFocused)
                    .onChange(of: authViewModel.verificationCode) { _, newValue in
                        // Limit to 6 digits
                        if newValue.count > 6 {
                            authViewModel.verificationCode = String(newValue.prefix(6))
                        }
                        authViewModel.verificationCode = newValue.filter { $0.isNumber }
                    }
            }
            .padding(.horizontal, 24)
            
            Spacer().frame(height: 24)
            
            // Verify button (matching Android: 52dp, radius 12, black)
            Button(action: {
                Task { await authViewModel.verifyEmail() }
            }) {
                HStack {
                    if authViewModel.verificationState == .loading {
                        ProgressView().tint(.white)
                    }
                    Text("Verify")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(authViewModel.verificationCode.count < 4 ? Color.gray.opacity(0.15) : Color.black)
                )
            }
            .disabled(authViewModel.verificationCode.count < 4 || authViewModel.verificationState == .loading)
            .padding(.horizontal, 24)
            
            Spacer().frame(height: 24)
            
            // Resend (matching Android: 60s countdown)
            if resendCountdown > 0 {
                Text("Resend code in \(resendCountdown)s")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
            } else {
                Button(action: {
                    Task {
                        await authViewModel.resendVerificationCode()
                        startResendCountdown()
                    }
                }) {
                    Text("Resend code")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(hex: "007AFF"))
                }
            }
            
            Spacer()
        }
        .background(Color.white)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.black)
                        .frame(width: 48, height: 48)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                }
            }
        }
        .onAppear {
            isCodeFocused = true
            startResendCountdown()
        }
        .onDisappear {
            resendTimer?.invalidate()
        }
        .alert("Error", isPresented: .constant(authViewModel.error != nil)) {
            Button("OK") { authViewModel.clearError() }
        } message: {
            Text(authViewModel.error ?? "")
        }
    }
    
    private func startResendCountdown() {
        resendCountdown = 60
        resendTimer?.invalidate()
        resendTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if resendCountdown > 0 {
                resendCountdown -= 1
            } else {
                resendTimer?.invalidate()
            }
        }
    }
}

// MARK: - Forgot Password View (matching Android: 3 steps)
struct ForgotPasswordView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var resetCode = ""
    @State private var newPassword = ""
    @State private var confirmNewPassword = ""
    @State private var isLoading = false
    @State private var step = 1
    @State private var showSuccess = false
    @State private var resendCountdown = 0
    @State private var resendTimer: Timer?
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 40)
            
            // Icon
            Image(systemName: step == 1 ? "lock.rotation" : step == 2 ? "envelope.badge" : "lock.shield")
                .font(.system(size: 60))
                .foregroundColor(.black)
            
            Spacer().frame(height: 32)
            
            // Title (matching Android: 28sp Bold)
            Text(step == 1 ? "Reset Password" : step == 2 ? "Enter Code" : "New Password")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.black)
            
            Spacer().frame(height: 12)
            
            // Subtitle
            Text(step == 1 ? "Enter your email to receive a reset code"
                 : step == 2 ? "Enter the code sent to \(email)"
                 : "Create a new password for your account")
                .font(.system(size: 15))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            Spacer().frame(height: 40)
            
            // Step content
            VStack(spacing: 16) {
                switch step {
                case 1:
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                        TextField("Enter your email", text: $email)
                            .font(.system(size: 16))
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                case 2:
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reset Code")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                        TextField("Enter 6-digit code", text: $resetCode)
                            .font(.system(size: 18, weight: .medium))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    if resendCountdown > 0 {
                        Text("Resend code in \(resendCountdown)s")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    } else {
                        Button("Resend Code") {
                            startResendCountdown()
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "007AFF"))
                    }
                    
                case 3:
                    VStack(alignment: .leading, spacing: 8) {
                        Text("New Password")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                        SecureField("Enter new password", text: $newPassword)
                            .font(.system(size: 16))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                        SecureField("Confirm new password", text: $confirmNewPassword)
                            .font(.system(size: 16))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                default:
                    EmptyView()
                }
            }
            .padding(.horizontal, 24)
            
            Spacer().frame(height: 24)
            
            // Action button
            Button(action: handleStepAction) {
                HStack {
                    if isLoading { ProgressView().tint(.white) }
                    Text(step == 1 ? "Send Reset Code" : step == 2 ? "Verify Code" : "Reset Password")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.black))
            }
            .padding(.horizontal, 24)
            .disabled(isLoading)
            
            Spacer()
        }
        .background(Color.white)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.black)
                        .frame(width: 48, height: 48)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                }
            }
        }
        .alert("Success", isPresented: $showSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text("Password reset successfully! You can now sign in with your new password.")
        }
    }
    
    private func handleStepAction() {
        switch step {
        case 1:
            Task {
                isLoading = true
                do {
                    try await authViewModel.authRepository.forgotPassword(email: email)
                    step = 2
                    startResendCountdown()
                } catch {
                    authViewModel.error = error.localizedDescription
                }
                isLoading = false
            }
        case 2:
            step = 3
        case 3:
            Task {
                isLoading = true
                do {
                    try await authViewModel.authRepository.resetPassword(
                        email: email, code: resetCode, newPassword: newPassword
                    )
                    showSuccess = true
                } catch {
                    authViewModel.error = error.localizedDescription
                }
                isLoading = false
            }
        default:
            break
        }
    }
    
    private func startResendCountdown() {
        resendCountdown = 60
        resendTimer?.invalidate()
        resendTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if resendCountdown > 0 { resendCountdown -= 1 }
            else { resendTimer?.invalidate() }
        }
    }
}

// MARK: - Reusable Components (kept for backward compatibility)
struct BCTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    
    var body: some View {
        HStack(spacing: 12) {
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
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

struct BCSecureField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    @State private var isSecure = true
    
    var body: some View {
        HStack(spacing: 12) {
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
                Image(systemName: isSecure ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        EmailAuthView(mode: .signup)
            .environmentObject(DependencyContainer.shared.authViewModel)
    }
}
