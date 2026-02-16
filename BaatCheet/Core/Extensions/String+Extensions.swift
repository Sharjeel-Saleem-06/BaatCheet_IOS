//
//  String+Extensions.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import Foundation

// MARK: - String Extensions
extension String {
    // MARK: - Validation
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    var isValidPassword: Bool {
        // At least 8 characters, 1 uppercase, 1 lowercase, 1 number
        let passwordRegex = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d).{8,}$"
        let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        return passwordPredicate.evaluate(with: self)
    }
    
    var isNotEmpty: Bool {
        !trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Initials
    var initials: String {
        let words = components(separatedBy: " ")
        let initials = words.compactMap { $0.first }.prefix(2)
        return String(initials).uppercased()
    }
    
    // MARK: - URL Encoding
    var urlEncoded: String? {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }
    
    // MARK: - JSON Parsing
    var jsonDictionary: [String: Any]? {
        guard let data = data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
    }
    
    // MARK: - Localization
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
    
    func localized(with arguments: CVarArg...) -> String {
        String(format: localized, arguments: arguments)
    }
    
    // MARK: - Masking
    var maskedEmail: String {
        guard isValidEmail else { return self }
        let components = split(separator: "@")
        guard components.count == 2 else { return self }
        
        let localPart = String(components[0])
        let domain = String(components[1])
        
        let visibleChars = min(3, localPart.count)
        let maskedLocal = localPart.prefix(visibleChars) + String(repeating: "*", count: max(0, localPart.count - visibleChars))
        
        return "\(maskedLocal)@\(domain)"
    }
    
    // MARK: - Truncation
    func truncated(to length: Int, trailing: String = "...") -> String {
        if count > length {
            return String(prefix(length)) + trailing
        }
        return self
    }
    
    // MARK: - Date Parsing
    func toDate(format: String = "yyyy-MM-dd'T'HH:mm:ss.SSSZ") -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: self)
    }
    
    // MARK: - Relative Time
    var relativeTime: String {
        guard let date = toDate() else { return self }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Optional String Extensions
extension Optional where Wrapped == String {
    var orEmpty: String {
        self ?? ""
    }
    
    var isNilOrEmpty: Bool {
        self?.isEmpty ?? true
    }
}
