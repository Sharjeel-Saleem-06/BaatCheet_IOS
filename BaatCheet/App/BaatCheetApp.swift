//
//  BaatCheetApp.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import SwiftUI
import GoogleSignIn

@main
struct BaatCheetApp: App {
    // MARK: - Dependencies
    @StateObject private var appState = AppState()
    @StateObject private var authViewModel: AuthViewModel
    @StateObject private var chatViewModel: ChatViewModel
    
    // MARK: - Init
    init() {
        let container = DependencyContainer.shared
        
        _authViewModel = StateObject(wrappedValue: container.authViewModel)
        _chatViewModel = StateObject(wrappedValue: container.chatViewModel)
        
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
                    if GIDSignIn.sharedInstance.handle(url) {
                        return
                    }
                    handleDeepLink(url)
                }
        }
    }
    
    // MARK: - Private Methods
    private func configureAppearance() {
        // No global UIKit appearance overrides - using SwiftUI native styling
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
