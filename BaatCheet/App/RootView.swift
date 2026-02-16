//
//  RootView.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import SwiftUI

struct RootView: View {
    // MARK: - Environment
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    // MARK: - Body
    var body: some View {
        ZStack {
            if appState.isShowingSplash {
                SplashView()
                    .transition(.opacity)
            } else if authViewModel.isAuthenticated {
                MainTabView()
                    .transition(.opacity)
            } else {
                NavigationStack {
                    LoginView()
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.isShowingSplash)
        .animation(.easeInOut(duration: 0.3), value: authViewModel.isAuthenticated)
        .onAppear {
            checkAuthAndHideSplash()
        }
    }
    
    // MARK: - Private Methods
    private func checkAuthAndHideSplash() {
        // Check authentication status
        authViewModel.checkAuthentication()
        
        // Hide splash after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                appState.isShowingSplash = false
            }
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            NavigationStack {
                ChatView()
            }
            .tabItem {
                Label("Chat", systemImage: "bubble.left.and.bubble.right.fill")
            }
            .tag(AppState.Tab.chat)
            
            NavigationStack {
                ProjectsView()
            }
            .tabItem {
                Label("Projects", systemImage: "folder.fill")
            }
            .tag(AppState.Tab.projects)
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(AppState.Tab.settings)
        }
        .tint(Color.bcPrimary)
    }
}

#Preview {
    RootView()
        .environmentObject(AppState())
        .environmentObject(DependencyContainer.shared.authViewModel)
        .environmentObject(DependencyContainer.shared.chatViewModel)
}
