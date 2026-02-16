//
//  SettingsView.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import SwiftUI

struct SettingsView: View {
    // MARK: - Environment
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var chatViewModel: ChatViewModel
    
    // MARK: - State
    @State private var showLogoutConfirmation = false
    @State private var showDeleteAccountConfirmation = false
    
    // MARK: - Body
    var body: some View {
        List {
            // Profile Section
            Section {
                profileHeader
            }
            
            // Account Section
            Section("Account") {
                NavigationLink(destination: EditProfileView()) {
                    Label("Edit Profile", systemImage: "person.circle")
                }
                
                NavigationLink(destination: MemoryView()) {
                    Label("Memory & Learning", systemImage: "brain")
                }
                
                NavigationLink(destination: AnalyticsView()) {
                    Label("Analytics", systemImage: "chart.bar")
                }
            }
            
            // Preferences Section
            Section("Preferences") {
                NavigationLink(destination: AppearanceSettingsView()) {
                    Label("Appearance", systemImage: "paintbrush")
                }
                
                NavigationLink(destination: NotificationSettingsView()) {
                    Label("Notifications", systemImage: "bell")
                }
                
                NavigationLink(destination: VoiceSettingsView()) {
                    Label("Voice & Audio", systemImage: "speaker.wave.2")
                }
            }
            
            // Usage Section
            Section("Usage") {
                usageRow
            }
            
            // About Section
            Section("About") {
                NavigationLink(destination: PrivacyPolicyView()) {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }
                
                NavigationLink(destination: TermsOfServiceView()) {
                    Label("Terms of Service", systemImage: "doc.text")
                }
                
                NavigationLink(destination: HelpView()) {
                    Label("Help & Support", systemImage: "questionmark.circle")
                }
                
                HStack {
                    Label("Version", systemImage: "info.circle")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
            
            // Sign Out Section
            Section {
                Button(role: .destructive) {
                    showLogoutConfirmation = true
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
                
                Button(role: .destructive) {
                    showDeleteAccountConfirmation = true
                } label: {
                    Label("Delete Account", systemImage: "trash")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .confirmationDialog("Sign Out?", isPresented: $showLogoutConfirmation) {
            Button("Sign Out", role: .destructive) {
                Task {
                    await authViewModel.logout()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog(
            "Delete Account?",
            isPresented: $showDeleteAccountConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Account", role: .destructive) {
                // Handle delete account
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your account and all data. This action cannot be undone.")
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        HStack(spacing: BCSpacing.md) {
            // Avatar
            if let avatarUrl = chatViewModel.userProfile?.avatar,
               let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    avatarPlaceholder
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
            } else {
                avatarPlaceholder
            }
            
            VStack(alignment: .leading, spacing: BCSpacing.xxs) {
                Text(chatViewModel.userProfile?.displayName ?? "User")
                    .font(.bcTitle3)
                
                Text(chatViewModel.userProfile?.email ?? "")
                    .font(.bcBody)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, BCSpacing.xs)
    }
    
    private var avatarPlaceholder: some View {
        Circle()
            .fill(Color.bcPrimary.opacity(0.2))
            .frame(width: 60, height: 60)
            .overlay(
                Text(chatViewModel.userProfile?.initials ?? "?")
                    .font(.bcTitle2)
                    .foregroundColor(.bcPrimary)
            )
    }
    
    // MARK: - Usage Row
    private var usageRow: some View {
        VStack(alignment: .leading, spacing: BCSpacing.sm) {
            HStack {
                Text("This Month")
                    .font(.bcBodyMedium)
                Spacer()
                Text(chatViewModel.usageInfo.quotaDescription)
                    .font(.bcCaption)
                    .foregroundColor(.secondary)
            }
            
            // Messages Progress
            VStack(alignment: .leading, spacing: BCSpacing.xxs) {
                HStack {
                    Text("Messages")
                        .font(.bcCaption)
                    Spacer()
                    Text("\(chatViewModel.usageInfo.messagesUsed)/\(chatViewModel.usageInfo.messagesLimit)")
                        .font(.bcCaption)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: chatViewModel.usageInfo.messageUsagePercentage)
                    .tint(.bcPrimary)
            }
            
            // Images Progress
            VStack(alignment: .leading, spacing: BCSpacing.xxs) {
                HStack {
                    Text("Images")
                        .font(.bcCaption)
                    Spacer()
                    Text("\(chatViewModel.usageInfo.imagesUsed)/\(chatViewModel.usageInfo.imagesLimit)")
                        .font(.bcCaption)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: chatViewModel.usageInfo.imageUsagePercentage)
                    .tint(.bcSecondary)
            }
            
            if chatViewModel.usageInfo.isFreeTier {
                Button(action: { /* Show upgrade */ }) {
                    HStack {
                        Image(systemName: "star.fill")
                        Text("Upgrade to Pro")
                    }
                    .font(.bcButtonSmall)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, BCSpacing.xs)
                    .background(Color.bcPrimary)
                    .cornerRadius(BCCornerRadius.sm)
                }
                .padding(.top, BCSpacing.xs)
            }
        }
    }
}

// MARK: - Placeholder Views
struct EditProfileView: View {
    var body: some View {
        Text("Edit Profile")
            .navigationTitle("Edit Profile")
    }
}

struct MemoryView: View {
    var body: some View {
        Text("Memory & Learning")
            .navigationTitle("Memory")
    }
}

struct AnalyticsView: View {
    var body: some View {
        Text("Analytics")
            .navigationTitle("Analytics")
    }
}

struct AppearanceSettingsView: View {
    var body: some View {
        Text("Appearance Settings")
            .navigationTitle("Appearance")
    }
}

struct NotificationSettingsView: View {
    var body: some View {
        Text("Notification Settings")
            .navigationTitle("Notifications")
    }
}

struct VoiceSettingsView: View {
    var body: some View {
        Text("Voice & Audio Settings")
            .navigationTitle("Voice & Audio")
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        Text("Privacy Policy")
            .navigationTitle("Privacy Policy")
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        Text("Terms of Service")
            .navigationTitle("Terms of Service")
    }
}

struct HelpView: View {
    var body: some View {
        Text("Help & Support")
            .navigationTitle("Help")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(DependencyContainer.shared.authViewModel)
            .environmentObject(DependencyContainer.shared.chatViewModel)
    }
}
