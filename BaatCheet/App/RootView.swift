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
        Group {
            if appState.isShowingSplash {
                SplashView()
            } else if authViewModel.isAuthenticated {
                MainDrawerView()
            } else {
                LoginFlowView()
            }
        }
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
        .fullScreenCover(item: $destination) { dest in
            switch dest {
            case .emailAuth(let isSignIn):
                NavigationStack {
                    EmailAuthView(mode: isSignIn ? .signin : .signup)
                        .navigationBarBackButtonHidden(true)
                }
                .environmentObject(DependencyContainer.shared.authViewModel)
            }
        }
    }
}

// MARK: - Main View with Side Drawer (matches Android ModalNavigationDrawer)
struct MainDrawerView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var chatViewModel: ChatViewModel
    @State private var showDrawer = false
    
    var body: some View {
        ZStack(alignment: .leading) {
            NavigationStack {
                currentScreen
            }
            
            if showDrawer {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation(.easeOut(duration: 0.25)) { showDrawer = false } }
                
                DrawerContent(
                    showDrawer: $showDrawer,
                    selectedTab: $appState.selectedTab
                )
                .frame(width: 280)
                .transition(.move(edge: .leading))
            }
        }
        .animation(.easeOut(duration: 0.25), value: showDrawer)
        .environment(\.showDrawer, $showDrawer)
    }
    
    @ViewBuilder
    private var currentScreen: some View {
        switch appState.selectedTab {
        case .chat:
            ChatView()
        case .projects:
            ProjectsView()
        case .settings:
            SettingsView()
        }
    }
}

// MARK: - Drawer Content (matches Android nav drawer items)
struct DrawerContent: View {
    @Binding var showDrawer: Bool
    @Binding var selectedTab: AppState.Tab
    @EnvironmentObject private var chatViewModel: ChatViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Image("SplashLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Text("BaatCheet")
                    .font(.system(size: 20, weight: .bold))
                
                if let name = chatViewModel.userProfile?.displayName {
                    Text(name)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(UIColor.secondarySystemBackground))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    drawerItem(icon: "square.and.pencil", label: "New Chat") {
                        chatViewModel.startNewChat()
                        selectedTab = .chat
                        showDrawer = false
                    }
                    
                    drawerItem(icon: "bubble.left.and.bubble.right", label: "Conversations") {
                        selectedTab = .chat
                        showDrawer = false
                    }
                    
                    drawerItem(icon: "folder", label: "Projects", selected: selectedTab == .projects) {
                        selectedTab = .projects
                        showDrawer = false
                    }
                    
                    Divider().padding(.vertical, 8).padding(.horizontal, 16)
                    
                    drawerItem(icon: "gearshape", label: "Settings", selected: selectedTab == .settings) {
                        selectedTab = .settings
                        showDrawer = false
                    }
                    
                    Divider().padding(.vertical, 8).padding(.horizontal, 16)
                    
                    drawerItem(icon: "rectangle.portrait.and.arrow.right", label: "Sign Out", tint: .red) {
                        showDrawer = false
                        Task { await authViewModel.logout() }
                    }
                }
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .background(Color(UIColor.systemBackground))
    }
    
    private func drawerItem(
        icon: String,
        label: String,
        selected: Bool = false,
        tint: Color = .primary,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(selected ? .bcPrimary : tint)
                    .frame(width: 24)
                
                Text(label)
                    .font(.system(size: 16, weight: selected ? .semibold : .regular))
                    .foregroundColor(selected ? .bcPrimary : tint)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(selected ? Color.bcPrimary.opacity(0.08) : Color.clear)
            .contentShape(Rectangle())
        }
    }
}

// MARK: - Environment key for drawer
private struct ShowDrawerKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(false)
}

extension EnvironmentValues {
    var showDrawer: Binding<Bool> {
        get { self[ShowDrawerKey.self] }
        set { self[ShowDrawerKey.self] = newValue }
    }
}

#Preview {
    RootView()
        .environmentObject(AppState())
        .environmentObject(DependencyContainer.shared.authViewModel)
        .environmentObject(DependencyContainer.shared.chatViewModel)
}
