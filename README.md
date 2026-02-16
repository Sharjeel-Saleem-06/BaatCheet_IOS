# BaatCheet iOS - باتچیت

<p align="center">
  <img src="https://raw.githubusercontent.com/Sharjeel-Saleem-06/BaatCheet/main/logo.png" alt="BaatCheet Logo" width="120"/>
</p>

<p align="center">
  <strong>🤖 AI-Powered Multilingual Chat Application</strong>
</p>

<p align="center">
  <em>Speech • Chat • Code • Image • Voice • Research</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS%2016%2B-blue?style=flat-square&logo=apple" alt="iOS 16+"/>
  <img src="https://img.shields.io/badge/Swift-5.9-orange?style=flat-square&logo=swift" alt="Swift 5.9"/>
  <img src="https://img.shields.io/badge/SwiftUI-4.0-blue?style=flat-square&logo=swift" alt="SwiftUI"/>
  <img src="https://img.shields.io/badge/Architecture-MVVM%20%2B%20Clean-green?style=flat-square" alt="Architecture"/>
  <img src="https://img.shields.io/badge/License-MIT-yellow?style=flat-square" alt="MIT License"/>
</p>

---

## 🌍 Multilingual Support

**Urdu** | **English** | **Hindi** | **Roman Urdu**

---

## ✨ Features

### 🤖 AI Chat Engine
| Provider | Models | Speed |
|----------|--------|-------|
| **Groq** | Llama 3.3 70B, Llama 3.1 8B Instant, Mixtral 8x7B, Gemma 2 9B | ⚡⚡⚡ |
| **OpenRouter** | Llama 3.1 70B, Gemini 2.0 Flash, Mistral 7B | ⚡⚡ |
| **DeepSeek** | DeepSeek Chat, DeepSeek Coder | ⚡⚡ |
| **Gemini** | Gemini 2.5 Flash | ⚡⚡⚡ |

### 🎯 7 Specialized AI Modes
- **💬 Chat** - Natural multilingual conversations
- **💻 Code** - Write, debug, explain code
- **🔍 Research** - Web search with citations
- **🎨 Image Gen** - Create images from text
- **📚 Tutor** - Interactive learning assistant
- **✍️ Creative** - Stories, poems, scripts
- **🧮 Math** - Step-by-step solutions

### 🎙️ Voice & Language
- **Speech Recognition** - Urdu, English, Hindi, Roman Urdu
- **Text-to-Speech Voices**:
  - 🇵🇰 **Urdu**: Asad (Male), Uzma (Female)
  - 🇺🇸 **English**: Guy (Male), Jenny (Female)

### 📸 Vision & Image AI
| Feature | Description |
|---------|-------------|
| **Image Analysis** | Gemini-powered analysis |
| **OCR** | 60+ Languages support |
| **Image Generation** | FLUX, Stable Diffusion XL |
| **Document Scanning** | PDF, Images |

### 👥 Team Collaboration
- **Projects** - Create unlimited projects
- **Invite** - Via email with role assignment
- **Team Chat** - Real-time messaging
- **Roles**: Admin, Moderator, Viewer

### 📊 Usage Analytics
- **Free Daily Limits**: 50 Messages, 10 Image Gens, 10 Voice Messages
- **Resets every 24 hours**
- **No credit card required**

---

## 🏗️ Architecture

```
📦 BaatCheet iOS
├── 📂 App/                          # App entry point
│   ├── BaatCheetApp.swift           # Main app
│   ├── RootView.swift               # Root view controller
│   └── DeepLinkHandler.swift        # Deep link handling
│
├── 📂 Core/                         # Core utilities
│   ├── DI/
│   │   └── DependencyContainer.swift
│   ├── Extensions/
│   │   ├── View+Extensions.swift
│   │   ├── String+Extensions.swift
│   │   └── Date+Extensions.swift
│   └── Utilities/
│       └── KeychainHelper.swift
│
├── 📂 Data/                         # Data Layer
│   ├── Network/
│   │   ├── APIClient.swift          # Network client
│   │   ├── APIConfig.swift          # Endpoints config
│   │   └── DTOs/                    # Data Transfer Objects
│   └── Repositories/                # Repository implementations
│
├── 📂 Domain/                       # Domain Layer
│   ├── Models/                      # Business models
│   ├── Repositories/                # Repository protocols
│   └── UseCases/                    # Use case implementations
│
├── 📂 Presentation/                 # UI Layer
│   ├── Splash/
│   ├── Login/
│   ├── EmailAuth/
│   ├── Chat/
│   ├── Conversations/
│   ├── Projects/
│   ├── VoiceChat/
│   └── Settings/
│
├── 📂 DesignSystem/                 # Design tokens
│   ├── Colors/
│   ├── Typography/
│   └── Components/
│
└── 📂 Resources/
    └── Info.plist
```

### MVVM + Clean Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │
│  │   SwiftUI   │ -> │  ViewModel  │ -> │   UseCase   │  │
│  │    Views    │    │  @Published │    │   Protocol  │  │
│  └─────────────┘    └─────────────┘    └─────────────┘  │
└─────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────┐
│                      Domain Layer                        │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │
│  │   Models    │    │ Repository  │    │  Use Cases  │  │
│  │   (Pure)    │    │  Protocols  │    │   (Logic)   │  │
│  └─────────────┘    └─────────────┘    └─────────────┘  │
└─────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────┐
│                       Data Layer                         │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │
│  │  APIClient  │    │ Repository  │    │  Keychain   │  │
│  │  (Network)  │    │    Impl     │    │   Helper    │  │
│  └─────────────┘    └─────────────┘    └─────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## 🛠️ Technology Stack

| Category | Technology |
|----------|------------|
| **Language** | Swift 5.9 |
| **UI Framework** | SwiftUI |
| **Architecture** | MVVM + Clean Architecture |
| **Dependency Injection** | Manual (DependencyContainer) |
| **Networking** | URLSession + async/await |
| **Local Storage** | Keychain + UserDefaults |
| **Authentication** | Email, Google Sign-In, Apple Sign-In |
| **Speech** | Speech Framework (SFSpeechRecognizer) |
| **TTS** | AVFoundation (AVSpeechSynthesizer) |
| **Navigation** | NavigationStack (iOS 16+) |

---

## 📋 Prerequisites

| Requirement | Version |
|-------------|---------|
| **Xcode** | 15.0+ |
| **iOS** | 16.0+ |
| **macOS** | Ventura 13.0+ |
| **Swift** | 5.9+ |

---

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/Sharjeel-Saleem-06/BaatCheet_IOS.git
cd BaatCheet_IOS
```

### 2. Open in Xcode

#### Option A: Using Existing Xcode Project
```bash
open ios/iOSBaseProject.xcodeproj
```

#### Option B: Create New Xcode Project (Recommended)
1. Open Xcode
2. File → New → Project
3. Select **iOS → App**
4. Configure:
   - **Product Name**: BaatCheet
   - **Bundle Identifier**: `com.baatcheet.app`
   - **Interface**: SwiftUI
   - **Language**: Swift
5. Save in the cloned directory
6. **Drag the `BaatCheet` folder** into the Xcode project navigator
7. Select "Copy items if needed" and "Create groups"

### 3. Configure Signing

1. Select the project in navigator
2. Go to **Signing & Capabilities**
3. Select your Team
4. Update Bundle Identifier if needed: `com.yourdomain.baatcheet`

### 4. Add Capabilities

Add the following capabilities:
- **Sign in with Apple**
- **Keychain Sharing** (optional, for shared credentials)

### 5. Configure Google Sign-In (Optional)

1. Add GoogleSignIn package:
   - File → Add Package Dependencies
   - URL: `https://github.com/google/GoogleSignIn-iOS`
2. Add `GOOGLE_CLIENT_ID` to Info.plist
3. Configure URL scheme: `com.googleusercontent.apps.YOUR_CLIENT_ID`

### 6. Add Image Assets

1. Open Assets.xcassets
2. Add `login_image` (for splash/login background)
3. Add `AppIcon` (1024x1024)

### 7. Run the App

1. Select a simulator or connected device
2. Click **Run** (⌘R)

---

## 🔑 API Endpoints

The app connects to: `https://sharry121-baatcheet.hf.space/api/v1`

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/mobile/auth/signin` | Email sign-in |
| POST | `/mobile/auth/signup` | Email sign-up |
| POST | `/mobile/auth/verify-email` | Verify email |
| POST | `/auth/google` | Google Sign-In |
| POST | `/auth/apple` | Apple Sign-In |

### Chat
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/chat/completions` | Send message (SSE) |
| GET | `/chat/modes` | Get AI modes |
| GET | `/chat/usage` | Get usage stats |

### Conversations
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/conversations` | List conversations |
| POST | `/conversations` | Create conversation |
| DELETE | `/conversations/:id` | Delete conversation |

### Projects
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/projects` | List projects |
| POST | `/projects` | Create project |
| POST | `/projects/:id/invite` | Invite collaborator |

---

## 📁 Project Structure Details

### Entry Point
- **BaatCheetApp.swift**: App lifecycle, DI setup
- **RootView.swift**: Navigation between auth/main screens
- **DeepLinkHandler.swift**: Universal links handling

### Design System
- **Colors.swift**: Brand colors, semantic colors
- **Typography.swift**: Font definitions
- **ButtonStyles.swift**: Reusable button styles

### ViewModels
- **AuthViewModel**: Authentication state management
- **ChatViewModel**: Chat interactions, messages
- **ProjectsViewModel**: Project management
- **VoiceChatViewModel**: Voice chat with speech recognition

---

## 🔗 Deep Linking

### Custom URL Scheme
```
baatcheet://conversation/{id}
baatcheet://shared/{shareId}
baatcheet://project/{projectId}
```

### Universal Links
```
https://baatcheet-web.netlify.app/shared/{shareId}
```

---

## 🎨 Brand Colors

| Color | Hex | Usage |
|-------|-----|-------|
| Primary | `#1e293b` | Backgrounds, primary elements |
| Secondary | `#64748b` | Secondary text, icons |
| Accent Blue | `#3b82f6` | Links, interactive elements |
| Accent Green | `#22c55e` | Success states |
| Accent Red | `#ef4444` | Error states |

---

## 🧪 Testing

```bash
# Run unit tests
xcodebuild test -project BaatCheet.xcodeproj -scheme BaatCheet -destination 'platform=iOS Simulator,name=iPhone 15'
```

---

## 📱 App Information

| Property | Value |
|----------|-------|
| **Bundle ID** | com.baatcheet.app |
| **Min iOS** | 16.0 |
| **Orientation** | Portrait |
| **Dark Mode** | Supported |

---

## 🔄 Related Repositories

| Platform | Repository |
|----------|------------|
| 🌐 **Main (Backend + Web)** | [BaatCheet](https://github.com/Sharjeel-Saleem-06/BaatCheet) |
| 📱 **Android** | [BaatCheet_Android](https://github.com/Sharjeel-Saleem-06/BaatCheet_Android) |
| 🍎 **iOS** | [BaatCheet_IOS](https://github.com/Sharjeel-Saleem-06/BaatCheet_IOS) |

---

## 👨‍💻 Developer

<p align="center">
  <strong>Muhammad Sharjeel</strong><br/>
  <em>Full-Stack Developer • Mobile Developer • AI Enthusiast</em>
</p>

<p align="center">
  <a href="https://github.com/Sharjeel-Saleem-06">GitHub</a> •
  <a href="https://linkedin.com/in/sharjeel-saleem">LinkedIn</a>
</p>

---

## 📄 License

```
MIT License

Copyright (c) 2026 Muhammad Sharjeel

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
```

---

<p align="center">
  Made with ❤️ in Pakistan
</p>
