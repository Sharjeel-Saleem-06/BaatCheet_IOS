//
//  ChatView.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ChatView: View {
    @EnvironmentObject private var chatViewModel: ChatViewModel
    @EnvironmentObject private var appState: AppState
    
    @Environment(\.showDrawer) private var showDrawer
    @State private var showConversations = false
    @State private var showPlusMenu = false
    @State private var showVoiceChat = false
    @State private var showShareSheet = false
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var showFilePicker = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            messagesView
            inputArea
        }
        .navigationTitle(chatViewModel.currentConversationId != nil ? "Chat" : "New Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { showDrawer.wrappedValue = true }) {
                    Image(systemName: "line.3.horizontal")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    if chatViewModel.currentConversationId != nil {
                        Button(action: { chatViewModel.createShareLink() }) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                    Button(action: { chatViewModel.startNewChat() }) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
        }
        .sheet(isPresented: $showConversations) {
            ConversationsView()
        }
        .sheet(isPresented: $showPlusMenu) {
            PlusMenuSheet(
                onCameraClick: {
                    showPlusMenu = false
                    showCamera = true
                },
                onPhotosClick: {
                    showPlusMenu = false
                    showImagePicker = true
                },
                onFilesClick: {
                    showPlusMenu = false
                    showFilePicker = true
                },
                onModeSelect: { mode in
                    chatViewModel.selectedMode = mode
                    showPlusMenu = false
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showVoiceChat) {
            VoiceChatView()
        }
        .photosPicker(isPresented: $showImagePicker, selection: $selectedPhotoItems, maxSelectionCount: 3, matching: .images)
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.pdf, .plainText, .json, .xml, .commaSeparatedText], allowsMultipleSelection: true) { result in
            handleFileImport(result)
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = chatViewModel.shareUrl {
                ShareSheet(items: [URL(string: url)!])
            }
        }
        .onChange(of: chatViewModel.shareUrl) { _, newValue in
            if newValue != nil { showShareSheet = true }
        }
        .onChange(of: selectedPhotoItems) { _, items in
            handlePhotoSelection(items)
        }
        .alert("Error", isPresented: .constant(chatViewModel.error != nil)) {
            Button("OK") { chatViewModel.clearError() }
        } message: {
            Text(chatViewModel.error ?? "")
        }
    }
    
    // MARK: - Messages
    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if chatViewModel.messages.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(chatViewModel.messages) { message in
                            MessageBubbleView(
                                message: message,
                                isSpeaking: chatViewModel.speakingMessageId == message.id,
                                onSpeak: {},
                                onLike: { chatViewModel.submitFeedback(messageId: message.id, isLike: true) },
                                onDislike: { chatViewModel.submitFeedback(messageId: message.id, isLike: false) },
                                onRegenerate: { chatViewModel.regenerateResponse() }
                            )
                            .id(message.id)
                        }
                    }
                }
                .padding(.vertical, 12)
            }
            .scrollDismissesKeyboard(.interactively)
            .contentShape(Rectangle())
            .onTapGesture { isInputFocused = false }
            .onChange(of: chatViewModel.messages.count) { _, _ in
                if let lastMessage = chatViewModel.messages.last {
                    withAnimation { proxy.scrollTo(lastMessage.id, anchor: .bottom) }
                }
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 60)
            
            Image("SplashLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .opacity(0.8)
            
            Text("How can I help you today?")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
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
            // Selected mode chip
            if let mode = chatViewModel.selectedMode, !mode.isEmpty {
                HStack {
                    Text(modeName(for: mode))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.bcPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.bcPrimary.opacity(0.1))
                        .cornerRadius(16)
                    
                    Button(action: { chatViewModel.selectedMode = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            
            // Uploaded files preview
            if !chatViewModel.uploadedFiles.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(chatViewModel.uploadedFiles) { file in
                            UploadedFileChip(file: file) {
                                chatViewModel.uploadedFiles.removeAll { $0.id == file.id }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            
            Divider()
            
            HStack(alignment: .center, spacing: 8) {
                Button(action: { showPlusMenu = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.bcPrimary)
                }
                .frame(width: 36, height: 36)
                
                TextField("Ask BaatCheet", text: $chatViewModel.inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)
                    .focused($isInputFocused)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(20)
                
                if chatViewModel.inputText.trimmed.isEmpty {
                    Button(action: { showVoiceChat = true }) {
                        Image(systemName: "waveform.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.bcPrimary)
                    }
                    .frame(width: 36, height: 36)
                } else {
                    Button(action: {
                        Task { await chatViewModel.sendMessage() }
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.green)
                    }
                    .frame(width: 36, height: 36)
                    .disabled(chatViewModel.isSending)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(UIColor.systemBackground))
        }
    }
    
    private func modeName(for id: String) -> String {
        switch id {
        case "image-generation": return "Create Image"
        case "research": return "Deep Research"
        case "web-search": return "Web Search"
        case "tutor": return "Study & Learn"
        case "code": return "Code"
        default: return id.capitalized
        }
    }
    
    private func handlePhotoSelection(_ items: [PhotosPickerItem]) {
        for item in items {
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    let filename = "photo_\(UUID().uuidString.prefix(8)).jpg"
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
                    try? data.write(to: tempURL)
                    let file = UploadedFileState(
                        id: UUID().uuidString,
                        url: tempURL,
                        filename: filename,
                        mimeType: "image/jpeg",
                        status: .ready
                    )
                    await MainActor.run {
                        chatViewModel.uploadedFiles.append(file)
                    }
                }
            }
        }
        selectedPhotoItems = []
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                let file = UploadedFileState(
                    id: UUID().uuidString,
                    url: url,
                    filename: url.lastPathComponent,
                    mimeType: UTType(filenameExtension: url.pathExtension)?.preferredMIMEType ?? "application/octet-stream",
                    status: .ready
                )
                chatViewModel.uploadedFiles.append(file)
            }
        case .failure:
            break
        }
    }
}

// MARK: - Plus Menu Bottom Sheet (matches Android PlusMenuBottomSheet)
struct PlusMenuSheet: View {
    let onCameraClick: () -> Void
    let onPhotosClick: () -> Void
    let onFilesClick: () -> Void
    let onModeSelect: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Media row
            HStack(spacing: 24) {
                mediaButton(icon: "camera.fill", label: "Camera", action: onCameraClick)
                mediaButton(icon: "photo.fill", label: "Photos", action: onPhotosClick)
                mediaButton(icon: "doc.fill", label: "Files", action: onFilesClick)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            Divider()
                .padding(.horizontal, 16)
            
            // Mode options
            VStack(spacing: 0) {
                modeRow(icon: "sparkles", label: "Create image", mode: "image-generation")
                modeRow(icon: "brain.head.profile", label: "Thinking", mode: "research")
                modeRow(icon: "magnifyingglass", label: "Deep research", mode: "research")
                modeRow(icon: "globe", label: "Web search", mode: "web-search")
                modeRow(icon: "book.fill", label: "Study and learn", mode: "tutor")
                modeRow(icon: "doc.text.fill", label: "Add files", mode: "files")
                modeRow(icon: "chevron.left.forwardslash.chevron.right", label: "Code", mode: "code")
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .background(Color(UIColor.systemBackground))
    }
    
    private func mediaButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(.primary)
                    .frame(width: 52, height: 52)
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(Circle())
                
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func modeRow(icon: String, label: String, mode: String) -> some View {
        Button(action: { onModeSelect(mode) }) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.primary)
                    .frame(width: 28)
                
                Text(label)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
    }
}

// MARK: - Uploaded File Chip
struct UploadedFileChip: View {
    let file: UploadedFileState
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: file.mimeType.starts(with: "image") ? "photo" : "doc.fill")
                .font(.system(size: 12))
                .foregroundColor(.bcPrimary)
            
            Text(file.filename)
                .font(.system(size: 12))
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Message Bubble View (matches Android: no AI circle, app icon for assistant)
struct MessageBubbleView: View {
    let message: ChatMessage
    let isSpeaking: Bool
    let onSpeak: () -> Void
    let onLike: () -> Void
    let onDislike: () -> Void
    let onRegenerate: () -> Void
    
    var body: some View {
        if message.isUser {
            // User message: right aligned, blue background
            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    if !message.attachments.isEmpty {
                        AttachmentsRow(attachments: message.attachments)
                    }
                    Text(message.content)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.bcPrimary)
                        .cornerRadius(18)
                }
                .frame(maxWidth: UIScreen.main.bounds.width * 0.8)
            }
            .padding(.horizontal, 8)
        } else {
            // AI message: left aligned, full width, light background
            HStack(alignment: .top, spacing: 8) {
                Image("SplashLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 6) {
                    if message.isStreaming {
                        StreamingIndicator()
                    } else {
                        if let imageResult = message.imageResult, imageResult.success {
                            GeneratedImageView(imageResult: imageResult)
                        }
                        
                        if !message.content.isEmpty {
                            Text(message.content)
                                .font(.system(size: 15))
                                .foregroundColor(.primary)
                                .textSelection(.enabled)
                        }
                    }
                    
                    if !message.attachments.isEmpty {
                        AttachmentsRow(attachments: message.attachments)
                    }
                    
                    if !message.isStreaming && !message.content.isEmpty {
                        HStack(spacing: 18) {
                            actionButton("speaker.wave.2.fill", action: onSpeak)
                            actionButton("hand.thumbsup", action: onLike)
                            actionButton("hand.thumbsdown", action: onDislike)
                            actionButton("doc.on.doc", action: { UIPasteboard.general.string = message.content })
                            actionButton("arrow.clockwise", action: onRegenerate)
                        }
                        .padding(.top, 2)
                    }
                }
            }
            .padding(.horizontal, 8)
        }
    }
    
    private func actionButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Streaming Indicator
struct StreamingIndicator: View {
    @State private var animating = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)
                    .opacity(animating ? 1 : 0.3)
                    .animation(
                        .easeInOut(duration: 0.6).repeatForever().delay(Double(index) * 0.2),
                        value: animating
                    )
            }
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .onAppear { animating = true }
    }
}

// MARK: - Generated Image View
struct GeneratedImageView: View {
    let imageResult: ImageResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let urlString = imageResult.imageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView().frame(width: 200, height: 200)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 250)
                            .cornerRadius(12)
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
                    .font(.system(size: 12))
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
            HStack(spacing: 8) {
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
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 60, height: 60)
                .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: attachment.iconName)
                            .foregroundColor(.secondary)
                    )
            }
            
            Text(attachment.filename)
                .font(.system(size: 10))
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
                .font(.system(size: 13))
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
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
            HStack(spacing: 4) {
                Text(mode.icon)
                    .font(.system(size: 14))
                Text(mode.displayName)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.bcPrimary : Color(UIColor.secondarySystemBackground))
            .cornerRadius(16)
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
