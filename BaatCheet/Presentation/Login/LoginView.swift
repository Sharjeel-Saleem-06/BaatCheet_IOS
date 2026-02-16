//
//  LoginView.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import SwiftUI
import AuthenticationServices

// MARK: - Carousel Slide
struct CarouselSlide {
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
    
    // MARK: - Slides (Matching Android)
    private let slides = [
        CarouselSlide(backgroundColor: .carouselMint, text: "", hasImage: true),
        CarouselSlide(backgroundColor: .carouselCyan, text: "Let's brainstorm", textColor: .bcPrimary),
        CarouselSlide(backgroundColor: .carouselBlue, text: "Let's go", textColor: .bcCyan)
    ]
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Animated Background
                slides[currentSlideIndex].backgroundColor
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 1), value: currentSlideIndex)
                
                VStack {
                    Spacer()
                    
                    // Content Area
                    contentView
                        .frame(height: 200)
                    
                    Spacer()
                    
                    // Bottom Sheet
                    bottomSheet
                }
            }
        }
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
            Image("login_image")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 292, height: 137)
                .transition(.opacity)
        } else {
            Text(displayedText)
                .font(.bcTypewriter)
                .foregroundColor(slides[currentSlideIndex].textColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, BCSpacing.xl)
                .transition(.opacity)
        }
    }
    
    // MARK: - Bottom Sheet
    private var bottomSheet: some View {
        VStack(spacing: BCSpacing.sm) {
            // Google Sign-In
            GoogleSignInButton(
                isLoading: authViewModel.isGoogleLoading,
                action: handleGoogleSignIn
            )
            
            // Apple Sign-In
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
            .frame(height: BCButtonHeight.large)
            .cornerRadius(BCCornerRadius.button)
            
            // Email Sign-Up
            NavigationLink(destination: EmailAuthView(mode: .signup)) {
                HStack(spacing: BCSpacing.xs) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 18))
                    Text("Sign up with email")
                        .font(.bcButtonLarge)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: BCButtonHeight.large)
                .background(Color.gray.opacity(0.36))
                .cornerRadius(BCCornerRadius.button)
            }
            
            // Login
            NavigationLink(destination: EmailAuthView(mode: .signin)) {
                Text("Log in")
                    .font(.bcButtonLarge)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: BCButtonHeight.large)
                    .overlay(
                        RoundedRectangle(cornerRadius: BCCornerRadius.button)
                            .stroke(Color(hex: "38383A"), lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 25)
        .padding(.top, 25)
        .padding(.bottom, 40)
        .background(Color.black)
        .cornerRadius(BCCornerRadius.sheet, corners: [.topLeft, .topRight])
    }
    
    // MARK: - Timer
    private func startCarouselTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            withAnimation {
                currentSlideIndex = (currentSlideIndex + 1) % slides.count
            }
            animateTypewriter()
        }
        
        // Start first animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            animateTypewriter()
        }
    }
    
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
        // Implement Google Sign-In using GoogleSignIn SDK
        // This would require the GoogleSignIn pod/package
        print("Google Sign-In tapped")
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environmentObject(DependencyContainer.shared.authViewModel)
    }
}
