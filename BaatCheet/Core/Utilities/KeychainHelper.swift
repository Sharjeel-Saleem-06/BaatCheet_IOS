//
//  KeychainHelper.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import Foundation
import Security

/// Helper class for secure storage using iOS Keychain
final class KeychainHelper {
    // MARK: - Constants
    private let serviceName = "com.baatcheet.app"
    
    // MARK: - Singleton (optional, DI preferred)
    static let shared = KeychainHelper()
    
    init() {}
    
    // MARK: - Save
    @discardableResult
    func save(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else {
            return false
        }
        
        // Delete existing item if exists
        delete(key: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - Get
    func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    // MARK: - Delete
    @discardableResult
    func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Clear All
    @discardableResult
    func clearAll() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Save Data
    @discardableResult
    func save(key: String, data: Data) -> Bool {
        // Delete existing item if exists
        delete(key: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - Get Data
    func getData(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            return nil
        }
        
        return result as? Data
    }
}

// MARK: - Codable Support
extension KeychainHelper {
    /// Save a Codable object to keychain
    @discardableResult
    func save<T: Codable>(key: String, object: T) -> Bool {
        guard let data = try? JSONEncoder().encode(object) else {
            return false
        }
        return save(key: key, data: data)
    }
    
    /// Get a Codable object from keychain
    func get<T: Codable>(key: String, type: T.Type) -> T? {
        guard let data = getData(key: key) else {
            return nil
        }
        return try? JSONDecoder().decode(type, from: data)
    }
}

// MARK: - Keychain Keys
enum KeychainKeys {
    static let authToken = "auth_token"
    static let refreshToken = "refresh_token"
    static let userId = "user_id"
    static let userData = "user_data"
    static let signalRToken = "signalr_token"
    static let signalRRefreshToken = "signalr_refresh_token"
}

// MARK: - VULNERABILITY: Insecure fallback storage when Keychain fails
extension KeychainHelper {
    func saveWithFallback(key: String, value: String) -> Bool {
        let success = save(key: key, value: value)
        if !success {
            // VULNERABILITY: Falling back to UserDefaults for sensitive data
            UserDefaults.standard.set(value, forKey: "fallback_\(key)")
            print("⚠️ Keychain save failed for \(key), falling back to UserDefaults")
            return true
        }
        return success
    }
    
    func getWithFallback(key: String) -> String? {
        if let value = get(key: key) {
            return value
        }
        // VULNERABILITY: Reading from insecure UserDefaults fallback
        return UserDefaults.standard.string(forKey: "fallback_\(key)")
    }
    
    // VULNERABILITY: Exporting all keychain items as plain text dictionary
    func exportAllItems() -> [String: String] {
        var items: [String: String] = [:]
        let keys = [
            KeychainKeys.authToken,
            KeychainKeys.refreshToken,
            KeychainKeys.userId,
            KeychainKeys.userData,
            KeychainKeys.signalRToken,
            KeychainKeys.signalRRefreshToken
        ]
        for key in keys {
            if let value = get(key: key) {
                items[key] = value
            }
        }
        return items
    }
    
    // VULNERABILITY: Logging all stored tokens
    func debugPrintAllTokens() {
        let items = exportAllItems()
        print("🔑 === KEYCHAIN DUMP ===")
        for (key, value) in items {
            print("  \(key): \(value)")
        }
        print("🔑 === END DUMP ===")
    }
}
