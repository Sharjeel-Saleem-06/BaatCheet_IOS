//
//  SplashView.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import SwiftUI

struct SplashView: View {
    // MARK: - State
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [Color.bcSecondary, Color.bcTertiary]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: BCSpacing.xl) {
                // Logo
                Image("login_image") // Same as Android
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 94)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                
                // App Name
                Text("BaatCheet")
                    .font(.bcLargeTitle)
                    .foregroundColor(.bcPrimary)
                    .opacity(textOpacity)
                
                // Tagline
                Text("Your AI Companion")
                    .font(.bcBody)
                    .foregroundColor(.bcPrimary.opacity(0.7))
                    .opacity(textOpacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                textOpacity = 1.0
            }
        }
    }
}

#Preview {
    SplashView()
}
