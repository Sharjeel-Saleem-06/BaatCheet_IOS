//
//  Typography.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import SwiftUI

// MARK: - Typography Extension
extension Font {
    // MARK: - Headings
    /// Large Title - 34pt Bold
    static let bcLargeTitle = Font.system(size: 34, weight: .bold, design: .default)
    
    /// Title 1 - 28pt Semibold
    static let bcTitle1 = Font.system(size: 28, weight: .semibold, design: .default)
    
    /// Title 2 - 22pt Semibold
    static let bcTitle2 = Font.system(size: 22, weight: .semibold, design: .default)
    
    /// Title 3 - 20pt Semibold
    static let bcTitle3 = Font.system(size: 20, weight: .semibold, design: .default)
    
    // MARK: - Body
    /// Body Large - 17pt Regular
    static let bcBodyLarge = Font.system(size: 17, weight: .regular, design: .default)
    
    /// Body - 15pt Regular
    static let bcBody = Font.system(size: 15, weight: .regular, design: .default)
    
    /// Body Medium - 15pt Medium
    static let bcBodyMedium = Font.system(size: 15, weight: .medium, design: .default)
    
    // MARK: - Labels
    /// Label Large - 14pt Medium
    static let bcLabelLarge = Font.system(size: 14, weight: .medium, design: .default)
    
    /// Label - 13pt Regular
    static let bcLabel = Font.system(size: 13, weight: .regular, design: .default)
    
    /// Label Small - 12pt Regular
    static let bcLabelSmall = Font.system(size: 12, weight: .regular, design: .default)
    
    // MARK: - Captions
    /// Caption - 11pt Regular
    static let bcCaption = Font.system(size: 11, weight: .regular, design: .default)
    
    /// Caption Medium - 11pt Medium
    static let bcCaptionMedium = Font.system(size: 11, weight: .medium, design: .default)
    
    // MARK: - Buttons
    /// Button Large - 20pt Medium
    static let bcButtonLarge = Font.system(size: 20, weight: .medium, design: .default)
    
    /// Button - 17pt Semibold
    static let bcButton = Font.system(size: 17, weight: .semibold, design: .default)
    
    /// Button Small - 14pt Medium
    static let bcButtonSmall = Font.system(size: 14, weight: .medium, design: .default)
    
    // MARK: - Special
    /// Code - 14pt Monospaced
    static let bcCode = Font.system(size: 14, weight: .regular, design: .monospaced)
    
    /// Typewriter - 34pt Medium (for login carousel)
    static let bcTypewriter = Font.system(size: 34, weight: .medium, design: .default)
}

// MARK: - Text Styles
struct BCTextStyle: ViewModifier {
    let font: Font
    let color: Color
    let lineSpacing: CGFloat
    
    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundColor(color)
            .lineSpacing(lineSpacing)
    }
}

extension View {
    func bcTextStyle(_ font: Font, color: Color = .primary, lineSpacing: CGFloat = 0) -> some View {
        modifier(BCTextStyle(font: font, color: color, lineSpacing: lineSpacing))
    }
}

// MARK: - Text Extensions
extension Text {
    func bcLargeTitle() -> Text {
        self.font(.bcLargeTitle)
    }
    
    func bcTitle1() -> Text {
        self.font(.bcTitle1)
    }
    
    func bcTitle2() -> Text {
        self.font(.bcTitle2)
    }
    
    func bcBody() -> Text {
        self.font(.bcBody)
    }
    
    func bcCaption() -> Text {
        self.font(.bcCaption)
    }
    
    func bcButton() -> Text {
        self.font(.bcButton)
    }
}
