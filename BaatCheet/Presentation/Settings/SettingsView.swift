//
//  SettingsView.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var chatViewModel: ChatViewModel
    @Environment(\.showDrawer) private var showDrawer
    
    @State private var showLogoutConfirmation = false
    @State private var showDeleteAccountConfirmation = false
    @State private var showClearHistoryConfirmation = false
    @State private var showChangePassword = false
    @State private var showCustomInstructions = false
    
    var body: some View {
        List {
            // Profile
            Section {
                profileHeader
            }
            
            // Usage
            Section("Usage") {
                usageRow
            }
            
            // Personalization
            Section("Personalization") {
                Button(action: { showCustomInstructions = true }) {
                    Label("Custom Instructions", systemImage: "text.bubble")
                        .foregroundColor(.primary)
                }
            }
            
            // Data Management
            Section("Data Management") {
                Button(action: { showClearHistoryConfirmation = true }) {
                    Label("Clear Chat History", systemImage: "trash")
                        .foregroundColor(.primary)
                }
            }
            
            // About & Legal
            Section("About & Legal") {
                Link(destination: URL(string: "https://baatcheet.app/privacy")!) {
                    Label("Privacy Policy", systemImage: "hand.raised")
                        .foregroundColor(.primary)
                }
                
                Link(destination: URL(string: "https://baatcheet.app/terms")!) {
                    Label("Terms of Service", systemImage: "doc.text")
                        .foregroundColor(.primary)
                }
                
                Link(destination: URL(string: "mailto:support@baatcheet.app")!) {
                    Label("Contact Support", systemImage: "envelope")
                        .foregroundColor(.primary)
                }
                
                HStack {
                    Label("Version", systemImage: "info.circle")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
            
            // Account & Security
            Section("Account & Security") {
                Button(action: { showChangePassword = true }) {
                    Label("Change Password", systemImage: "lock.rotation")
                        .foregroundColor(.primary)
                }
                
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
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { showDrawer.wrappedValue = true }) {
                    Image(systemName: "line.3.horizontal")
                }
            }
        }
        .confirmationDialog("Sign Out?", isPresented: $showLogoutConfirmation) {
            Button("Sign Out", role: .destructive) {
                Task { await authViewModel.logout() }
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Delete Account?", isPresented: $showDeleteAccountConfirmation, titleVisibility: .visible) {
            Button("Delete Account", role: .destructive) {}
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your account and all data. This action cannot be undone.")
        }
        .confirmationDialog("Clear Chat History?", isPresented: $showClearHistoryConfirmation) {
            Button("Clear All", role: .destructive) {
                // chatViewModel.clearHistory()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete all your conversation history. This cannot be undone.")
        }
        .sheet(isPresented: $showChangePassword) {
            ChangePasswordSheet()
        }
        .sheet(isPresented: $showCustomInstructions) {
            CustomInstructionsSheet()
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        HStack(spacing: 14) {
            if let avatarUrl = chatViewModel.userProfile?.avatar,
               let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    avatarPlaceholder
                }
                .frame(width: 56, height: 56)
                .clipShape(Circle())
            } else {
                avatarPlaceholder
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(chatViewModel.userProfile?.displayName ?? "User")
                    .font(.system(size: 18, weight: .semibold))
                
                Text(chatViewModel.userProfile?.email ?? "")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Text("Free tier")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.bcPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.bcPrimary.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var avatarPlaceholder: some View {
        Circle()
            .fill(Color.bcPrimary.opacity(0.2))
            .frame(width: 56, height: 56)
            .overlay(
                Text(chatViewModel.userProfile?.initials ?? "?")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.bcPrimary)
            )
    }
    
    // MARK: - Usage
    private var usageRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Messages")
                        .font(.system(size: 13))
                    Spacer()
                    Text("\(chatViewModel.usageInfo.messagesUsed)/\(chatViewModel.usageInfo.messagesLimit)")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                ProgressView(value: chatViewModel.usageInfo.messageUsagePercentage)
                    .tint(.bcPrimary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Images/Day")
                        .font(.system(size: 13))
                    Spacer()
                    Text("\(chatViewModel.usageInfo.imagesUsed)/\(chatViewModel.usageInfo.imagesLimit)")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                ProgressView(value: chatViewModel.usageInfo.imageUsagePercentage)
                    .tint(.orange)
            }
        }
    }
}

// MARK: - Change Password Sheet
struct ChangePasswordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Current Password", text: $currentPassword)
                    SecureField("New Password", text: $newPassword)
                    SecureField("Confirm New Password", text: $confirmPassword)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.system(size: 14))
                    }
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        guard newPassword == confirmPassword else {
                            errorMessage = "Passwords do not match"
                            return
                        }
                        guard newPassword.count >= 8 else {
                            errorMessage = "Password must be at least 8 characters"
                            return
                        }
                        Task {
                            isLoading = true
                            do {
                                try await authViewModel.authRepository.changePassword(
                                    currentPassword: currentPassword,
                                    newPassword: newPassword
                                )
                                showSuccess = true
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isLoading = false
                        }
                    }
                    .disabled(currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty || isLoading)
                }
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("Password changed successfully.")
            }
        }
    }
}

// MARK: - Custom Instructions Sheet
struct CustomInstructionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var instructions = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("What would you like BaatCheet to know about you to provide better responses?")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                TextEditor(text: $instructions)
                    .font(.system(size: 15))
                    .padding(12)
                    .frame(minHeight: 200)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                
                HStack {
                    Spacer()
                    Text("\(instructions.count)/1500")
                        .font(.system(size: 13))
                        .foregroundColor(instructions.count > 1500 ? .red : .secondary)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle("Custom Instructions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        dismiss()
                    }
                    .disabled(instructions.count > 1500 || isLoading)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(DependencyContainer.shared.authViewModel)
            .environmentObject(DependencyContainer.shared.chatViewModel)
    }
}
