//
//  DeepLinkHandler.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import Foundation

@MainActor
final class DeepLinkHandler {
    // MARK: - Singleton
    static let shared = DeepLinkHandler()
    
    private init() {}
    
    // MARK: - Deep Link Types
    enum DeepLinkType {
        case conversation(id: String)
        case sharedChat(shareId: String)
        case project(id: String)
        case unknown
    }
    
    // MARK: - Handle Deep Link
    func handle(url: URL, appState: AppState, chatViewModel: ChatViewModel) {
        let deepLinkType = parse(url: url)
        
        switch deepLinkType {
        case .conversation(let id):
            appState.deepLinkConversationId = id
            chatViewModel.loadConversation(id)
            appState.selectedTab = .chat
            
        case .sharedChat(let shareId):
            appState.deepLinkShareId = shareId
            chatViewModel.loadSharedConversation(shareId: shareId)
            appState.selectedTab = .chat
            
        case .project(let id):
            appState.selectedTab = .projects
            // Navigate to project detail
            
        case .unknown:
            break
        }
    }
    
    // MARK: - Parse URL
    private func parse(url: URL) -> DeepLinkType {
        // Handle custom scheme: baatcheet://
        if url.scheme == "baatcheet" {
            return parseCustomScheme(url: url)
        }
        
        // Handle universal links: https://baatcheet-web.netlify.app/
        if url.host == "baatcheet-web.netlify.app" {
            return parseUniversalLink(url: url)
        }
        
        return .unknown
    }
    
    private func parseCustomScheme(url: URL) -> DeepLinkType {
        guard let host = url.host else { return .unknown }
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        switch host {
        case "chat":
            if let conversationId = pathComponents.first {
                return .conversation(id: conversationId)
            }
            
        case "share":
            if let shareId = pathComponents.first {
                return .sharedChat(shareId: shareId)
            }
            
        case "project":
            if let projectId = pathComponents.first {
                return .project(id: projectId)
            }
            
        default:
            break
        }
        
        return .unknown
    }
    
    private func parseUniversalLink(url: URL) -> DeepLinkType {
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        // Handle /share/{shareId}
        if let shareIndex = pathComponents.firstIndex(of: "share"),
           shareIndex + 1 < pathComponents.count {
            let shareId = pathComponents[shareIndex + 1]
            return .sharedChat(shareId: shareId)
        }
        
        // Handle /app/chat/{conversationId}
        if let chatIndex = pathComponents.firstIndex(of: "chat"),
           chatIndex + 1 < pathComponents.count {
            let conversationId = pathComponents[chatIndex + 1]
            return .conversation(id: conversationId)
        }
        
        // Handle /project/{projectId}
        if let projectIndex = pathComponents.firstIndex(of: "project"),
           projectIndex + 1 < pathComponents.count {
            let projectId = pathComponents[projectIndex + 1]
            return .project(id: projectId)
        }
        
        return .unknown
    }
}
