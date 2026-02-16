//
//  ConversationsView.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import SwiftUI

struct ConversationsView: View {
    // MARK: - Environment
    @EnvironmentObject private var chatViewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    @State private var searchText = ""
    @State private var showDeleteConfirmation = false
    @State private var conversationToDelete: Conversation?
    
    // MARK: - Computed
    private var pinnedConversations: [Conversation] {
        chatViewModel.conversations.filter { $0.isPinned }
    }
    
    private var recentConversations: [Conversation] {
        chatViewModel.conversations.filter { !$0.isPinned && !$0.isArchived }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            List {
                // Pinned Section
                if !pinnedConversations.isEmpty {
                    Section("Pinned") {
                        ForEach(pinnedConversations) { conversation in
                            ConversationRow(conversation: conversation)
                                .onTapGesture {
                                    selectConversation(conversation)
                                }
                                .swipeActions(edge: .trailing) {
                                    deleteButton(for: conversation)
                                }
                                .swipeActions(edge: .leading) {
                                    pinButton(for: conversation)
                                }
                                .contextMenu {
                                    contextMenuItems(for: conversation)
                                }
                        }
                    }
                }
                
                // Recent Section
                if !recentConversations.isEmpty {
                    Section("Recent") {
                        ForEach(recentConversations) { conversation in
                            ConversationRow(conversation: conversation)
                                .onTapGesture {
                                    selectConversation(conversation)
                                }
                                .swipeActions(edge: .trailing) {
                                    deleteButton(for: conversation)
                                }
                                .swipeActions(edge: .leading) {
                                    pinButton(for: conversation)
                                }
                                .contextMenu {
                                    contextMenuItems(for: conversation)
                                }
                        }
                    }
                }
                
                // Empty State
                if chatViewModel.conversations.isEmpty && !chatViewModel.isLoadingConversations {
                    ContentUnavailableView(
                        "No Conversations",
                        systemImage: "bubble.left.and.bubble.right",
                        description: Text("Start a new chat to begin")
                    )
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $searchText, prompt: "Search conversations")
            .navigationTitle("Conversations")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        chatViewModel.startNewChat()
                        dismiss()
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .refreshable {
                chatViewModel.loadConversations()
            }
            .onChange(of: searchText) { _, newValue in
                chatViewModel.searchConversations(newValue)
            }
            .confirmationDialog(
                "Delete Conversation?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let conversation = conversationToDelete {
                        chatViewModel.deleteConversation(conversation.id)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Helpers
    private func selectConversation(_ conversation: Conversation) {
        chatViewModel.loadConversation(conversation.id)
        dismiss()
    }
    
    private func deleteButton(for conversation: Conversation) -> some View {
        Button(role: .destructive) {
            conversationToDelete = conversation
            showDeleteConfirmation = true
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    private func pinButton(for conversation: Conversation) -> some View {
        Button {
            chatViewModel.togglePinConversation(conversation.id)
        } label: {
            Label(
                conversation.isPinned ? "Unpin" : "Pin",
                systemImage: conversation.isPinned ? "pin.slash" : "pin"
            )
        }
        .tint(.orange)
    }
    
    @ViewBuilder
    private func contextMenuItems(for conversation: Conversation) -> some View {
        Button {
            chatViewModel.togglePinConversation(conversation.id)
        } label: {
            Label(
                conversation.isPinned ? "Unpin" : "Pin",
                systemImage: conversation.isPinned ? "pin.slash" : "pin"
            )
        }
        
        Button {
            // Show rename dialog
        } label: {
            Label("Rename", systemImage: "pencil")
        }
        
        Divider()
        
        Button(role: .destructive) {
            conversationToDelete = conversation
            showDeleteConfirmation = true
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}

// MARK: - Conversation Row
struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(spacing: BCSpacing.sm) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.bcPrimary.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: conversation.isPinned ? "pin.fill" : "bubble.left.fill")
                    .foregroundColor(.bcPrimary)
                    .font(.system(size: 16))
            }
            
            VStack(alignment: .leading, spacing: BCSpacing.xxs) {
                Text(conversation.title)
                    .font(.bcBodyMedium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: BCSpacing.xxs) {
                    Text("\(conversation.messageCount) messages")
                        .font(.bcCaption)
                        .foregroundColor(.secondary)
                    
                    if conversation.isInProject {
                        Text("• In Project")
                            .font(.bcCaption)
                            .foregroundColor(.bcPrimary)
                    }
                }
            }
            
            Spacer()
            
            Text(conversation.formattedDate)
                .font(.bcCaption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, BCSpacing.xxs)
    }
}

#Preview {
    ConversationsView()
        .environmentObject(DependencyContainer.shared.chatViewModel)
}
