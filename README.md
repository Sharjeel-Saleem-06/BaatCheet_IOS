# BaatCheet iOS

<p align="center">
  <img src="https://raw.githubusercontent.com/Sharjeel-Saleem-06/BaatCheet/main/logo.png" alt="BaatCheet Logo" width="140"/>
</p>

<p align="center">
  <strong>AI-Powered Multilingual Chat Application for iOS</strong>
</p>

<p align="center">
  <em>Chat &bull; Code &bull; Research &bull; Image &bull; Voice &bull; Collaborate</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS%2016%2B-000?style=flat-square&logo=apple&logoColor=white" alt="iOS 16+"/>
  <img src="https://img.shields.io/badge/Swift-5.9-F05138?style=flat-square&logo=swift&logoColor=white" alt="Swift 5.9"/>
  <img src="https://img.shields.io/badge/SwiftUI-4.0-007AFF?style=flat-square&logo=swift&logoColor=white" alt="SwiftUI"/>
  <img src="https://img.shields.io/badge/Arch-MVVM%20%2B%20Clean-34C759?style=flat-square" alt="Architecture"/>
  <img src="https://img.shields.io/badge/License-MIT-F5C518?style=flat-square" alt="MIT License"/>
</p>

<p align="center">
  <a href="https://baatcheet-web.netlify.app">Web App</a> &bull;
  <a href="https://github.com/Sharjeel-Saleem-06/BaatCheet">Backend</a> &bull;
  <a href="https://github.com/Sharjeel-Saleem-06/BaatCheet_Android">Android</a>
</p>

---

## About

BaatCheet iOS is the native iPhone/iPad client for the BaatCheet AI platform. It delivers the same feature set as the Android and Web versions, built from the ground up with SwiftUI, MVVM + Clean Architecture, and real-time streaming. Every API call, every screen, and every interaction matches the existing ecosystem.

---

## Features

### Multi-Provider AI Engine

| Provider | Models | Speed |
|----------|--------|-------|
| **Groq** | Llama 3.3 70B, Llama 3.1 8B, Mixtral 8x7B, Gemma 2 9B | Ultra-fast |
| **OpenRouter** | Llama 3.1 70B, Gemini 2.0 Flash, Mistral 7B | Fast |
| **DeepSeek** | DeepSeek Chat, DeepSeek Coder | Fast |
| **Gemini** | Gemini 2.5 Flash | Ultra-fast |
| **HuggingFace** | FLUX, Stable Diffusion XL (image gen) | Moderate |

### 7 Specialized AI Modes

- **Chat** &mdash; Natural multilingual conversations (Urdu, English, Hindi, Roman Urdu)
- **Code** &mdash; Write, debug, and explain code in 30+ languages
- **Research** &mdash; Web search with citations and source links
- **Image Gen** &mdash; Create images from text prompts
- **Tutor** &mdash; Interactive learning assistant with step-by-step explanations
- **Creative** &mdash; Stories, poems, scripts, and creative writing
- **Math** &mdash; Step-by-step mathematical solutions

### Production-Grade Markdown Renderer

The chat experience features a custom markdown renderer comparable to ChatGPT and Gemini:

- **Rich text** &mdash; Bold, italic, bold-italic, strikethrough, inline code, links
- **Code blocks** &mdash; Dark theme with syntax highlighting for 20+ languages, line numbers, copy-to-clipboard, collapse/expand for long blocks
- **Tables** &mdash; Dynamic column widths, horizontal scroll, alternating row colors, green accent headers
- **Lists** &mdash; Bullet and numbered lists with colored markers
- **Blockquotes** &mdash; Styled with green accent border
- **Citations** &mdash; Superscript-styled reference numbers
- **Performance** &mdash; Short-circuits for simple text, truncation for very long content

### Voice & Speech

| Feature | Technology |
|---------|------------|
| **Speech-to-Text** | `SFSpeechRecognizer` &mdash; Urdu, English, Hindi |
| **Text-to-Speech** | `AVSpeechSynthesizer` with voice selection |
| **Voice Chat** | Full-screen voice interaction with real-time transcription |

### Vision & Image AI

| Feature | Description |
|---------|-------------|
| **Image Analysis** | Gemini-powered visual understanding |
| **OCR** | 60+ language document scanning |
| **Image Generation** | FLUX, Stable Diffusion XL via HuggingFace |
| **File Attachments** | PDF, images, documents |

### Team Collaboration

- **Projects** &mdash; Create and manage unlimited AI projects
- **AI Chat** &mdash; Per-project AI conversations with context
- **Team Chat** &mdash; Real-time messaging with image support, message actions (copy, reply, delete)
- **Invitations** &mdash; Invite collaborators via email with role assignment
- **Roles** &mdash; Owner, Admin, Moderator, Viewer with granular permissions
- **Settings** &mdash; Project name, description, context, content controls, permissions

### Additional Features

- **Conversation Management** &mdash; Create, rename, pin, archive, delete conversations
- **Side Drawer** &mdash; Hamburger menu with recent conversations (20 loaded, "View All" pagination)
- **Share Chat** &mdash; Generate shareable links for any conversation
- **Deep Linking** &mdash; Open conversations and shared chats via URL
- **Full-Screen Image Viewer** &mdash; Pinch-to-zoom, double-tap zoom, download to Photos
- **Dark Mode** &mdash; Full system dark mode support
- **Session Management** &mdash; Auto-detect expired sessions with login redirect
- **In-App Browser** &mdash; `SFSafariViewController` for Terms, Privacy, Contact

---

## Architecture

```
BaatCheet/
├── App/                             # App lifecycle & navigation
│   ├── BaatCheetApp.swift          # Entry point & dependency setup
│   ├── RootView.swift              # Auth flow, main drawer, navigation
│   └── DeepLinkHandler.swift       # Universal links & URL schemes
│
├── Core/                            # Shared utilities
│   ├── DI/DependencyContainer.swift
│   ├── Extensions/                 # View, String, Date extensions
│   └── Utilities/KeychainHelper.swift
│
├── Data/                            # Data layer
│   ├── Network/
│   │   ├── APIClient.swift         # URLSession async/await + SSE streaming
│   │   ├── APIConfig.swift         # Endpoint definitions
│   │   └── DTOs/                   # Decodable response models
│   └── Repositories/               # Repository implementations
│
├── Domain/                          # Pure business logic (no iOS imports)
│   ├── Models/                     # User, Conversation, Project, Message
│   ├── Repositories/               # Repository protocols
│   └── UseCases/                   # Business rules
│
├── Presentation/                    # SwiftUI views & ViewModels
│   ├── Splash/                     # Launch screen
│   ├── Login/                      # Google Sign-In + Email auth
│   ├── EmailAuth/                  # Signup, verification, forgot password
│   ├── Chat/                       # Chat UI, message bubbles, markdown
│   ├── Conversations/              # Conversation list & management
│   ├── Projects/                   # Projects, team chat, settings
│   ├── VoiceChat/                  # Voice interaction screen
│   ├── Settings/                   # User settings, profile, legal
│   └── Components/                 # Reusable: MarkdownTextView, etc.
│
├── DesignSystem/                    # Design tokens
│   ├── Colors.swift                # Brand & semantic colors
│   ├── Typography.swift            # Font system
│   └── ButtonStyles.swift          # Reusable button styles
│
└── Resources/
    ├── Info.plist                   # App config, URL schemes
    └── Assets.xcassets             # App icon, images
```

### MVVM + Clean Architecture

```
┌──────────────────────────────────────────────────────────┐
│                    Presentation Layer                      │
│  ┌──────────┐    ┌──────────────┐    ┌────────────────┐  │
│  │ SwiftUI  │───>│  ViewModel   │───>│    UseCase     │  │
│  │  Views   │    │  @Published  │    │   (Protocol)   │  │
│  └──────────┘    └──────────────┘    └────────────────┘  │
└──────────────────────────────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────┐
│                      Domain Layer                         │
│  ┌──────────┐    ┌──────────────┐    ┌────────────────┐  │
│  │  Models  │    │  Repository  │    │   Use Cases    │  │
│  │  (Pure)  │    │  Protocols   │    │   (Logic)      │  │
│  └──────────┘    └──────────────┘    └────────────────┘  │
└──────────────────────────────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────┐
│                       Data Layer                          │
│  ┌──────────┐    ┌──────────────┐    ┌────────────────┐  │
│  │APIClient │    │  Repository  │    │   Keychain     │  │
│  │(Network) │    │    Impl      │    │   Helper       │  │
│  └──────────┘    └──────────────┘    └────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

---

## Tech Stack

| Category | Technology |
|----------|------------|
| **Language** | Swift 5.9 |
| **UI** | SwiftUI 4.0 |
| **Architecture** | MVVM + Clean Architecture |
| **DI** | Manual DependencyContainer |
| **Networking** | URLSession + async/await + SSE |
| **Storage** | Keychain (tokens) + UserDefaults (prefs) |
| **Auth** | Email/Password + Google Sign-In SDK |
| **Speech** | SFSpeechRecognizer + AVSpeechSynthesizer |
| **Navigation** | NavigationStack (iOS 16+) |
| **Markdown** | Custom SwiftUI renderer with syntax highlighting |
| **Images** | AsyncImage + PhotosPicker |

---

## Prerequisites

| Requirement | Version |
|-------------|---------|
| **Xcode** | 15.0+ |
| **iOS** | 16.0+ |
| **macOS** | Ventura 13.0+ |
| **Swift** | 5.9+ |

---

## Getting Started

### 1. Clone

```bash
git clone https://github.com/Sharjeel-Saleem-06/BaatCheet_IOS.git
cd BaatCheet_IOS
```

### 2. Open in Xcode

```bash
open BaatCheet.xcodeproj
```

### 3. Configure Signing

1. Select the **BaatCheet** project in the navigator
2. Go to **Signing & Capabilities**
3. Select your Apple Developer Team
4. Update **Bundle Identifier** to `com.yourdomain.baatcheet`

### 4. Configure Google Sign-In

The project uses Google Sign-In SDK. To set up:

1. The GoogleSignIn package is already included via SPM
2. Ensure `Info.plist` contains the correct `GIDClientID`
3. URL scheme `com.googleusercontent.apps.YOUR_CLIENT_ID` is configured

### 5. Run

1. Select **iPhone 15** (or any iOS 16+ simulator/device)
2. Press **Cmd + R**
3. The app will connect to `https://sharry121-baatcheet.hf.space/api/v1`

---

## API Reference

### Authentication

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/mobile/auth/signin` | Email sign-in |
| `POST` | `/mobile/auth/signup` | Email sign-up |
| `POST` | `/mobile/auth/verify-email` | Verify email code |
| `POST` | `/mobile/auth/forgot-password` | Request password reset |
| `POST` | `/mobile/auth/reset-password` | Reset password with code |
| `POST` | `/auth/google` | Google OAuth |

### Chat

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/chat/completions` | Send message (SSE streaming) |
| `GET` | `/chat/modes` | List AI modes |
| `GET` | `/chat/usage` | Daily usage stats |
| `POST` | `/chat/share` | Generate share link |
| `POST` | `/chat/feedback` | Submit message feedback |

### Conversations

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/conversations` | List conversations (paginated) |
| `POST` | `/conversations` | Create conversation |
| `GET` | `/conversations/:id/messages` | Get messages |
| `PATCH` | `/conversations/:id` | Rename / pin / archive |
| `DELETE` | `/conversations/:id` | Delete conversation |

### Projects

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/projects` | List all projects |
| `POST` | `/projects` | Create project |
| `PATCH` | `/projects/:id` | Update project settings |
| `DELETE` | `/projects/:id` | Delete project |
| `POST` | `/projects/:id/invite` | Invite collaborator |
| `GET` | `/projects/:id/members` | List members |
| `GET` | `/projects/:id/team-chat` | Get team chat messages |
| `POST` | `/projects/:id/team-chat` | Send team message |

### Profile

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/profile` | Get user profile |
| `PATCH` | `/profile/settings` | Update profile settings |
| `POST` | `/profile/avatar` | Upload avatar |

### TTS & Voice

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/tts/generate` | Generate TTS audio |

---

## Deep Linking

### Custom URL Scheme

```
baatcheet://conversation/{conversationId}
baatcheet://shared/{shareId}
baatcheet://project/{projectId}
```

### Universal Links

```
https://baatcheet-web.netlify.app/shared/{shareId}
```

---

## Design System

### Brand Colors

| Color | Hex | Usage |
|-------|-----|-------|
| **Slate 800** | `#1e293b` | Primary backgrounds |
| **Slate 500** | `#64748b` | Secondary text |
| **Blue 500** | `#3b82f6` | Links, interactive elements |
| **Green 500** | `#22c55e` | Success, accent highlights |
| **Red 500** | `#ef4444` | Error states, destructive actions |

### Typography

| Style | Size | Weight |
|-------|------|--------|
| Heading 1 | 24pt | Bold |
| Heading 2 | 20pt | Bold |
| Heading 3 | 17pt | Semibold |
| Body | 15pt | Regular |
| Caption | 13pt | Regular |
| Code | 12pt | Monospaced |

---

## Usage Limits

| Resource | Daily Limit |
|----------|------------|
| Chat Messages | 50 |
| Image Generations | 10 |
| Voice Messages | 10 |

Limits reset every 24 hours. No credit card required.

---

## Related Repositories

| Platform | Repository | Status |
|----------|------------|--------|
| **Backend + Web** | [BaatCheet](https://github.com/Sharjeel-Saleem-06/BaatCheet) | Production |
| **Android** | [BaatCheet_Android](https://github.com/Sharjeel-Saleem-06/BaatCheet_Android) | Production |
| **iOS** | [BaatCheet_IOS](https://github.com/Sharjeel-Saleem-06/BaatCheet_IOS) | Production |

### Live Deployments

| Service | URL |
|---------|-----|
| **Web App** | [baatcheet-web.netlify.app](https://baatcheet-web.netlify.app) |
| **Backend API** | [sharry121-baatcheet.hf.space](https://sharry121-baatcheet.hf.space/api/v1) |

---

## Developer

<p align="center">
  <strong>Muhammad Sharjeel</strong><br/>
  <em>Full-Stack &bull; Mobile &bull; AI</em>
</p>

<p align="center">
  <a href="https://github.com/Sharjeel-Saleem-06">GitHub</a> &bull;
  <a href="https://linkedin.com/in/sharjeel-saleem">LinkedIn</a>
</p>

---

## License

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
  Made with care in Pakistan
</p>
