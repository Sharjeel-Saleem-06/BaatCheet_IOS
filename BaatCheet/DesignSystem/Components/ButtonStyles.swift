//
//  ButtonStyles.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import SwiftUI

// MARK: - Primary Button Style
struct BCPrimaryButtonStyle: ButtonStyle {
    var isLoading: Bool = false
    var isDisabled: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.bcButtonLarge)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: BCButtonHeight.large)
            .background(
                RoundedRectangle(cornerRadius: BCCornerRadius.button)
                    .fill(isDisabled ? Color.gray : Color.bcPrimary)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style
struct BCSecondaryButtonStyle: ButtonStyle {
    var isLoading: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.bcButtonLarge)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: BCButtonHeight.large)
            .background(
                RoundedRectangle(cornerRadius: BCCornerRadius.button)
                    .fill(Color.gray.opacity(0.36))
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Outline Button Style
struct BCOutlineButtonStyle: ButtonStyle {
    var borderColor: Color = Color(hex: "38383A")
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.bcButtonLarge)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: BCButtonHeight.large)
            .background(
                RoundedRectangle(cornerRadius: BCCornerRadius.button)
                    .stroke(borderColor, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Icon Button Style
struct BCIconButtonStyle: ButtonStyle {
    var size: CGFloat = 44
    var backgroundColor: Color = Color.gray.opacity(0.1)
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(backgroundColor)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Chip Button Style
struct BCChipButtonStyle: ButtonStyle {
    var isSelected: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.bcLabelLarge)
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, BCSpacing.md)
            .padding(.vertical, BCSpacing.xs)
            .background(
                Capsule()
                    .fill(isSelected ? Color.bcPrimary : Color.gray.opacity(0.1))
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - View Extensions
extension View {
    func bcPrimaryButton(isLoading: Bool = false, isDisabled: Bool = false) -> some View {
        self.buttonStyle(BCPrimaryButtonStyle(isLoading: isLoading, isDisabled: isDisabled))
    }
    
    func bcSecondaryButton(isLoading: Bool = false) -> some View {
        self.buttonStyle(BCSecondaryButtonStyle(isLoading: isLoading))
    }
    
    func bcOutlineButton(borderColor: Color = Color(hex: "38383A")) -> some View {
        self.buttonStyle(BCOutlineButtonStyle(borderColor: borderColor))
    }
    
    func bcIconButton(size: CGFloat = 44, backgroundColor: Color = Color.gray.opacity(0.1)) -> some View {
        self.buttonStyle(BCIconButtonStyle(size: size, backgroundColor: backgroundColor))
    }
    
    func bcChipButton(isSelected: Bool = false) -> some View {
        self.buttonStyle(BCChipButtonStyle(isSelected: isSelected))
    }
}

// MARK: - Loading Button
struct BCLoadingButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: BCSpacing.xs) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
                Text(isLoading ? "Loading..." : title)
            }
        }
        .bcPrimaryButton(isLoading: isLoading, isDisabled: isLoading)
        .disabled(isLoading)
    }
}

// MARK: - Social Sign-In Buttons
struct GoogleSignInButton: View {
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: BCSpacing.xs) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image("ic_google")
                        .resizable()
                        .frame(width: 16, height: 16)
                }
                Text(isLoading ? "Signing in..." : "Continue with Google")
                    .font(.bcButtonLarge)
            }
        }
        .bcSecondaryButton(isLoading: isLoading)
        .disabled(isLoading)
    }
}

struct AppleSignInButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: BCSpacing.xs) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 18))
                Text("Continue with Apple")
                    .font(.bcButtonLarge)
            }
            .foregroundColor(.white)
        }
        .bcSecondaryButton()
    }
}

struct EmailSignUpButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: BCSpacing.xs) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 18))
                Text("Sign up with email")
                    .font(.bcButtonLarge)
            }
            .foregroundColor(.white)
        }
        .bcSecondaryButton()
    }
}
