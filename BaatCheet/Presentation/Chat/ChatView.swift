//
//  ChatView.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import SwiftUI

struct ChatView: View {
    // MARK: - Environment
    @EnvironmentObject private var chatViewModel: ChatViewModel
    @EnvironmentObject private var appState: AppState
    
    // MARK: - State
    @State private var showConversations = false
    @State private var showModeSelector = false
    @State private var showShareSheet = false
    @FocusState private var isInputFocused: Bool
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Messages List
            messagesView
            
            // Input Area
            inputArea
        }
        .navigationTitle(chatViewModel.currentConversationId != nil ? "Chat" : "New Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { showConversations = true }) {
                    Image(systemName: "list.bullet")
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: BCSpacing.sm) {
                    if chatViewModel.currentConversationId != nil {
                        Button(action: { chatViewModel.createShareLink() }) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                    
                    Button(action: { chatViewModel.startNewChat() }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showConversations) {
            ConversationsView()
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = chatViewModel.shareUrl {
                ShareSheet(items: [URL(string: url)!])
            }
        }
        .onChange(of: chatViewModel.shareUrl) { _, newValue in
            if newValue != nil {
                showShareSheet = true
            }
        }
        .alert("Error", isPresented: .constant(chatViewModel.error != nil)) {
            Button("OK") {
                chatViewModel.clearError()
            }
        } message: {
            Text(chatViewModel.error ?? "")
        }
    }
    
    // MARK: - Messages View
    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: BCSpacing.md) {
                    if chatViewModel.messages.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(chatViewModel.messages) { message in
                            MessageBubbleView(
                                message: message,
                                isSpeaking: chatViewModel.speakingMessageId == message.id,
                                onSpeak: { /* Handle speak */ },
                                onLike: { chatViewModel.submitFeedback(messageId: message.id, isLike: true) },
                                onDislike: { chatViewModel.submitFeedback(messageId: message.id, isLike: false) },
                                onRegenerate: { chatViewModel.regenerateResponse() }
                            )
                            .id(message.id)
                        }
                    }
                }
                .padding(.vertical, BCSpacing.md)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: chatViewModel.messages.count) { _, _ in
                if let lastMessage = chatViewModel.messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: BCSpacing.xl) {
            Spacer()
            
            Image("login_image")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 70)
                .opacity(0.8)
            
            Text("How can I help you today?")
                .font(.bcTitle2)
                .foregroundColor(.primary)
            
            // Suggestions
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: BCSpacing.sm) {
                ForEach(chatViewModel.suggestions.prefix(4), id: \.self) { suggestion in
                    SuggestionChip(text: suggestion) {
                        chatViewModel.useSuggestion(suggestion)
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
    // MARK: - Input Area
    private var inputArea: some View {
        VStack(spacing: 0) {
            // AI Mode Selector
            if !chatViewModel.aiModes.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: BCSpacing.xs) {
                        ForEach(chatViewModel.aiModes.prefix(6)) { mode in
                            AIModeChip(
                                mode: mode,
                                isSelected: chatViewModel.selectedMode == mode.id
                            ) {
                                chatViewModel.selectAIMode(mode)
                            }
                        }
                    }
                    .padding(.horizontal, BCSpacing.md)
                    .padding(.vertical, BCSpacing.xs)
                }
            }
            
            Divider()
            
            // Input Field
            HStack(alignment: .bottom, spacing: BCSpacing.sm) {
                // Attach Button
                Button(action: { /* Show attachment options */ }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.bcPrimary)
                }
                
                // Text Input
                TextField("Message", text: $chatViewModel.inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)
                    .focused($isInputFocused)
                    .padding(.horizontal, BCSpacing.sm)
                    .padding(.vertical, BCSpacing.xs)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(20)
                
                // Send Button
                Button(action: {
                    Task {
                        await chatViewModel.sendMessage()
                    }
                }) {
                    Image(systemName: chatViewModel.isSending ? "stop.circle.fill" : "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(chatViewModel.inputText.isEmpty ? .gray : .bcPrimary)
                }
                .disabled(chatViewModel.inputText.isEmpty && !chatViewModel.isSending)
            }
            .padding(.horizontal, BCSpacing.md)
            .padding(.vertical, BCSpacing.sm)
            .background(Color(UIColor.systemBackground))
        }
    }
}

// MARK: - Message Bubble View
struct MessageBubbleView: View {
    let message: ChatMessage
    let isSpeaking: Bool
    let onSpeak: () -> Void
    let onLike: () -> Void
    let onDislike: () -> Void
    let onRegenerate: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: BCSpacing.sm) {
            if !message.isUser {
                // AI Avatar
                Circle()
                    .fill(Color.bcPrimary)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text("AI")
                            .font(.bcCaptionMedium)
                            .foregroundColor(.white)
                    )
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: BCSpacing.xxs) {
                // Message Content
                if message.isStreaming {
                    StreamingIndicator()
                } else {
                    // Image Result
                    if let imageResult = message.imageResult, imageResult.success {
                        GeneratedImageView(imageResult: imageResult)
                    }
                    
                    // Text Content
                    if !message.content.isEmpty {
                        Text(message.content)
                            .font(.bcBody)
                            .foregroundColor(message.isUser ? .white : .primary)
                            .padding(BCSpacing.sm)
                            .background(message.isUser ? Color.bcPrimary : Color(UIColor.secondarySystemBackground))
                            .cornerRadius(BCCornerRadius.lg)
                    }
                }
                
                // Attachments
                if !message.attachments.isEmpty {
                    AttachmentsRow(attachments: message.attachments)
                }
                
                // Action Buttons (for AI messages)
                if !message.isUser && !message.isStreaming {
                    HStack(spacing: BCSpacing.md) {
                        Button(action: onSpeak) {
                            Image(systemName: isSpeaking ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        
                        Button(action: onLike) {
                            Image(systemName: "hand.thumbsup")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        
                        Button(action: onDislike) {
                            Image(systemName: "hand.thumbsdown")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        
                        Button(action: {
                            UIPasteboard.general.string = message.content
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        
                        Button(action: onRegenerate) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, BCSpacing.xxs)
                }
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.isUser ? .trailing : .leading)
            
            if message.isUser {
                Spacer()
            }
        }
        .padding(.horizontal, BCSpacing.md)
    }
}

// MARK: - Streaming Indicator
struct StreamingIndicator: View {
    @State private var animating = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)
                    .opacity(animating ? 1 : 0.3)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(index) * 0.2),
                        value: animating
                    )
            }
        }
        .padding(BCSpacing.sm)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(BCCornerRadius.lg)
        .onAppear {
            animating = true
        }
    }
}

// MARK: - Generated Image View
struct GeneratedImageView: View {
    let imageResult: ImageResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: BCSpacing.xs) {
            if let urlString = imageResult.imageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 200, height: 200)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 250)
                            .cornerRadius(BCCornerRadius.md)
                    case .failure:
                        Image(systemName: "photo")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                            .frame(width: 200, height: 200)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            
            if let enhancedPrompt = imageResult.enhancedPrompt {
                Text("Enhanced: \(enhancedPrompt)")
                    .font(.bcCaption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
    }
}

// MARK: - Attachments Row
struct AttachmentsRow: View {
    let attachments: [MessageAttachment]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: BCSpacing.xs) {
                ForEach(attachments) { attachment in
                    AttachmentThumbnail(attachment: attachment)
                }
            }
        }
    }
}

struct AttachmentThumbnail: View {
    let attachment: MessageAttachment
    
    var body: some View {
        VStack {
            if attachment.isImage, let urlString = attachment.thumbnailUrl ?? attachment.url,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 60, height: 60)
                .cornerRadius(BCCornerRadius.sm)
            } else {
                RoundedRectangle(cornerRadius: BCCornerRadius.sm)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: attachment.iconName)
                            .foregroundColor(.secondary)
                    )
            }
            
            Text(attachment.filename)
                .font(.bcCaption)
                .lineLimit(1)
                .frame(width: 60)
        }
    }
}

// MARK: - Suggestion Chip
struct SuggestionChip: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.bcLabel)
                .foregroundColor(.primary)
                .padding(.horizontal, BCSpacing.sm)
                .padding(.vertical, BCSpacing.xs)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(BCCornerRadius.md)
        }
    }
}

// MARK: - AI Mode Chip
struct AIModeChip: View {
    let mode: AIMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: BCSpacing.xxs) {
                Text(mode.icon)
                    .font(.system(size: 14))
                Text(mode.displayName)
                    .font(.bcLabelSmall)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, BCSpacing.sm)
            .padding(.vertical, BCSpacing.xs)
            .background(isSelected ? Color.bcPrimary : Color(UIColor.secondarySystemBackground))
            .cornerRadius(BCCornerRadius.md)
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        ChatView()
            .environmentObject(DependencyContainer.shared.chatViewModel)
            .environmentObject(AppState())
    }
}
