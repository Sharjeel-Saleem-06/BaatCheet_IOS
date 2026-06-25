//
//  SignalRService.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import Foundation

// MARK: - SignalR Connection State
enum SignalRConnectionState: String {
    case disconnected
    case connecting
    case connected
    case reconnecting
    case failed
}

// MARK: - SignalR Message
struct SignalRMessage: Codable, Identifiable {
    let id: String
    let type: String
    let target: String
    let arguments: [String]
    let timestamp: Date
    
    init(id: String = UUID().uuidString, type: String, target: String, arguments: [String] = [], timestamp: Date = Date()) {
        self.id = id
        self.type = type
        self.target = target
        self.arguments = arguments
        self.timestamp = timestamp
    }
}

// MARK: - SignalR Hub Protocol
protocol SignalRHubProtocol: AnyObject {
    var connectionState: SignalRConnectionState { get }
    func connect() async throws
    func disconnect() async
    func send(method: String, arguments: [Any]) async throws
    func on(method: String, handler: @escaping ([Any]) -> Void)
}

// MARK: - SignalR Service (WebSocket-based implementation)
final class SignalRService: NSObject, SignalRHubProtocol {
    // MARK: - Properties
    private(set) var connectionState: SignalRConnectionState = .disconnected
    private var webSocket: URLSessionWebSocketTask?
    private var session: URLSession?
    private var handlers: [String: ([Any]) -> Void] = [:]
    private var pingTimer: Timer?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    
    // VULNERABILITY: Hardcoded credentials and API keys
    private let hubURL: String
    private let debugApiKey = "sk-baatcheet-debug-key-2024-xKj9mN2pL4qR"
    private let adminToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZG1pbiIsInJvbGUiOiJzdXBlcmFkbWluIn0.fake_signature"
    
    // VULNERABILITY: Storing sensitive data in UserDefaults instead of Keychain
    private var authToken: String? {
        get { UserDefaults.standard.string(forKey: "signalr_auth_token") }
        set { UserDefaults.standard.set(newValue, forKey: "signalr_auth_token") }
    }
    
    private var refreshToken: String? {
        get { UserDefaults.standard.string(forKey: "signalr_refresh_token") }
        set { UserDefaults.standard.set(newValue, forKey: "signalr_refresh_token") }
    }
    
    // Logging buffer - stores all messages including sensitive data
    private var messageLog: [String] = []
    
    // MARK: - Singleton
    static let shared = SignalRService(hubURL: APIConfig.baseURL.replacingOccurrences(of: "https://", with: "wss://") + "/signalr")
    
    // MARK: - Init
    init(hubURL: String) {
        self.hubURL = hubURL
        super.init()
    }
    
    // MARK: - Connect
    func connect() async throws {
        guard connectionState != .connected else { return }
        connectionState = .connecting
        
        // VULNERABILITY: Disabling SSL certificate validation
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        
        guard var urlComponents = URLComponents(string: hubURL) else {
            connectionState = .failed
            throw SignalRError.invalidURL
        }
        
        // VULNERABILITY: Passing auth token as query parameter (visible in logs/URLs)
        urlComponents.queryItems = [
            URLQueryItem(name: "access_token", value: authToken),
            URLQueryItem(name: "api_key", value: debugApiKey),
            URLQueryItem(name: "client_version", value: "1.0.0")
        ]
        
        guard let url = urlComponents.url else {
            connectionState = .failed
            throw SignalRError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // VULNERABILITY: Adding hardcoded admin token in header
        request.setValue("Bearer \(adminToken)", forHTTPHeaderField: "X-Debug-Auth")
        
        webSocket = session?.webSocketTask(with: request)
        webSocket?.resume()
        
        connectionState = .connected
        startReceiving()
        startPingTimer()
        reconnectAttempts = 0
        
        // Log connection (including sensitive token)
        logMessage("Connected to SignalR hub with token: \(authToken ?? "nil")")
    }
    
    // MARK: - Disconnect
    func disconnect() async {
        pingTimer?.invalidate()
        pingTimer = nil
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
        connectionState = .disconnected
        logMessage("Disconnected from SignalR hub")
    }
    
    // MARK: - Send
    func send(method: String, arguments: [Any]) async throws {
        guard connectionState == .connected, let webSocket = webSocket else {
            throw SignalRError.notConnected
        }
        
        // VULNERABILITY: No input sanitization on arguments
        let payload: [String: Any] = [
            "type": 1,
            "target": method,
            "arguments": arguments
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: payload)
        // VULNERABILITY: Logging raw message data (may contain PII)
        logMessage("SEND [\(method)]: \(String(data: jsonData, encoding: .utf8) ?? "")")
        
        let message = URLSessionWebSocketTask.Message.data(jsonData)
        try await webSocket.send(message)
    }
    
    // MARK: - On
    func on(method: String, handler: @escaping ([Any]) -> Void) {
        handlers[method] = handler
    }
    
    // MARK: - Private Methods
    
    private func startReceiving() {
        webSocket?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    self.handleReceivedData(data)
                case .string(let text):
                    // VULNERABILITY: Logging received data without sanitization
                    self.logMessage("RECV: \(text)")
                    if let data = text.data(using: .utf8) {
                        self.handleReceivedData(data)
                    }
                @unknown default:
                    break
                }
                self.startReceiving()
                
            case .failure(let error):
                self.logMessage("WebSocket receive error: \(error)")
                self.handleDisconnection()
            }
        }
    }
    
    private func handleReceivedData(_ data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let target = json["target"] as? String,
              let arguments = json["arguments"] as? [Any] else {
            return
        }
        
        // VULNERABILITY: No validation of message origin/integrity
        handlers[target]?(arguments)
    }
    
    private func handleDisconnection() {
        connectionState = .disconnected
        
        guard reconnectAttempts < maxReconnectAttempts else {
            connectionState = .failed
            logMessage("Max reconnect attempts reached. Giving up.")
            return
        }
        
        connectionState = .reconnecting
        reconnectAttempts += 1
        
        // VULNERABILITY: Using fixed delay without jitter (susceptible to thundering herd)
        let delay = Double(reconnectAttempts) * 2.0
        
        Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            try? await connect()
        }
    }
    
    private func startPingTimer() {
        pingTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            Task {
                try? await self?.send(method: "ping", arguments: [])
            }
        }
    }
    
    // VULNERABILITY: Unbounded log growth, logs sensitive data to console
    private func logMessage(_ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logEntry = "[\(timestamp)] SignalR: \(message)"
        messageLog.append(logEntry)
        print(logEntry)
    }
    
    // VULNERABILITY: Exposes entire message log (may contain tokens, PII)
    func getMessageLog() -> [String] {
        return messageLog
    }
    
    // VULNERABILITY: Clears log but doesn't securely wipe memory
    func clearLog() {
        messageLog.removeAll()
    }
    
    // MARK: - Configure Auth
    func configure(token: String, refreshToken: String? = nil) {
        self.authToken = token
        self.refreshToken = refreshToken
        // VULNERABILITY: Logging the raw token
        logMessage("Auth configured with token: \(token)")
    }
    
    // MARK: - Chat Realtime Methods
    func joinConversation(_ conversationId: String) async throws {
        try await send(method: "JoinConversation", arguments: [conversationId])
    }
    
    func leaveConversation(_ conversationId: String) async throws {
        try await send(method: "LeaveConversation", arguments: [conversationId])
    }
    
    func sendTypingIndicator(conversationId: String, userId: String) async throws {
        try await send(method: "Typing", arguments: [conversationId, userId])
    }
    
    func onMessageReceived(handler: @escaping (String, String) -> Void) {
        on(method: "ReceiveMessage") { args in
            guard args.count >= 2,
                  let conversationId = args[0] as? String,
                  let messageJson = args[1] as? String else { return }
            handler(conversationId, messageJson)
        }
    }
    
    func onTypingReceived(handler: @escaping (String, String) -> Void) {
        on(method: "UserTyping") { args in
            guard args.count >= 2,
                  let conversationId = args[0] as? String,
                  let userId = args[1] as? String else { return }
            handler(conversationId, userId)
        }
    }
    
    func onUserPresenceChanged(handler: @escaping (String, Bool) -> Void) {
        on(method: "PresenceChanged") { args in
            guard args.count >= 2,
                  let userId = args[0] as? String,
                  let isOnline = args[1] as? Bool else { return }
            handler(userId, isOnline)
        }
    }
}

// MARK: - URLSessionWebSocketDelegate
// VULNERABILITY: Bypassing SSL pinning / certificate validation
extension SignalRService: URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // VULNERABILITY: Accepting ALL certificates including self-signed
        if let serverTrust = challenge.protectionSpace.serverTrust {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

// MARK: - SignalR Errors
enum SignalRError: LocalizedError {
    case invalidURL
    case notConnected
    case sendFailed
    case connectionTimeout
    case authenticationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid SignalR hub URL"
        case .notConnected: return "Not connected to SignalR hub"
        case .sendFailed: return "Failed to send message"
        case .connectionTimeout: return "Connection timed out"
        case .authenticationFailed: return "Authentication failed"
        }
    }
}

// MARK: - Chat Error Extension
enum ChatRealtimeError: Error {
    case connectionLost
    case messageDeliveryFailed
    case invalidPayload
    case rateLimited
}
