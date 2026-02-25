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

// MARK: - Main View
struct MainDrawerView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var chatViewModel: ChatViewModel
    @State private var showDrawer = false
    @State private var showAllChats = false
    @State private var showCollaborations = false
    
    var body: some View {
        ZStack(alignment: .leading) {
            if appState.selectedProjectId != nil {
                NavigationStack {
                    ProjectDetailInlineView(projectId: appState.selectedProjectId!)
                }
            } else {
                TabView(selection: $appState.selectedTab) {
                    NavigationStack {
                        ChatView()
                    }
                    .tabItem {
                        Label("Chat", systemImage: "bubble.left.and.bubble.right")
                    }
                    .tag(AppState.Tab.chat)
                    
                    NavigationStack {
                        ProjectsView()
                    }
                    .tabItem {
                        Label("Projects", systemImage: "folder")
                    }
                    .tag(AppState.Tab.projects)
                    
                    NavigationStack {
                        SettingsView()
                    }
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                    }
                    .tag(AppState.Tab.settings)
                }
                .tint(.bcPrimary)
            }
            
            if showDrawer {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.2)) { showDrawer = false }
                    }
                
                ChatDrawerContent(showDrawer: $showDrawer, showAllChats: $showAllChats, showCollaborations: $showCollaborations)
                    .frame(width: 300)
                    .background(Color(UIColor.systemBackground))
                    .transition(.move(edge: .leading))
            }
        }
        .animation(.easeOut(duration: 0.2), value: showDrawer)
        .environment(\.showDrawer, $showDrawer)
        .sheet(isPresented: $showAllChats) {
            ConversationsView()
                .environmentObject(chatViewModel)
        }
        .sheet(isPresented: $showCollaborations) {
            CollaborationsSheet()
        }
    }
}

// MARK: - Project Detail Inline View (matches Android ProjectChatScreen)
struct ProjectDetailInlineView: View {
    let projectId: String
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var chatViewModel: ChatViewModel
    @Environment(\.showDrawer) private var showDrawer
    @StateObject private var viewModel = DependencyContainer.shared.projectsViewModel
    @State private var selectedTab = 0
    @State private var showProjectSettings = false
    @State private var newChatText = ""
    
    private var hasCollaborators: Bool {
        !viewModel.collaborators.isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let project = viewModel.selectedProject {
                // Tab row (only if collaborators exist, like Android)
                if hasCollaborators {
                    HStack(spacing: 0) {
                        tabPill(icon: "cpu", label: "AI Chats", index: 0)
                        tabPill(icon: "person.2.fill", label: "Team Chat", index: 1)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(UIColor.secondarySystemBackground))
                }
                
                TabView(selection: $selectedTab) {
                    aiChatsTab(project: project)
                        .tag(0)
                    
                    if hasCollaborators {
                        teamChatTab(project: project)
                            .tag(1)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            } else if viewModel.isLoadingProject {
                Spacer()
                ProgressView("Loading project...")
                Spacer()
            } else {
                Spacer()
                ContentUnavailableView("Project not found", systemImage: "folder",
                    description: Text("This project could not be loaded"))
                Spacer()
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack(alignment: .center, spacing: 8) {
                    Button(action: {
                        appState.selectedProjectId = nil
                        appState.selectedTab = .chat
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 16, weight: .medium))
                            .frame(width: 32, height: 32)
                            .background(Color(UIColor.secondarySystemBackground))
                            .clipShape(Circle())
                    }
                    
                    if let project = viewModel.selectedProject {
                        HStack(spacing: 6) {
                            if let emoji = project.emoji, !emoji.isEmpty {
                                Text(emoji).font(.system(size: 20))
                            }
                            VStack(alignment: .leading, spacing: 0) {
                                Text(project.displayName)
                                    .font(.system(size: 16, weight: .semibold))
                                Text("\(viewModel.projectConversations.count) chats")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showProjectSettings = true }) {
                    Image(systemName: "gearshape")
                }
            }
        }
        .onAppear {
            viewModel.loadProject(projectId)
        }
        .onChange(of: projectId) { _, newId in
            viewModel.loadProject(newId)
        }
        .sheet(isPresented: $showProjectSettings) {
            if let project = viewModel.selectedProject {
                ProjectSettingsSheet(project: project, viewModel: viewModel)
            }
        }
    }
    
    // MARK: - AI Chats Tab
    private func aiChatsTab(project: Project) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Instructions Card (matches Android ProjectInstructionsCard)
                    instructionsCard(project: project)
                    
                    // "Chats in this project" header + New Chat
                    HStack {
                        Text("Chats in this project")
                            .font(.system(size: 15, weight: .semibold))
                        Spacer()
                        Button(action: {
                            // Start new project chat
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.system(size: 12))
                                Text("New chat")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(.bcPrimary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                    // Conversations list
                    if viewModel.projectConversations.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("No chats yet")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ForEach(viewModel.projectConversations) { conversation in
                            Button(action: {
                                chatViewModel.loadConversation(conversation.id)
                                appState.selectedProjectId = nil
                                appState.selectedTab = .chat
                            }) {
                                projectConversationRow(conversation)
                            }
                        }
                    }
                }
            }
            
            // Bottom input bar
            projectChatInputBar(project: project)
        }
    }
    
    private func instructionsCard(project: Project) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.bcPrimary)
                Text("Instructions")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Button("Edit") { showProjectSettings = true }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.bcPrimary)
            }
            
            Text("Set context and customize how BaatCheet responds in this project.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            
            // AI-learned context
            if let context = project.context, !context.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                            .foregroundColor(.bcPrimary)
                        Text("AI-learned context")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.bcPrimary)
                    }
                    
                    Text(context)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(4)
                }
            }
            
            // Topics
            if !project.keyTopics.isEmpty {
                tagRow(label: "Topics:", tags: project.keyTopics, color: .orange)
            }
            
            // Tech
            if !project.techStack.isEmpty {
                tagRow(label: "Tech:", tags: project.techStack, color: .green)
            }
            
            // Goals
            if !project.goals.isEmpty {
                tagRow(label: "Goals:", tags: project.goals, color: .purple)
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
    
    private func tagRow(label: String, tags: [String], color: Color) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(width: 45, alignment: .leading)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(color.opacity(0.12))
                            .foregroundColor(color)
                            .cornerRadius(10)
                    }
                }
            }
        }
    }
    
    private func projectConversationRow(_ conversation: Conversation) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "bubble.left")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(conversation.title)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text("\(conversation.messageCount) messages")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "ellipsis")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
    
    private func projectChatInputBar(project: Project) -> some View {
        HStack(spacing: 8) {
            TextField("New chat in \(project.displayName)", text: $newChatText)
                .font(.system(size: 15))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(24)
            
            Button(action: {
                guard !newChatText.trimmed.isEmpty else { return }
                // Send as project chat
                newChatText = ""
            }) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 18))
                    .foregroundColor(newChatText.isEmpty ? .secondary : .bcPrimary)
            }
            .disabled(newChatText.trimmed.isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground))
        .overlay(Divider(), alignment: .top)
    }
    
    // MARK: - Team Chat Tab
    private func teamChatTab(project: Project) -> some View {
        ProjectTeamChatView(viewModel: viewModel, project: project)
    }
    
    private func tabPill(icon: String, label: String, index: Int) -> some View {
        Button(action: { withAnimation(.easeInOut(duration: 0.2)) { selectedTab = index } }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(label)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(selectedTab == index ? .primary : .secondary)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(selectedTab == index ? Color(UIColor.systemBackground) : Color.clear)
            )
        }
    }
}

// MARK: - Project Team Chat View (matches Android TeamChatContent)
struct ProjectTeamChatView: View {
    @ObservedObject var viewModel: ProjectsViewModel
    let project: Project
    @State private var showTeamSettings = false
    @State private var selectedMessage: TeamChatMessage?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.secondary)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Team Chat")
                        .font(.system(size: 15, weight: .semibold))
                    Text("\(viewModel.teamMessages.count) messages")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
                if project.isOwner {
                    Button(action: { showTeamSettings = true }) {
                        Image(systemName: "gearshape")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(UIColor.secondarySystemBackground))
            
            // Messages
            if viewModel.isLoadingTeamChat {
                Spacer()
                ProgressView()
                Spacer()
            } else if viewModel.teamMessages.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("No messages yet")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                    Text("Start the conversation with your team")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.teamMessages) { message in
                            teamMessageBubble(message)
                                .onLongPressGesture {
                                    selectedMessage = message
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            
            // Input bar
            teamChatInputBar
        }
        .onAppear {
            viewModel.loadTeamChat()
        }
        .sheet(isPresented: $showTeamSettings) {
            TeamChatSettingsSheet(project: project, viewModel: viewModel)
        }
        .sheet(item: $selectedMessage) { message in
            TeamMessageActionsSheet(message: message, viewModel: viewModel)
                .presentationDetents([.height(260)])
        }
    }
    
    private func teamMessageBubble(_ message: TeamChatMessage) -> some View {
        HStack(alignment: .top, spacing: 8) {
            // Avatar
            Circle()
                .fill(avatarColor(for: message.user?.displayName ?? "U"))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(message.user?.initials ?? "U")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(message.user?.displayName ?? "Unknown")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(nameColor(for: message.user?.displayName ?? ""))
                    
                    Spacer()
                    
                    Text(formatDate(message.createdAt))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Text(message.content)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
    
    private var teamChatInputBar: some View {
        HStack(spacing: 8) {
            TextField("Message your team...", text: $viewModel.teamChatInput)
                .font(.system(size: 15))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(24)
            
            Button(action: { viewModel.sendTeamMessage() }) {
                if viewModel.isSendingTeamMessage {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18))
                        .foregroundColor(viewModel.teamChatInput.trimmed.isEmpty ? .secondary : .bcPrimary)
                }
            }
            .disabled(viewModel.teamChatInput.trimmed.isEmpty || viewModel.isSendingTeamMessage)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground))
        .overlay(Divider(), alignment: .top)
    }
    
    private func avatarColor(for name: String) -> Color {
        let colors: [Color] = [.orange, .blue, .green, .purple, .red, .teal, .indigo]
        let hash = abs(name.hashValue) % colors.count
        return colors[hash]
    }
    
    private func nameColor(for name: String) -> Color {
        avatarColor(for: name)
    }
    
    private func formatDate(_ dateStr: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: dateStr) ?? ISO8601DateFormatter().date(from: dateStr) else {
            return ""
        }
        let display = DateFormatter()
        display.dateFormat = "MMM d"
        return display.string(from: date)
    }
}

// MARK: - Team Message Actions Sheet
struct TeamMessageActionsSheet: View {
    let message: TeamChatMessage
    @ObservedObject var viewModel: ProjectsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Message preview
            VStack(alignment: .leading, spacing: 4) {
                Text(message.user?.displayName ?? "Unknown")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.bcPrimary)
                Text(message.content)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            VStack(spacing: 0) {
                actionButton(icon: "doc.on.doc", label: "Copy text") {
                    UIPasteboard.general.string = message.content
                    dismiss()
                }
                
                actionButton(icon: "arrowshape.turn.up.left", label: "Reply") {
                    dismiss()
                }
                
                actionButton(icon: "trash", label: "Delete for me", color: .secondary) {
                    viewModel.deleteTeamMessage(message.id)
                    dismiss()
                }
                
                actionButton(icon: "trash.fill", label: "Delete for everyone", color: .red) {
                    viewModel.deleteTeamMessage(message.id)
                    dismiss()
                }
            }
            .padding(.top, 12)
            
            Spacer()
        }
    }
    
    private func actionButton(icon: String, label: String, color: Color = .primary, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                    .frame(width: 24)
                Text(label)
                    .font(.system(size: 15))
                    .foregroundColor(color)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
    }
}

// MARK: - Team Chat Settings Sheet
struct TeamChatSettingsSheet: View {
    let project: Project
    @ObservedObject var viewModel: ProjectsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var allowImages = true
    @State private var allowEmojis = true
    @State private var allowEditing = false
    @State private var allowDeletion = false
    @State private var sendPermission = "everyone"
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: "gearshape.2")
                            .foregroundColor(.bcPrimary)
                        Text("Group Settings")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                
                Section("MESSAGE PERMISSIONS") {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Send messages")
                                .font(.system(size: 15))
                            Text("Control who can send messages in this chat")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Menu(sendPermission.capitalized) {
                            Button("Everyone") { sendPermission = "everyone" }
                            Button("Admin & Mods") { sendPermission = "admin_mods" }
                            Button("Admin Only") { sendPermission = "admin_only" }
                        }
                        .foregroundColor(.bcPrimary)
                    }
                }
                
                Section("CONTENT CONTROLS") {
                    Toggle(isOn: $allowImages) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Allow images")
                            Text("Members can share images")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    .tint(.bcPrimary)
                    
                    Toggle(isOn: $allowEmojis) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Allow emojis")
                            Text("Members can use emoji reactions")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    .tint(.bcPrimary)
                }
                
                Section("EDIT & DELETE CONTROLS") {
                    Toggle(isOn: $allowEditing) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Allow message editing")
                            Text("Members can edit their messages")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    .tint(.bcPrimary)
                    
                    Toggle(isOn: $allowDeletion) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Allow message deletion")
                            Text("Members can delete their messages")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    .tint(.bcPrimary)
                }
                
                Section {
                    Text("Note: Admin can always send, edit, and delete any message regardless of these settings.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            .navigationTitle("Team Chat Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Project Settings Sheet (matches Android ProjectSettingsDialog)
struct ProjectSettingsSheet: View {
    let project: Project
    @ObservedObject var viewModel: ProjectsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var projectName: String = ""
    @State private var projectEmoji: String = ""
    @State private var instructions: String = ""
    @State private var showDeleteConfirmation = false
    @State private var isSaving = false
    
    private let emojis = ["📁", "📂", "🗂️", "💼", "📊", "📈", "🎯", "💡", "🚀", "⭐", "🔥", "💻", "📱", "🌐", "🎨", "📝", "✏️", "🔧", "⚡", "🎮"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Project name & emoji
                    HStack(spacing: 12) {
                        Button(action: {}) {
                            Text(projectEmoji)
                                .font(.system(size: 32))
                                .frame(width: 56, height: 56)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(12)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Project name")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            TextField("Project name", text: $projectName)
                                .font(.system(size: 16, weight: .medium))
                        }
                    }
                    
                    Text("\(viewModel.projectConversations.count) chats")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    // Emoji picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(emojis, id: \.self) { emoji in
                                Button(action: { projectEmoji = emoji }) {
                                    Text(emoji)
                                        .font(.system(size: 24))
                                        .padding(6)
                                        .background(
                                            projectEmoji == emoji
                                                ? Color.bcPrimary.opacity(0.2)
                                                : Color.clear
                                        )
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Instructions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Instructions")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Set context and customize how BaatCheet responds in this project.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $instructions)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                    
                    Divider()
                    
                    // Access section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Access")
                            .font(.system(size: 16, weight: .semibold))
                        
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(.bcPrimary)
                            Text("You are the owner")
                                .font(.system(size: 14))
                            Spacer()
                            Text("Owner")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        Button(action: { viewModel.showInviteSheet = true }) {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                Text("Invite Collaborator")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.bcPrimary)
                            .cornerRadius(10)
                        }
                        
                        if !viewModel.collaborators.isEmpty {
                            HStack {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(.secondary)
                                Text("Collaborators")
                                    .font(.system(size: 14))
                                Spacer()
                                Text("\(viewModel.collaborators.count) members")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    Divider()
                    
                    // Memory section
                    if let context = project.context, !context.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Memory")
                                .font(.system(size: 16, weight: .semibold))
                            
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 4) {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(.bcPrimary)
                                    Text("BaatCheet learns from conversations in this project to provide better context-aware responses.")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                                
                                if !project.keyTopics.isEmpty {
                                    Text("Topics: \(project.keyTopics.joined(separator: ", "))")
                                        .font(.system(size: 12))
                                        .foregroundColor(.bcPrimary)
                                        .italic()
                                }
                                
                                if !project.techStack.isEmpty {
                                    Text("Tech: \(project.techStack.joined(separator: ", "))")
                                        .font(.system(size: 12))
                                        .foregroundColor(.bcPrimary)
                                        .italic()
                                }
                            }
                            .padding(12)
                            .background(Color.bcPrimary.opacity(0.05))
                            .cornerRadius(10)
                        }
                    }
                    
                    // Save button
                    Button(action: {
                        saveProject()
                    }) {
                        if isSaving {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        } else {
                            Text("Save changes")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.bcPrimary)
                                .cornerRadius(10)
                        }
                    }
                    .disabled(isSaving)
                    
                    // Delete project
                    if project.canDelete {
                        Button(action: { showDeleteConfirmation = true }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete project")
                            }
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Project settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
        .onAppear {
            projectName = project.name
            projectEmoji = project.emoji ?? "📁"
            instructions = project.instructions ?? ""
        }
        .alert("Delete project?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                viewModel.deleteProject(project.id)
                dismiss()
            }
        } message: {
            Text("This will permanently delete the project and all its data.")
        }
        .sheet(isPresented: $viewModel.showInviteSheet) {
            InviteCollaboratorSheet(viewModel: viewModel)
        }
    }
    
    private func saveProject() {
        isSaving = true
        Task {
            do {
                let updated = try await viewModel.projectRepository.updateProject(
                    project.id,
                    name: projectName.trimmed.isEmpty ? nil : projectName.trimmed,
                    description: nil,
                    color: nil,
                    emoji: projectEmoji,
                    instructions: instructions.trimmed.isEmpty ? nil : instructions.trimmed,
                    customInstructions: nil
                )
                viewModel.selectedProject = updated
                if let idx = viewModel.projects.firstIndex(where: { $0.id == project.id }) {
                    viewModel.projects[idx] = updated
                }
                isSaving = false
                dismiss()
            } catch {
                viewModel.error = error.localizedDescription
                isSaving = false
            }
        }
    }
}

// MARK: - Collaborations Sheet
struct CollaborationsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = DependencyContainer.shared.projectsViewModel
    
    var body: some View {
        NavigationStack {
            List {
                if !viewModel.sharedProjects.isEmpty {
                    Section("Shared With Me") {
                        ForEach(viewModel.sharedProjects) { project in
                            HStack(spacing: 10) {
                                if let emoji = project.emoji, !emoji.isEmpty {
                                    Text(emoji).font(.system(size: 20))
                                } else {
                                    Image(systemName: "folder.fill")
                                        .foregroundColor(.bcPrimary)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(project.displayName)
                                        .font(.system(size: 15, weight: .medium))
                                    if let desc = project.description, !desc.isEmpty {
                                        Text(desc)
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                if !viewModel.pendingInvitations.isEmpty {
                    Section("Pending Invitations") {
                        ForEach(viewModel.pendingInvitations, id: \.id) { invitation in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(.green)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(invitation.projectName)
                                            .font(.system(size: 15, weight: .medium))
                                        Text("From \(invitation.inviterName)")
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                        Text("Role: \(invitation.role.capitalized)")
                                            .font(.system(size: 12))
                                            .foregroundColor(.bcPrimary)
                                    }
                                    Spacer()
                                }
                                
                                HStack(spacing: 12) {
                                    Button(action: {
                                        viewModel.respondToInvitation(invitation.id, accept: true)
                                    }) {
                                        Text("Accept")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(Color.green)
                                            .cornerRadius(8)
                                    }
                                    
                                    Button(action: {
                                        viewModel.respondToInvitation(invitation.id, accept: false)
                                    }) {
                                        Text("Decline")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.red)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(Color.red.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                if viewModel.sharedProjects.isEmpty && viewModel.pendingInvitations.isEmpty {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "person.2.slash")
                                .font(.system(size: 36))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("No collaborations yet")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                            Text("When someone invites you to a project, it will appear here.")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                    }
                }
            }
            .navigationTitle("Collaborations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                viewModel.loadSharedProjects()
                viewModel.loadPendingInvitations()
            }
        }
    }
}

// MARK: - Drawer Content
struct ChatDrawerContent: View {
    @Binding var showDrawer: Bool
    @Binding var showAllChats: Bool
    @Binding var showCollaborations: Bool
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var chatViewModel: ChatViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @State private var searchText = ""
    @StateObject private var projectsVM = DependencyContainer.shared.projectsViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            searchBar
                .padding(.top, 12)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            
            drawerMenuItem(icon: "square.and.pencil", label: "New chat") {
                appState.selectedProjectId = nil
                chatViewModel.startNewChat()
                appState.selectedTab = .chat
                showDrawer = false
            }
            
            Divider().padding(.horizontal, 16).padding(.vertical, 4)
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    projectsSection
                    
                    Divider().padding(.horizontal, 16).padding(.vertical, 6)
                    
                    collaborationsSection
                    
                    Divider().padding(.horizontal, 16).padding(.vertical, 6)
                    
                    recentChatsSection
                }
            }
            
            Spacer(minLength: 0)
            
            userProfileBar
        }
        .sheet(isPresented: $projectsVM.showCreateSheet) {
            CreateProjectSheet(viewModel: projectsVM)
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                
                TextField("Search", text: $searchText)
                    .font(.system(size: 15))
                    .onChange(of: searchText) { _, newValue in
                        chatViewModel.searchConversations(newValue)
                    }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            
            Button(action: {
                appState.selectedProjectId = nil
                chatViewModel.startNewChat()
                appState.selectedTab = .chat
                showDrawer = false
            }) {
                Image("SplashLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }
    
    // MARK: - Projects Section
    private var projectsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("PROJECTS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(1)
                Spacer()
                Button(action: { projectsVM.showCreateSheet = true }) {
                    Image(systemName: "plus.square")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            if projectsVM.isLoading && projectsVM.projects.isEmpty {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Loading projects...")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16).padding(.vertical, 8)
            } else if projectsVM.projects.isEmpty {
                Text("No projects yet")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16).padding(.vertical, 6)
            } else {
                ForEach(projectsVM.projects.prefix(3)) { project in
                    drawerProjectItem(project: project)
                }
                
                if projectsVM.projects.count > 3 {
                    Button(action: {
                        appState.selectedProjectId = nil
                        appState.selectedTab = .projects
                        showDrawer = false
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "folder")
                                .font(.system(size: 14))
                            Text("All projects (\(projectsVM.projects.count))")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                    }
                }
            }
        }
    }
    
    // MARK: - Collaborations Section
    private var collaborationsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("COLLABORATIONS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(1)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            
            drawerMenuItem(icon: "person.2", label: "View All") {
                showDrawer = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showCollaborations = true
                }
            }
            
            if !projectsVM.pendingInvitations.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                    Text("\(projectsVM.pendingInvitations.count) pending invitation\(projectsVM.pendingInvitations.count > 1 ? "s" : "")")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.green)
                .cornerRadius(8)
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
        }
    }
    
    // MARK: - Recent Chats Section
    private var recentChatsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Recent Chats")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            
            if chatViewModel.isLoadingConversations && chatViewModel.conversations.isEmpty {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Loading chats...")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16).padding(.vertical, 8)
            } else if chatViewModel.conversations.isEmpty {
                Text("No conversations yet")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16).padding(.vertical, 6)
            } else {
                ForEach(filteredConversations.prefix(10)) { conversation in
                    drawerChatItem(conversation: conversation)
                }
                
                if chatViewModel.conversations.count > 10 {
                    Button(action: {
                        showDrawer = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showAllChats = true
                        }
                    }) {
                        Text("View all (\(chatViewModel.conversations.count))")
                            .font(.system(size: 14))
                            .foregroundColor(.bcPrimary)
                            .padding(.horizontal, 16).padding(.vertical, 8)
                    }
                }
            }
        }
    }
    
    // MARK: - User Profile Bar
    private var userProfileBar: some View {
        VStack(spacing: 0) {
            Divider()
            Button(action: {
                appState.selectedProjectId = nil
                appState.selectedTab = .settings
                showDrawer = false
            }) {
                HStack(spacing: 12) {
                    if let avatarUrl = chatViewModel.userProfile?.avatar,
                       let url = URL(string: avatarUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: { avatarPlaceholder }
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                    } else {
                        avatarPlaceholder
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(userDisplayName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        Text(userEmail)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "gearshape")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
        }
    }
    
    private var avatarPlaceholder: some View {
        Circle()
            .fill(Color(hex: "7C4DFF"))
            .frame(width: 36, height: 36)
            .overlay(
                Text(userInitials)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            )
    }
    
    private var userDisplayName: String {
        if let profile = chatViewModel.userProfile, !profile.displayName.isEmpty { return profile.displayName }
        if let user = authViewModel.currentUser {
            if let first = user.firstName, !first.isEmpty {
                return user.lastName.map { "\(first) \($0)" } ?? first
            }
        }
        return "User"
    }
    
    private var userEmail: String {
        chatViewModel.userProfile?.email ?? authViewModel.currentUser?.email ?? ""
    }
    
    private var userInitials: String {
        chatViewModel.userProfile?.initials ?? authViewModel.currentUser?.initials ?? "U"
    }
    
    private var filteredConversations: [Conversation] {
        if searchText.isEmpty { return chatViewModel.conversations }
        return chatViewModel.conversations.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    // MARK: - Drawer Items
    private func drawerMenuItem(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.primary)
                    .frame(width: 22)
                Text(label)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .contentShape(Rectangle())
        }
    }
    
    private func drawerProjectItem(project: Project) -> some View {
        Button(action: {
            appState.selectedProjectId = project.id
            showDrawer = false
        }) {
            HStack(spacing: 10) {
                if let emoji = project.emoji, !emoji.isEmpty {
                    Text(emoji).font(.system(size: 16))
                        .frame(width: 28, height: 28)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(6)
                } else {
                    Image(systemName: "folder").font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(width: 28, height: 28)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(6)
                }
                Text(project.displayName).font(.system(size: 15))
                    .foregroundColor(.primary).lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
            .contentShape(Rectangle())
        }
    }
    
    private func drawerChatItem(conversation: Conversation) -> some View {
        Button(action: {
            appState.selectedProjectId = nil
            chatViewModel.loadConversation(conversation.id)
            appState.selectedTab = .chat
            showDrawer = false
        }) {
            HStack(spacing: 8) {
                if conversation.isPinned {
                    Image(systemName: "pin.fill").font(.system(size: 10))
                        .foregroundColor(.orange).rotationEffect(.degrees(45))
                }
                Text(conversation.title).font(.system(size: 14))
                    .foregroundColor(chatViewModel.currentConversationId == conversation.id ? .bcPrimary : .primary)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(chatViewModel.currentConversationId == conversation.id ? Color.bcPrimary.opacity(0.08) : Color.clear)
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
