//
//  VoiceChatViewModel.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import Foundation
import SwiftUI
import Speech
import AVFoundation

// MARK: - Voice Chat ViewModel
@MainActor
final class VoiceChatViewModel: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    // MARK: - Published State
    @Published var currentStep: VoiceModeStep = .intro
    @Published var availableVoices: [AIVoice] = []
    @Published var selectedVoice: AIVoice?
    @Published var isLoadingVoices = false
    @Published var isPlayingPreview = false
    @Published var playingVoiceId: String?
    
    // Call state
    @Published var isRecording = false
    @Published var isProcessing = false
    @Published var isAISpeaking = false
    @Published var isMuted = false
    @Published var currentTranscript = ""
    @Published var aiResponse = ""
    @Published var callDuration: TimeInterval = 0
    @Published var audioLevel: Float = 0
    @Published var conversationId: String?
    @Published var error: String?
    
    // MARK: - Private Properties
    private let chatRepository: ChatRepository
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var audioEngine = AVAudioEngine()
    private let synthesizer = AVSpeechSynthesizer()
    private var callTimer: Timer?
    
    // MARK: - Init
    init(chatRepository: ChatRepository) {
        self.chatRepository = chatRepository
        super.init()
        synthesizer.delegate = self
        loadAvailableVoices()
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isAISpeaking = false
            self.currentTranscript = ""
            if self.currentStep == .activeCall && !self.isMuted {
                self.startRecording()
            }
        }
    }
    
    // MARK: - Voice Loading
    func loadAvailableVoices() {
        availableVoices = [
            AIVoice(id: "ur-PK-AsadNeural", name: "Asad (اردو)", description: "Pakistani Urdu • Best for Urdu & Roman Urdu", color: .vcGreen, icon: "🇵🇰"),
            AIVoice(id: "ur-PK-UzmaNeural", name: "Uzma (اردو)", description: "Pakistani Urdu • Warm feminine voice", color: .vcPink, icon: "🇵🇰"),
            AIVoice(id: "en-US-GuyNeural", name: "Guy (English)", description: "American English • Clear male voice", color: .vcBlue, icon: "🇺🇸"),
            AIVoice(id: "en-US-JennyNeural", name: "Jenny (English)", description: "American English • Friendly female voice", color: .vcIndigo, icon: "🇺🇸"),
            AIVoice(id: "en-GB-RyanNeural", name: "Ryan (English)", description: "British English • Professional male voice", color: .vcPurple, icon: "🇬🇧"),
            AIVoice(id: "en-GB-SoniaNeural", name: "Sonia (English)", description: "British English • Elegant female voice", color: .vcOrange, icon: "🇬🇧")
        ]
        selectedVoice = availableVoices.first
    }
    
    // MARK: - Navigation
    func moveToVoiceSelection() {
        currentStep = .voiceSelect
    }
    
    func selectVoice(_ voice: AIVoice) {
        selectedVoice = voice
    }
    
    func startCall() {
        currentStep = .activeCall
        requestPermissions()
    }
    
    // MARK: - Permissions
    private func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self?.requestMicrophonePermission()
                case .denied, .restricted, .notDetermined:
                    self?.error = "Speech recognition permission denied"
                @unknown default:
                    break
                }
            }
        }
    }
    
    private func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.startVoiceCall()
                } else {
                    self?.error = "Microphone permission denied"
                }
            }
        }
    }
    
    // MARK: - Voice Call
    func startVoiceCall() {
        callDuration = 0
        currentTranscript = ""
        aiResponse = ""
        
        // Configure audio session
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            self.error = "Failed to configure audio: \(error.localizedDescription)"
            return
        }
        
        // Start call timer
        callTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.callDuration += 1
            }
        }
        
        // Start listening
        startRecording()
    }
    
    func endCall() {
        callTimer?.invalidate()
        callTimer = nil
        stopRecording()
        synthesizer.stopSpeaking(at: .immediate)
        currentStep = .intro
        isRecording = false
        isProcessing = false
        isAISpeaking = false
        currentTranscript = ""
        aiResponse = ""
    }
    
    // MARK: - Speech Recognition
    func startRecording() {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            error = "Speech recognition not available"
            return
        }
        
        // Cancel any existing task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            error = "Unable to create speech recognition request"
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.taskHint = .dictation
        
        // Configure audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            
            // Calculate audio level
            let level = self?.calculateAudioLevel(buffer: buffer) ?? 0
            Task { @MainActor in
                self?.audioLevel = level
            }
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            self.error = "Failed to start audio engine: \(error.localizedDescription)"
            return
        }
        
        // Start recognition
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                Task { @MainActor in
                    self.currentTranscript = result.bestTranscription.formattedString
                    
                    // Check for silence (end of speech)
                    if result.isFinal {
                        self.handleEndOfSpeech()
                    }
                }
            }
            
            if let error = error {
                Task { @MainActor in
                    if (error as NSError).code != 1 { // Ignore cancellation errors
                        self.error = error.localizedDescription
                    }
                }
            }
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isRecording = false
        audioLevel = 0
    }
    
    // MARK: - Handle End of Speech
    private func handleEndOfSpeech() {
        guard !currentTranscript.isEmpty else { return }
        
        stopRecording()
        sendVoiceMessage()
    }
    
    // MARK: - Send Voice Message
    private func sendVoiceMessage() {
        let message = currentTranscript
        guard !message.isEmpty else { return }
        
        isProcessing = true
        
        Task {
            do {
                let result = try await chatRepository.sendMessage(
                    message: message,
                    conversationId: conversationId,
                    model: nil,
                    mode: nil,
                    imageIds: nil,
                    projectId: nil,
                    isVoiceChat: true
                )
                
                await MainActor.run {
                    aiResponse = result.content
                    conversationId = result.conversationId
                    isProcessing = false
                    speakResponse(result.content)
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    isProcessing = false
                    // Resume listening
                    startRecording()
                }
            }
        }
    }
    
    // MARK: - Text-to-Speech
    private func speakResponse(_ text: String) {
        isAISpeaking = true
        
        let utterance = AVSpeechUtterance(string: text)
        
        // Configure voice based on selection
        if let voiceId = selectedVoice?.id {
            if voiceId.contains("en-US") {
                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            } else if voiceId.contains("en-GB") {
                utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
            } else if voiceId.contains("ur-PK") {
                utterance.voice = AVSpeechSynthesisVoice(language: "ur-PK") ?? AVSpeechSynthesisVoice(language: "en-US")
            }
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
    }
    
    // MARK: - Mute Toggle
    func toggleMute() {
        isMuted.toggle()
        
        if isMuted {
            stopRecording()
        } else if currentStep == .activeCall {
            startRecording()
        }
    }
    
    // MARK: - Helpers
    private func calculateAudioLevel(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0 }
        
        let channelDataValue = channelData.pointee
        let channelDataValueArray = stride(from: 0, to: Int(buffer.frameLength), by: buffer.stride)
            .map { channelDataValue[$0] }
        
        let rms = sqrt(channelDataValueArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
        return min(rms * 10, 1.0)
    }
    
    var formattedCallDuration: String {
        let minutes = Int(callDuration) / 60
        let seconds = Int(callDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Voice Mode Step
enum VoiceModeStep {
    case intro
    case voiceSelect
    case activeCall
}

// MARK: - AI Voice Model
struct AIVoice: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let color: Color
    let icon: String
}
