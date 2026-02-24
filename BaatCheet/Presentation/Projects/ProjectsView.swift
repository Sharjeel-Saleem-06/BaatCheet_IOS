//
//  ProjectsView.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import SwiftUI

struct ProjectsView: View {
    // MARK: - State
    @StateObject private var viewModel = DependencyContainer.shared.projectsViewModel
    @Environment(\.showDrawer) private var showDrawer
    
    // MARK: - Body
    var body: some View {
        List {
            // Pending Invitations
            if !viewModel.pendingInvitations.isEmpty {
                Section {
                    ForEach(viewModel.pendingInvitations) { invitation in
                        InvitationRow(invitation: invitation) { accept in
                            viewModel.respondToInvitation(invitation.id, accept: accept)
                        }
                    }
                } header: {
                    HStack {
                        Text("Invitations")
                        Spacer()
                        Text("\(viewModel.pendingInvitations.count)")
                            .font(.bcCaption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.bcPrimary)
                            .cornerRadius(10)
                    }
                }
            }
            
            // My Projects
            Section("My Projects") {
                ForEach(viewModel.projects.filter { $0.isOwner }) { project in
                    NavigationLink(destination: ProjectDetailView(project: project)) {
                        ProjectRow(project: project)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.deleteProject(project.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                
                if viewModel.projects.filter({ $0.isOwner }).isEmpty && !viewModel.isLoading {
                    Button(action: { viewModel.showCreateSheet = true }) {
                        Label("Create your first project", systemImage: "plus")
                            .foregroundColor(.bcPrimary)
                    }
                }
            }
            
            // Shared Projects
            if !viewModel.projects.filter({ !$0.isOwner }).isEmpty {
                Section("Shared with me") {
                    ForEach(viewModel.projects.filter { !$0.isOwner }) { project in
                        NavigationLink(destination: ProjectDetailView(project: project)) {
                            ProjectRow(project: project)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Projects")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { showDrawer.wrappedValue = true }) {
                    Image(systemName: "line.3.horizontal")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { viewModel.showCreateSheet = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .refreshable {
            viewModel.loadProjects()
            viewModel.loadPendingInvitations()
        }
        .overlay {
            if viewModel.isLoading && viewModel.projects.isEmpty {
                ProgressView()
            }
        }
        .sheet(isPresented: $viewModel.showCreateSheet) {
            CreateProjectSheet(viewModel: viewModel)
        }
        .onAppear {
            viewModel.loadPendingInvitations()
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.error ?? "")
        }
    }
}

// MARK: - Project Row
struct ProjectRow: View {
    let project: Project
    
    var body: some View {
        HStack(spacing: BCSpacing.sm) {
            // Emoji Icon
            Text(project.displayEmoji)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(BCCornerRadius.sm)
            
            VStack(alignment: .leading, spacing: BCSpacing.xxs) {
                Text(project.displayName)
                    .font(.bcBodyMedium)
                    .foregroundColor(.primary)
                
                HStack(spacing: BCSpacing.xs) {
                    Text("\(project.conversationCount) chats")
                        .font(.bcCaption)
                        .foregroundColor(.secondary)
                    
                    if project.isShared {
                        Label("\(project.collaboratorCount)", systemImage: "person.2")
                            .font(.bcCaption)
                            .foregroundColor(.bcPrimary)
                    }
                    
                    if !project.isOwner {
                        Text("• \(project.roleDisplayName)")
                            .font(.bcCaption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, BCSpacing.xxs)
    }
}

// MARK: - Invitation Row
struct InvitationRow: View {
    let invitation: PendingInvitation
    let onRespond: (Bool) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: BCSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: BCSpacing.xxs) {
                    Text(invitation.projectName)
                        .font(.bcBodyMedium)
                    
                    Text("Invited by \(invitation.inviterName) as \(invitation.roleDisplayName)")
                        .font(.bcCaption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            if let message = invitation.message, !message.isEmpty {
                Text(message)
                    .font(.bcCaption)
                    .foregroundColor(.secondary)
                    .italic()
            }
            
            HStack(spacing: BCSpacing.sm) {
                Button(action: { onRespond(true) }) {
                    Text("Accept")
                        .font(.bcButtonSmall)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, BCSpacing.xs)
                        .background(Color.bcSuccess)
                        .cornerRadius(BCCornerRadius.sm)
                }
                
                Button(action: { onRespond(false) }) {
                    Text("Decline")
                        .font(.bcButtonSmall)
                        .foregroundColor(.bcError)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, BCSpacing.xs)
                        .background(Color.bcError.opacity(0.1))
                        .cornerRadius(BCCornerRadius.sm)
                }
            }
        }
        .padding(.vertical, BCSpacing.xs)
    }
}

// MARK: - Create Project Sheet
struct CreateProjectSheet: View {
    @ObservedObject var viewModel: ProjectsViewModel
    @Environment(\.dismiss) private var dismiss
    
    private let emojis = ["📁", "📂", "🗂️", "💼", "📊", "📈", "🎯", "💡", "🚀", "⭐", "🔥", "💻", "📱", "🌐", "🎨", "📝"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Emoji Picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: BCSpacing.sm) {
                            ForEach(emojis, id: \.self) { emoji in
                                Button(action: { viewModel.newProjectEmoji = emoji }) {
                                    Text(emoji)
                                        .font(.title)
                                        .padding(BCSpacing.xs)
                                        .background(
                                            viewModel.newProjectEmoji == emoji
                                            ? Color.bcPrimary.opacity(0.2)
                                            : Color.clear
                                        )
                                        .cornerRadius(BCCornerRadius.sm)
                                }
                            }
                        }
                        .padding(.vertical, BCSpacing.xs)
                    }
                }
                
                Section("Project Details") {
                    TextField("Project Name", text: $viewModel.newProjectName)
                    
                    TextField("Description (optional)", text: $viewModel.newProjectDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.clearCreateForm()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        viewModel.createProject()
                    }
                    .disabled(viewModel.newProjectName.isEmpty || viewModel.isCreating)
                }
            }
        }
    }
}

// MARK: - Project Detail View
struct ProjectDetailView: View {
    let project: Project
    @StateObject private var viewModel = DependencyContainer.shared.projectsViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Picker
            Picker("", selection: $selectedTab) {
                Text("Chats").tag(0)
                Text("Team").tag(1)
                Text("Settings").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Content
            TabView(selection: $selectedTab) {
                // Chats Tab
                ProjectChatsTab(viewModel: viewModel)
                    .tag(0)
                
                // Team Tab
                ProjectTeamTab(viewModel: viewModel, project: project)
                    .tag(1)
                
                // Settings Tab
                ProjectSettingsTab(project: project)
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle(project.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadProject(project.id)
        }
    }
}

// MARK: - Project Chats Tab
struct ProjectChatsTab: View {
    @ObservedObject var viewModel: ProjectsViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.projectConversations) { conversation in
                ConversationRow(conversation: conversation)
            }
            
            if viewModel.projectConversations.isEmpty && !viewModel.isLoadingProject {
                ContentUnavailableView(
                    "No Chats",
                    systemImage: "bubble.left.and.bubble.right",
                    description: Text("Start a chat in this project")
                )
            }
        }
        .listStyle(.plain)
        .overlay {
            if viewModel.isLoadingProject {
                ProgressView()
            }
        }
    }
}

// MARK: - Project Team Tab
struct ProjectTeamTab: View {
    @ObservedObject var viewModel: ProjectsViewModel
    let project: Project
    
    var body: some View {
        VStack(spacing: 0) {
            // Team Members
            List {
                // Owner
                if let owner = project.owner {
                    Section("Owner") {
                        CollaboratorRow(user: owner, role: "owner", isOwner: true)
                    }
                }
                
                // Collaborators
                Section("Collaborators (\(viewModel.collaborators.count))") {
                    ForEach(viewModel.collaborators) { collaborator in
                        CollaboratorRow(
                            user: collaborator.user,
                            role: collaborator.role,
                            isOwner: false
                        )
                    }
                    
                    if viewModel.collaborators.isEmpty && !viewModel.isLoadingProject {
                        Text("No collaborators yet")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Invite Button
                if project.canInvite {
                    Section {
                        Button(action: { viewModel.showInviteSheet = true }) {
                            Label("Invite Collaborator", systemImage: "person.badge.plus")
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .sheet(isPresented: $viewModel.showInviteSheet) {
            InviteCollaboratorSheet(viewModel: viewModel)
        }
    }
}

// MARK: - Collaborator Row
struct CollaboratorRow: View {
    let user: UserSummary
    let role: String
    let isOwner: Bool
    
    var roleColor: Color {
        switch role {
        case "owner": return .orange
        case "admin": return .red
        case "moderator": return .blue
        default: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: BCSpacing.sm) {
            // Avatar
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(user.initials)
                        .font(.bcLabelLarge)
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: BCSpacing.xxs) {
                Text(user.displayName)
                    .font(.bcBodyMedium)
                
                if let email = user.email {
                    Text(email)
                        .font(.bcCaption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Role Badge
            Text(role.capitalized)
                .font(.bcCaption)
                .foregroundColor(roleColor)
                .padding(.horizontal, BCSpacing.xs)
                .padding(.vertical, BCSpacing.xxs)
                .background(roleColor.opacity(0.1))
                .cornerRadius(BCCornerRadius.xs)
        }
    }
}

// MARK: - Invite Collaborator Sheet
struct InviteCollaboratorSheet: View {
    @ObservedObject var viewModel: ProjectsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Email") {
                    TextField("collaborator@email.com", text: $viewModel.inviteEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                Section("Role") {
                    Picker("Role", selection: $viewModel.inviteRole) {
                        Text("Viewer").tag("viewer")
                        Text("Moderator").tag("moderator")
                        Text("Admin").tag("admin")
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Message (optional)") {
                    TextField("Add a personal message...", text: $viewModel.inviteMessage, axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .navigationTitle("Invite Collaborator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.clearInviteForm()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Invite") {
                        viewModel.inviteCollaborator()
                    }
                    .disabled(!viewModel.inviteEmail.isValidEmail || viewModel.isInviting)
                }
            }
        }
    }
}

// MARK: - Project Settings Tab
struct ProjectSettingsTab: View {
    let project: Project
    
    var body: some View {
        List {
            Section("Project Info") {
                LabeledContent("Name", value: project.name)
                
                if let description = project.description {
                    LabeledContent("Description", value: description)
                }
                
                LabeledContent("Conversations", value: "\(project.conversationCount)")
                LabeledContent("Collaborators", value: "\(project.collaboratorCount)")
            }
            
            if project.hasContext {
                Section("AI Context") {
                    if let context = project.context {
                        Text(context)
                            .font(.bcCaption)
                            .foregroundColor(.secondary)
                    }
                    
                    if !project.keyTopics.isEmpty {
                        LabeledContent("Topics") {
                            Text(project.keyTopics.joined(separator: ", "))
                                .font(.bcCaption)
                        }
                    }
                }
            }
            
            if project.canDelete {
                Section {
                    Button(role: .destructive) {
                        // Delete project
                    } label: {
                        Label("Delete Project", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

#Preview {
    NavigationStack {
        ProjectsView()
    }
}
