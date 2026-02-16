//
//  Colors.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import SwiftUI

// MARK: - Brand Colors Extension
extension Color {
    // MARK: - Primary Colors
    /// Primary Blue - #0000F5
    static let bcPrimary = Color(hex: "0000F5")
    
    /// Secondary Mint Green - #7BE8BE
    static let bcSecondary = Color(hex: "7BE8BE")
    
    /// Tertiary Cyan - #9EF8EE
    static let bcTertiary = Color(hex: "9EF8EE")
    
    // MARK: - Background Colors
    static let bcBackgroundLight = Color(hex: "FFFFFF")
    static let bcBackgroundDark = Color(hex: "000000")
    
    static let bcSurfaceLight = Color(hex: "F5F5F5")
    static let bcSurfaceDark = Color(hex: "1C1C1E")
    
    // MARK: - Accent Colors
    static let bcMintGreen = Color(hex: "7BE8BE")
    static let bcCyan = Color(hex: "9EF8EE")
    static let bcBlue = Color(hex: "0000F5")
    
    // MARK: - Text Colors
    static let bcTextPrimary = Color.primary
    static let bcTextSecondary = Color.secondary
    static let bcTextTertiary = Color(hex: "8E8E93")
    
    // MARK: - Status Colors
    static let bcSuccess = Color(hex: "34C759")
    static let bcWarning = Color(hex: "FF9500")
    static let bcError = Color(hex: "FF3B30")
    static let bcInfo = Color(hex: "007AFF")
    
    // MARK: - Voice Chat Colors
    static let vcGreen = Color(hex: "34C759")
    static let vcBlue = Color(hex: "007AFF")
    static let vcPurple = Color(hex: "5856D6")
    static let vcOrange = Color(hex: "FF9500")
    static let vcPink = Color(hex: "FF2D55")
    static let vcIndigo = Color(hex: "6366F1")
    
    // MARK: - Message Bubble Colors
    static let bcUserBubble = Color(hex: "0000F5")
    static let bcAssistantBubble = Color(UIColor.systemGray6)
    
    // MARK: - Carousel Background Colors
    static let carouselMint = Color(hex: "7BE8BE")
    static let carouselCyan = Color(hex: "9EF8EE")
    static let carouselBlue = Color(hex: "0000F5")
    
    // MARK: - Hex Initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Dynamic Colors
extension Color {
    /// Returns the appropriate background color based on color scheme
    static func bcBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? bcBackgroundDark : bcBackgroundLight
    }
    
    /// Returns the appropriate surface color based on color scheme
    static func bcSurface(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? bcSurfaceDark : bcSurfaceLight
    }
    
    /// Returns the appropriate primary color based on color scheme
    static func bcPrimaryAdaptive(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? bcCyan : bcPrimary
    }
}

// MARK: - UIColor Extension
extension UIColor {
    static let bcPrimary = UIColor(Color.bcPrimary)
    static let bcSecondary = UIColor(Color.bcSecondary)
    static let bcTertiary = UIColor(Color.bcTertiary)
}
