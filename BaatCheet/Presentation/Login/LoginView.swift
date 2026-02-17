//
//  LoginView.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import SwiftUI
import AuthenticationServices
import GoogleSignIn

// MARK: - Carousel Slide
struct CarouselSlide: Identifiable {
    let id = UUID()
    let backgroundColor: Color
    let text: String
    var textColor: Color = .black
    var hasImage: Bool = false
}

struct LoginView: View {
    // MARK: - Environment
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - State
    @State private var currentSlideIndex = 0
    @State private var displayedText = ""
    @State private var timer: Timer?
    @State private var showEmailAuth = false
    @State private var emailAuthMode: AuthMode = .signup
    
    // MARK: - Slides (Matching Android exactly)
    private let slides = [
        CarouselSlide(backgroundColor: Color(hex: "7BE8BE"), text: "", hasImage: true),
        CarouselSlide(backgroundColor: Color(hex: "9EF8EE"), text: "Let's brainstorm", textColor: Color(hex: "0000F5")),
        CarouselSlide(backgroundColor: Color(hex: "0000F5"), text: "Let's go", textColor: Color(hex: "9EF8EE"))
    ]
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Animated Background (1000ms transition matching Android)
                slides[currentSlideIndex].backgroundColor
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 1.0), value: currentSlideIndex)
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Content Area
                    contentView
                        .frame(maxWidth: .infinity)
                        .frame(height: geometry.size.height * 0.45)
                    
                    Spacer()
                    
                    // Bottom Sheet (matching Android: black, rounded top 38dp)
                    bottomSheet
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            startCarouselTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .alert("Error", isPresented: .constant(authViewModel.error != nil)) {
            Button("OK") {
                authViewModel.clearError()
            }
        } message: {
            Text(authViewModel.error ?? "")
        }
    }
    
    // MARK: - Content View
    @ViewBuilder
    private var contentView: some View {
        if slides[currentSlideIndex].hasImage {
            // Logo image (matching Android: 292x137dp, scale 0.8->1 spring)
            Image("LoginImage")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 292, height: 137)
                .transition(.scale.combined(with: .opacity))
        } else {
            // Typewriter text (matching Android: 34sp, FontWeight.Medium)
            Text(displayedText)
                .font(.system(size: 34, weight: .medium))
                .foregroundColor(slides[currentSlideIndex].textColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .transition(.opacity)
        }
    }
    
    // MARK: - Bottom Sheet
    private var bottomSheet: some View {
        VStack(spacing: 12) {
            // Continue with Google (matching Android: height 50, gray 36% opacity, radius 14)
            Button(action: handleGoogleSignIn) {
                HStack(spacing: 10) {
                    if authViewModel.isGoogleLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image("GoogleIcon")
                            .resizable()
                            .frame(width: 20, height: 20)
                    }
                    Text(authViewModel.isGoogleLoading ? "Signing in..." : "Continue with Google")
                        .font(.system(size: 20, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(authViewModel.isGoogleLoading)
            
            // Sign in with Apple (matching Android style but using native Apple button)
            SignInWithAppleButton(
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    Task {
                        await authViewModel.handleAppleSignIn(result: result)
                    }
                }
            )
            .signInWithAppleButtonStyle(.white)
            .frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            
            // Sign up with email (matching Android: gray button with mail icon)
            NavigationLink(destination: EmailAuthView(mode: .signup)) {
                HStack(spacing: 10) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 18))
                    Text("Sign up with email")
                        .font(.system(size: 20, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            
            // Log in (matching Android: outlined, border #38383A)
            NavigationLink(destination: EmailAuthView(mode: .signin)) {
                Text("Log in")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(hex: "38383A"), lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 25)
        .padding(.top, 25)
        .padding(.bottom, 40)
        .background(Color.black)
        .clipShape(
            .rect(
                topLeadingRadius: 38,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 38
            )
        )
    }
    
    // MARK: - Timer (4s per slide matching Android)
    private func startCarouselTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentSlideIndex = (currentSlideIndex + 1) % slides.count
            }
            animateTypewriter()
        }
    }
    
    // Typewriter animation (80ms per character, 300ms delay - matching Android)
    private func animateTypewriter() {
        let targetText = slides[currentSlideIndex].text
        displayedText = ""
        
        guard !targetText.isEmpty else { return }
        
        var charIndex = 0
        Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { timer in
            if charIndex < targetText.count {
                let index = targetText.index(targetText.startIndex, offsetBy: charIndex)
                displayedText.append(targetText[index])
                charIndex += 1
            } else {
                timer.invalidate()
            }
        }
    }
    
    // MARK: - Google Sign-In
    private func handleGoogleSignIn() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            authViewModel.error = "Unable to find root view controller"
            return
        }
        
        authViewModel.isGoogleLoading = true
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { result, error in
            Task { @MainActor in
                if let error = error {
                    if (error as NSError).code != GIDSignInError.canceled.rawValue {
                        authViewModel.error = error.localizedDescription
                    }
                    authViewModel.isGoogleLoading = false
                    return
                }
                
                guard let idToken = result?.user.idToken?.tokenString else {
                    authViewModel.error = "Failed to get Google ID token"
                    authViewModel.isGoogleLoading = false
                    return
                }
                
                await authViewModel.signInWithGoogle(idToken: idToken)
            }
        }
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environmentObject(DependencyContainer.shared.authViewModel)
    }
}
