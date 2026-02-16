//
//  VoiceChatView.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import SwiftUI

struct VoiceChatView: View {
    // MARK: - State
    @StateObject private var viewModel = VoiceChatViewModel(chatRepository: DependencyContainer.shared.chatRepository)
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                backgroundGradient
                
                // Content
                VStack {
                    switch viewModel.currentStep {
                    case .intro:
                        introView
                    case .voiceSelect:
                        voiceSelectionView
                    case .activeCall:
                        activeCallView
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        if viewModel.currentStep == .activeCall {
                            viewModel.endCall()
                        }
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                Text(viewModel.error ?? "")
            }
        }
    }
    
    // MARK: - Background
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                viewModel.selectedVoice?.color ?? .vcGreen,
                Color.black
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Intro View
    private var introView: some View {
        VStack(spacing: BCSpacing.xxl) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 150, height: 150)
                
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
            }
            
            // Title
            VStack(spacing: BCSpacing.sm) {
                Text("Voice Chat")
                    .font(.bcLargeTitle)
                    .foregroundColor(.white)
                
                Text("Talk naturally with AI using your voice")
                    .font(.bcBody)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Start Button
            Button(action: { viewModel.moveToVoiceSelection() }) {
                HStack {
                    Image(systemName: "phone.fill")
                    Text("Start Voice Chat")
                }
                .font(.bcButton)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: BCButtonHeight.large)
                .background(Color.white)
                .cornerRadius(BCCornerRadius.button)
            }
            .padding(.horizontal, BCSpacing.xl)
            .padding(.bottom, BCSpacing.xxl)
        }
    }
    
    // MARK: - Voice Selection View
    private var voiceSelectionView: some View {
        VStack(spacing: BCSpacing.xl) {
            // Header
            VStack(spacing: BCSpacing.sm) {
                Text("Choose a Voice")
                    .font(.bcTitle1)
                    .foregroundColor(.white)
                
                Text("Select the AI voice you want to chat with")
                    .font(.bcBody)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.top, BCSpacing.xl)
            
            // Voice Options
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: BCSpacing.md) {
                    ForEach(viewModel.availableVoices) { voice in
                        VoiceOptionCard(
                            voice: voice,
                            isSelected: viewModel.selectedVoice?.id == voice.id,
                            onSelect: { viewModel.selectVoice(voice) }
                        )
                    }
                }
                .padding(.horizontal, BCSpacing.md)
            }
            
            // Continue Button
            Button(action: { viewModel.startCall() }) {
                HStack {
                    Image(systemName: "phone.fill")
                    Text("Start Call")
                }
                .font(.bcButton)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: BCButtonHeight.large)
                .background(Color.white)
                .cornerRadius(BCCornerRadius.button)
            }
            .padding(.horizontal, BCSpacing.xl)
            .padding(.bottom, BCSpacing.xl)
        }
    }
    
    // MARK: - Active Call View
    private var activeCallView: some View {
        VStack(spacing: BCSpacing.xl) {
            Spacer()
            
            // Call Duration
            Text(viewModel.formattedCallDuration)
                .font(.system(size: 48, weight: .light, design: .monospaced))
                .foregroundColor(.white)
            
            // Status
            Text(statusText)
                .font(.bcBody)
                .foregroundColor(.white.opacity(0.7))
            
            // Audio Visualization
            audioVisualization
            
            // Current Transcript
            if !viewModel.currentTranscript.isEmpty {
                VStack(spacing: BCSpacing.xs) {
                    Text("You:")
                        .font(.bcCaption)
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text(viewModel.currentTranscript)
                        .font(.bcBody)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, BCSpacing.xl)
                }
            }
            
            // AI Response
            if !viewModel.aiResponse.isEmpty && viewModel.isAISpeaking {
                VStack(spacing: BCSpacing.xs) {
                    Text("AI:")
                        .font(.bcCaption)
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text(viewModel.aiResponse)
                        .font(.bcBody)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, BCSpacing.xl)
                        .lineLimit(4)
                }
            }
            
            Spacer()
            
            // Call Controls
            HStack(spacing: BCSpacing.xxl) {
                // Mute Button
                Button(action: { viewModel.toggleMute() }) {
                    Image(systemName: viewModel.isMuted ? "mic.slash.fill" : "mic.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
                
                // End Call Button
                Button(action: {
                    viewModel.endCall()
                    dismiss()
                }) {
                    Image(systemName: "phone.down.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                        .frame(width: 70, height: 70)
                        .background(Color.red)
                        .clipShape(Circle())
                }
                
                // Speaker Button
                Button(action: { /* Toggle speaker */ }) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }
            .padding(.bottom, BCSpacing.xxl)
        }
    }
    
    // MARK: - Audio Visualization
    private var audioVisualization: some View {
        HStack(spacing: 4) {
            ForEach(0..<20, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white)
                    .frame(width: 4, height: barHeight(for: index))
                    .animation(.easeInOut(duration: 0.1), value: viewModel.audioLevel)
            }
        }
        .frame(height: 60)
    }
    
    private func barHeight(for index: Int) -> CGFloat {
        let baseHeight: CGFloat = 10
        let maxHeight: CGFloat = 60
        let level = CGFloat(viewModel.audioLevel)
        
        // Create wave pattern
        let normalizedIndex = CGFloat(index) / 20.0
        let wave = sin(normalizedIndex * .pi * 2 + level * 10)
        let height = baseHeight + (maxHeight - baseHeight) * level * (0.5 + wave * 0.5)
        
        return max(baseHeight, height)
    }
    
    private var statusText: String {
        if viewModel.isProcessing {
            return "Processing..."
        } else if viewModel.isAISpeaking {
            return "AI is speaking..."
        } else if viewModel.isRecording {
            return "Listening..."
        } else if viewModel.isMuted {
            return "Muted"
        } else {
            return "Connecting..."
        }
    }
}

// MARK: - Voice Option Card
struct VoiceOptionCard: View {
    let voice: AIVoice
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: BCSpacing.sm) {
                // Icon
                Text(voice.icon)
                    .font(.system(size: 40))
                
                // Name
                Text(voice.name)
                    .font(.bcBodyMedium)
                    .foregroundColor(.white)
                
                // Description
                Text(voice.description)
                    .font(.bcCaption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(BCSpacing.md)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: BCCornerRadius.lg)
                    .fill(isSelected ? voice.color.opacity(0.3) : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: BCCornerRadius.lg)
                            .stroke(isSelected ? voice.color : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

#Preview {
    VoiceChatView()
}
