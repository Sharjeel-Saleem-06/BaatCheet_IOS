//
//  SettingsView.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import SwiftUI
import SafariServices
import PhotosUI

struct SettingsView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var chatViewModel: ChatViewModel
    @Environment(\.showDrawer) private var showDrawer
    
    @State private var showLogoutConfirmation = false
    @State private var showDeleteAccountConfirmation = false
    @State private var showClearHistoryConfirmation = false
    @State private var showChangePassword = false
    @State private var showCustomInstructions = false
    @State private var showEditProfile = false
    @State private var safariURL: URL?
    
    @State private var profileExpanded = true
    @State private var usageExpanded = true
    @State private var personalizationExpanded = true
    @State private var dataExpanded = true
    @State private var aboutExpanded = true
    @State private var accountExpanded = true
    
    @State private var debugExpanded = false
    @State private var showSignalRLog = false
    @State private var signalRStatus: String = "Disconnected"
    
    var body: some View {
        List {
            profileSection
            usageSection
            realtimeSection
            personalizationSection
            dataManagementSection
            aboutLegalSection
            accountSecuritySection
            debugSection
            appInfoSection
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
                chatViewModel.clearHistory()
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
        .sheet(isPresented: $showEditProfile) {
            EditProfileSheet()
        }
        .sheet(item: $safariURL) { url in
            SafariView(url: url)
                .ignoresSafeArea()
        }
    }
    
    // MARK: - Profile Section
    private var profileSection: some View {
        Section {
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
                
                Button(action: { showEditProfile = true }) {
                    Image(systemName: "pencil.circle")
                        .font(.system(size: 22))
                        .foregroundColor(.bcPrimary)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Usage Section
    private var usageSection: some View {
        Section {
            DisclosureGroup(isExpanded: $usageExpanded) {
                VStack(alignment: .leading, spacing: 12) {
                    usageBar(
                        label: "Messages",
                        used: chatViewModel.usageInfo.messagesUsed,
                        limit: chatViewModel.usageInfo.messagesLimit,
                        percentage: chatViewModel.usageInfo.messageUsagePercentage,
                        color: .bcPrimary
                    )
                    
                    usageBar(
                        label: "Chats",
                        used: chatViewModel.conversations.count,
                        limit: 999,
                        percentage: 0,
                        color: .blue
                    )
                    
                    usageBar(
                        label: "Images/Day",
                        used: chatViewModel.usageInfo.imagesUsed,
                        limit: chatViewModel.usageInfo.imagesLimit,
                        percentage: chatViewModel.usageInfo.imageUsagePercentage,
                        color: .orange
                    )
                }
            } label: {
                Label("Usage", systemImage: "chart.bar")
                    .font(.system(size: 15, weight: .medium))
            }
        }
    }
    
    private func usageBar(label: String, used: Int, limit: Int, percentage: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 13))
                Spacer()
                Text("\(used)/\(limit)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            if percentage > 0 {
                ProgressView(value: percentage)
                    .tint(color)
            }
        }
    }
    
    // MARK: - Personalization
    private var personalizationSection: some View {
        Section {
            DisclosureGroup(isExpanded: $personalizationExpanded) {
                Button(action: { showCustomInstructions = true }) {
                    HStack {
                        Label("Custom Instructions", systemImage: "text.bubble")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            } label: {
                Label("Personalization", systemImage: "person.text.rectangle")
                    .font(.system(size: 15, weight: .medium))
            }
        }
    }
    
    // MARK: - Data Management
    private var dataManagementSection: some View {
        Section {
            DisclosureGroup(isExpanded: $dataExpanded) {
                Button(action: { showClearHistoryConfirmation = true }) {
                    HStack {
                        Label("Clear Chat History", systemImage: "trash")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            } label: {
                Label("Data Management", systemImage: "externaldrive")
                    .font(.system(size: 15, weight: .medium))
            }
        }
    }
    
    // MARK: - About & Legal
    private var aboutLegalSection: some View {
        Section {
            DisclosureGroup(isExpanded: $aboutExpanded) {
                Button(action: { safariURL = URL(string: "https://baatcheet-web.netlify.app/privacy") }) {
                    HStack {
                        Label("Privacy Policy", systemImage: "hand.raised")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                Button(action: { safariURL = URL(string: "https://baatcheet-web.netlify.app/terms") }) {
                    HStack {
                        Label("Terms of Service", systemImage: "doc.text")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                Button(action: { openContactSupport() }) {
                    HStack {
                        Label("Contact Support", systemImage: "envelope")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            } label: {
                Label("About & Legal", systemImage: "info.circle")
                    .font(.system(size: 15, weight: .medium))
            }
        }
    }
    
    // MARK: - Account & Security
    private var accountSecuritySection: some View {
        Section {
            DisclosureGroup(isExpanded: $accountExpanded) {
                Button(action: { showChangePassword = true }) {
                    HStack {
                        Label("Change Password", systemImage: "lock.rotation")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
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
            } label: {
                Label("Account & Security", systemImage: "shield")
                    .font(.system(size: 15, weight: .medium))
            }
        }
    }
    
    // MARK: - Realtime (SignalR) Section
    private var realtimeSection: some View {
        Section {
            HStack {
                Label("Realtime Connection", systemImage: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 15, weight: .medium))
                Spacer()
                Circle()
                    .fill(signalRStatusColor)
                    .frame(width: 10, height: 10)
                Text(signalRStatus)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Toggle(isOn: $chatViewModel.realtimeEnabled) {
                Label("Enable Realtime Updates", systemImage: "bolt.fill")
            }
            .tint(.bcPrimary)
            .onChange(of: chatViewModel.realtimeEnabled) { _, enabled in
                Task {
                    if enabled {
                        await chatViewModel.connectRealtime()
                    } else {
                        await chatViewModel.disconnectRealtime()
                    }
                }
            }
            
            Button(action: {
                Task { await chatViewModel.connectRealtime() }
            }) {
                HStack {
                    Label("Reconnect", systemImage: "arrow.triangle.2.circlepath")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var signalRStatusColor: Color {
        switch chatViewModel.connectionState {
        case .connected: return .green
        case .connecting, .reconnecting: return .orange
        case .disconnected: return .gray
        case .failed: return .red
        }
    }
    
    // MARK: - Debug Section (VULNERABILITY: Exposed in production)
    private var debugSection: some View {
        Section {
            DisclosureGroup(isExpanded: $debugExpanded) {
                // VULNERABILITY: Exposing API debug info in production UI
                Button(action: { showSignalRLog = true }) {
                    HStack {
                        Label("View SignalR Log", systemImage: "doc.text.magnifyingglass")
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(SignalRService.shared.getMessageLog().count) entries")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                Button(action: {
                    // VULNERABILITY: Dumping full request log to console
                    let log = DependencyContainer.shared.apiClient.dumpRequestLog()
                    print(log)
                    UIPasteboard.general.string = log
                }) {
                    HStack {
                        Label("Copy API Request Log", systemImage: "doc.on.clipboard")
                            .foregroundColor(.primary)
                        Spacer()
                    }
                }
                
                Toggle(isOn: Binding(
                    get: { APIClient.verboseLogging },
                    set: { APIClient.verboseLogging = $0 }
                )) {
                    Label("Verbose Logging", systemImage: "terminal")
                }
                .tint(.orange)
                
                Toggle(isOn: Binding(
                    get: { APIConfig.enableDebugPanel },
                    set: { APIConfig.enableDebugPanel = $0 }
                )) {
                    Label("Debug Panel", systemImage: "ladybug")
                }
                .tint(.red)
                
                // VULNERABILITY: Button to clear keychain (destructive, no confirmation)
                Button(role: .destructive, action: {
                    KeychainHelper.shared.clearAll()
                }) {
                    Label("Clear Keychain (Danger)", systemImage: "trash.fill")
                }
            } label: {
                Label("Developer Options", systemImage: "wrench.and.screwdriver")
                    .font(.system(size: 15, weight: .medium))
            }
        }
        .sheet(isPresented: $showSignalRLog) {
            SignalRLogSheet()
        }
    }
    
    // MARK: - App Info
    private var appInfoSection: some View {
        Section {
            HStack {
                Label("Version", systemImage: "app.badge")
                Spacer()
                Text("1.1.0-signalr")
                    .foregroundColor(.secondary)
            }
            HStack {
                Label("Build", systemImage: "hammer")
                Spacer()
                Text("2024.01.29-rc1")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Helpers
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
    
    private func openContactSupport() {
        let email = "support@baatcheet.app"
        let subject = "BaatCheet iOS Support"
        let mailtoString = "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject)"
        
        if let url = URL(string: mailtoString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let gmailUrl = URL(string: "googlegmail:///co?to=\(email)&subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject)"),
                  UIApplication.shared.canOpenURL(gmailUrl) {
            UIApplication.shared.open(gmailUrl)
        } else {
            safariURL = URL(string: "https://baatcheet-web.netlify.app/contact")
        }
    }
}

// MARK: - Edit Profile Sheet
struct EditProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var chatViewModel: ChatViewModel
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    @State private var selectedPhotoImage: Image?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    ZStack(alignment: .bottomTrailing) {
                        if let selectedPhotoImage {
                            selectedPhotoImage
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else if let avatarUrl = chatViewModel.userProfile?.avatar,
                                  let url = URL(string: avatarUrl) {
                            AsyncImage(url: url) { image in
                                image.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                profilePlaceholder
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                        } else {
                            profilePlaceholder
                        }
                        
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.bcPrimary)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color(UIColor.systemBackground), lineWidth: 2))
                        }
                        .offset(x: 4, y: 4)
                    }
                    .padding(.top, 10)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("First Name")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            TextField("First name", text: $firstName)
                                .font(.system(size: 16))
                                .padding(12)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(10)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Last Name")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            TextField("Last name", text: $lastName)
                                .font(.system(size: 16))
                                .padding(12)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .disabled(isLoading)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isLoading {
                        ProgressView().controlSize(.small)
                    } else {
                        Button("Save") {
                            saveProfile()
                        }
                        .disabled(firstName.trimmed.isEmpty)
                    }
                }
            }
            .onAppear {
                firstName = chatViewModel.userProfile?.firstName ?? ""
                lastName = chatViewModel.userProfile?.lastName ?? ""
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        selectedPhotoData = data
                        if let uiImage = UIImage(data: data) {
                            selectedPhotoImage = Image(uiImage: uiImage)
                        }
                    }
                }
            }
        }
    }
    
    private var profilePlaceholder: some View {
        Circle()
            .fill(Color.bcPrimary.opacity(0.2))
            .frame(width: 100, height: 100)
            .overlay(
                Text(chatViewModel.userProfile?.initials ?? "?")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(.bcPrimary)
            )
    }
    
    private func saveProfile() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await chatViewModel.updateProfile(
                    firstName: firstName.trimmed,
                    lastName: lastName.trimmed,
                    avatarData: selectedPhotoData
                )
                isLoading = false
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
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

// MARK: - Safari View Wrapper
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - SignalR Log Sheet (VULNERABILITY: Shows raw logs with tokens in production)
struct SignalRLogSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var logEntries: [String] = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(logEntries.indices, id: \.self) { index in
                        Text(logEntries[index])
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(logEntries[index].contains("error") ? .red : .primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 2)
                    }
                }
            }
            .navigationTitle("SignalR Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") {
                        SignalRService.shared.clearLog()
                        logEntries = []
                    }
                    .foregroundColor(.red)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                logEntries = SignalRService.shared.getMessageLog()
            }
        }
    }
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(DependencyContainer.shared.authViewModel)
            .environmentObject(DependencyContainer.shared.chatViewModel)
    }
}
