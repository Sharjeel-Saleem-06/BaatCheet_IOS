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

// MARK: - Main View (Chat is always the main screen, drawer overlays)
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
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.2)) { showDrawer = false }
                    }
                
                ChatDrawerContent(showDrawer: $showDrawer)
                    .frame(width: 300)
                    .background(Color(UIColor.systemBackground))
                    .transition(.move(edge: .leading))
            }
        }
        .animation(.easeOut(duration: 0.2), value: showDrawer)
        .environment(\.showDrawer, $showDrawer)
    }
    
    @ViewBuilder
    private var currentScreen: some View {
        if let projectId = appState.selectedProjectId {
            ProjectDetailInlineView(projectId: projectId)
        } else {
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
}

// MARK: - Project Detail Inline View (shown when project clicked from drawer, like Android)
struct ProjectDetailInlineView: View {
    let projectId: String
    @EnvironmentObject private var appState: AppState
    @Environment(\.showDrawer) private var showDrawer
    @StateObject private var viewModel = DependencyContainer.shared.projectsViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            if let project = viewModel.selectedProject {
                // Tab Picker (AI Chats / Team Chat)
                HStack(spacing: 0) {
                    tabButton(icon: "cpu", label: "AI Chats", index: 0)
                    tabButton(icon: "person.2", label: "Team Chat", index: 1)
                    tabButton(icon: "gearshape", label: "Settings", index: 2)
                }
                .padding(.horizontal, 8)
                .padding(.top, 4)
                
                // Content
                TabView(selection: $selectedTab) {
                    ProjectAIChatsTab(viewModel: viewModel)
                        .tag(0)
                    
                    ProjectTeamTab(viewModel: viewModel, project: project)
                        .tag(1)
                    
                    ProjectSettingsTab(project: project)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            } else if viewModel.isLoadingProject {
                Spacer()
                ProgressView("Loading project...")
                Spacer()
            } else {
                Spacer()
                ContentUnavailableView(
                    "Project not found",
                    systemImage: "folder",
                    description: Text("This project could not be loaded")
                )
                Spacer()
            }
        }
        .navigationTitle(viewModel.selectedProject?.displayName ?? "Project")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { showDrawer.wrappedValue = true }) {
                    Image(systemName: "line.3.horizontal")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    appState.selectedProjectId = nil
                    appState.selectedTab = .chat
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                }
            }
        }
        .onAppear {
            viewModel.loadProject(projectId)
        }
    }
    
    private func tabButton(icon: String, label: String, index: Int) -> some View {
        Button(action: { withAnimation { selectedTab = index } }) {
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                    Text(label)
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(selectedTab == index ? .bcPrimary : .secondary)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                
                Rectangle()
                    .fill(selectedTab == index ? Color.bcPrimary : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Project AI Chats Tab (matches Android ProjectChatScreen AI Chats tab)
struct ProjectAIChatsTab: View {
    @ObservedObject var viewModel: ProjectsViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            if let project = viewModel.selectedProject {
                // Project info card
                if let context = project.context, !context.isEmpty {
                    projectInfoCard(project: project)
                }
            }
            
            // Conversations list
            if viewModel.projectConversations.isEmpty && !viewModel.isLoadingProject {
                Spacer()
                ContentUnavailableView(
                    "No Chats",
                    systemImage: "bubble.left.and.bubble.right",
                    description: Text("Start a chat in this project")
                )
                Spacer()
            } else {
                List {
                    ForEach(viewModel.projectConversations) { conversation in
                        ConversationRow(conversation: conversation)
                    }
                }
                .listStyle(.plain)
            }
        }
        .overlay {
            if viewModel.isLoadingProject {
                ProgressView()
            }
        }
    }
    
    private func projectInfoCard(project: Project) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let desc = project.description, !desc.isEmpty {
                Text(desc)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            if !project.keyTopics.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(project.keyTopics, id: \.self) { topic in
                            Text(topic)
                                .font(.system(size: 11, weight: .medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.bcPrimary.opacity(0.1))
                                .foregroundColor(.bcPrimary)
                                .cornerRadius(12)
                        }
                    }
                }
            }
            
            if !project.techStack.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(project.techStack, id: \.self) { tech in
                            Text(tech)
                                .font(.system(size: 11, weight: .medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.1))
                                .foregroundColor(.secondary)
                                .cornerRadius(12)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// MARK: - Drawer Content (matches Android ChatDrawerContent exactly)
struct ChatDrawerContent: View {
    @Binding var showDrawer: Bool
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
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            } else if projectsVM.projects.isEmpty {
                Text("No projects yet")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
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
                                .foregroundColor(.secondary)
                            Text("All projects (\(projectsVM.projects.count))")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
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
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            } else if chatViewModel.conversations.isEmpty {
                Text("No conversations yet")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
            } else {
                ForEach(filteredConversations.prefix(10)) { conversation in
                    drawerChatItem(conversation: conversation)
                }
                
                if chatViewModel.conversations.count > 10 {
                    Button(action: {
                        appState.selectedProjectId = nil
                        appState.selectedTab = .chat
                        showDrawer = false
                    }) {
                        Text("View all (\(chatViewModel.conversations.count))")
                            .font(.system(size: 14))
                            .foregroundColor(.bcPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                }
            }
        }
    }
    
    // MARK: - User Profile Bar (bottom of drawer)
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
                        } placeholder: {
                            avatarPlaceholder
                        }
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
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
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
        if let profile = chatViewModel.userProfile, !profile.displayName.isEmpty {
            return profile.displayName
        }
        if let user = authViewModel.currentUser {
            if let first = user.firstName, !first.isEmpty {
                if let last = user.lastName, !last.isEmpty {
                    return "\(first) \(last)"
                }
                return first
            }
        }
        return "User"
    }
    
    private var userEmail: String {
        chatViewModel.userProfile?.email ?? authViewModel.currentUser?.email ?? ""
    }
    
    private var userInitials: String {
        if let profile = chatViewModel.userProfile {
            return profile.initials
        }
        if let user = authViewModel.currentUser {
            return user.initials
        }
        return "U"
    }
    
    private var filteredConversations: [Conversation] {
        if searchText.isEmpty { return chatViewModel.conversations }
        return chatViewModel.conversations.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // MARK: - Drawer Item Components
    
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
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
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
                    Text(emoji)
                        .font(.system(size: 16))
                        .frame(width: 28, height: 28)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(6)
                } else {
                    Image(systemName: "folder")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(width: 28, height: 28)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(6)
                }
                
                Text(project.displayName)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
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
                    Image(systemName: "pin.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                        .rotationEffect(.degrees(45))
                }
                
                Text(conversation.title)
                    .font(.system(size: 14))
                    .foregroundColor(
                        chatViewModel.currentConversationId == conversation.id ? .bcPrimary : .primary
                    )
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                chatViewModel.currentConversationId == conversation.id
                    ? Color.bcPrimary.opacity(0.08)
                    : Color.clear
            )
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
