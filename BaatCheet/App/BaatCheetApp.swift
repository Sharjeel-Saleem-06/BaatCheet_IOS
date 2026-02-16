//
//  BaatCheetApp.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import SwiftUI

@main
struct BaatCheetApp: App {
    // MARK: - Dependencies
    @StateObject private var appState = AppState()
    @StateObject private var authViewModel: AuthViewModel
    @StateObject private var chatViewModel: ChatViewModel
    
    // MARK: - Init
    init() {
        // Initialize dependencies
        let container = DependencyContainer.shared
        
        _authViewModel = StateObject(wrappedValue: container.authViewModel)
        _chatViewModel = StateObject(wrappedValue: container.chatViewModel)
        
        // Configure appearance
        configureAppearance()
    }
    
    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(authViewModel)
                .environmentObject(chatViewModel)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }
    
    // MARK: - Private Methods
    private func configureAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        
        // Configure tab bar
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
    private func handleDeepLink(_ url: URL) {
        DeepLinkHandler.shared.handle(url: url, appState: appState, chatViewModel: chatViewModel)
    }
}

// MARK: - App State
final class AppState: ObservableObject {
    @Published var isShowingSplash = true
    @Published var deepLinkConversationId: String?
    @Published var deepLinkShareId: String?
    @Published var selectedTab: Tab = .chat
    
    enum Tab: Int, CaseIterable {
        case chat = 0
        case projects = 1
        case settings = 2
    }
}
