//
//  LoginView.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import SwiftUI
import GoogleSignIn

struct CarouselSlide: Identifiable {
    let id = UUID()
    let backgroundColor: Color
    let text: String
    var textColor: Color = .black
    var hasImage: Bool = false
}

struct LoginView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    // Navigation callback - login screen is NOT inside NavigationStack
    var navigateTo: ((LoginFlowView.LoginDestination) -> Void)?
    
    @State private var currentSlideIndex = 0
    @State private var displayedText = ""
    @State private var timer: Timer?
    
    private let slides = [
        CarouselSlide(backgroundColor: Color(hex: "7BE8BE"), text: "", hasImage: true),
        CarouselSlide(backgroundColor: Color(hex: "9EF8EE"), text: "Let's brainstorm", textColor: Color(hex: "0000F5")),
        CarouselSlide(backgroundColor: Color(hex: "0000F5"), text: "Let's go", textColor: Color(hex: "9EF8EE"))
    ]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background color fills entire screen
            slides[currentSlideIndex].backgroundColor
                .animation(.easeInOut(duration: 1.0), value: currentSlideIndex)
            
            // Carousel content centered above the bottom sheet
            contentView
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding(.bottom, 250)
            
            // Bottom sheet
            bottomSheet
        }
        .ignoresSafeArea(.all)
        .onAppear { startCarouselTimer() }
        .onDisappear { timer?.invalidate() }
        .alert("Error", isPresented: .constant(authViewModel.error != nil)) {
            Button("OK") { authViewModel.clearError() }
        } message: {
            Text(authViewModel.error ?? "")
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if slides[currentSlideIndex].hasImage {
            Image("LoginImage")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 292, height: 137)
        } else {
            Text(displayedText)
                .font(.system(size: 34, weight: .medium))
                .foregroundColor(slides[currentSlideIndex].textColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
    
    private var bottomSheet: some View {
        VStack(spacing: 12) {
            // Continue with Google
            Button(action: handleGoogleSignIn) {
                HStack(spacing: 10) {
                    if authViewModel.isGoogleLoading {
                        ProgressView().tint(.white)
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
            
            // Sign up with email
            Button {
                navigateTo?(.emailAuth(isSignIn: false))
            } label: {
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
            
            // Log in
            Button {
                navigateTo?(.emailAuth(isSignIn: true))
            } label: {
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
        .padding(.bottom, 34)
        .frame(maxWidth: .infinity)
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
    
    private func startCarouselTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentSlideIndex = (currentSlideIndex + 1) % slides.count
            }
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
    LoginView()
        .environmentObject(DependencyContainer.shared.authViewModel)
}
