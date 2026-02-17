//
//  SplashView.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import SwiftUI

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var loaderOpacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.white

            VStack(spacing: 48) {
                Image("SplashLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 220, height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 44))
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 8)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                
                ProgressView()
                    .controlSize(.regular)
                    .tint(Color(hex: "1E3A8A"))
                    .scaleEffect(1.2)
                    .opacity(loaderOpacity)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6, blendDuration: 0)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                loaderOpacity = 1.0
            }
        }
    }
}

#Preview {
    SplashView()
}
