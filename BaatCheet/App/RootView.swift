//
//  RootView.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            if appState.isShowingSplash {
                SplashView()
            } else if authViewModel.isAuthenticated {
                MainTabView()
            } else {
                LoginFlowView()
            }
        }
        .ignoresSafeArea(.all)
        .animation(.easeInOut(duration: 0.3), value: appState.isShowingSplash)
        .animation(.easeInOut(duration: 0.3), value: authViewModel.isAuthenticated)
        .onAppear {
            checkAuthAndHideSplash()
        }
    }
    
    private func checkAuthAndHideSplash() {
        authViewModel.checkAuthentication()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                appState.isShowingSplash = false
            }
        }
    }
}

struct LoginFlowView: View {
    @State private var destination: LoginDestination?
    
    enum LoginDestination: Identifiable, Hashable {
        case emailAuth(isSignIn: Bool)
        
        var id: String {
            switch self {
            case .emailAuth(let isSignIn): return "emailAuth-\(isSignIn)"
            }
        }
    }
    
    var body: some View {
        LoginView(navigateTo: { dest in
            destination = dest
        })
        .ignoresSafeArea(.all)
        .fullScreenCover(item: $destination) { dest in
            switch dest {
            case .emailAuth(let isSignIn):
                NavigationStack {
                    EmailAuthView(mode: isSignIn ? .signin : .signup)
                }
                .environmentObject(DependencyContainer.shared.authViewModel)
            }
        }
    }
}

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
