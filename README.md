# 🔒 FaceVault — macOS Native Secret Media Vault & Biometric Security

[![Swift 6](https://img.shields.io/badge/Swift-6.0-orange.svg?style=flat&logo=swift)](https://swift.org)
[![macOS 14+](https://img.shields.io/badge/macOS-14.0%2B-blue.svg?style=flat&logo=apple)](https://www.apple.com/macos)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**FaceVault** is a native macOS secret storage application built using **Swift 6**, **SwiftUI**, **AVFoundation**, **LocalAuthentication**, and Apple's **Vision framework**. It provides multi-factor authentication (Face ID camera tracking, Apple Touch ID, Master Passwords, and PIN codes) to protect your photos, videos, confidential documents, and secret notes.

---

## 💾 Direct Download Installer (.DMG)

Download the latest pre-compiled macOS installer package:
👉 **[Download FaceVault-v1.0.dmg](https://github.com/AJforge-dev/FaceLockAI-mac/blob/main/FaceVault-v1.0.dmg?raw=true)**

1. Download `FaceVault-v1.0.dmg`.
2. Double-click to open and drag **FaceVault.app** into your `/Applications` folder.
3. Launch **FaceVault**!

---

## ✨ Features & Multi-Factor Auth

- 📁 **Secret Storage (Photos, Media, Documents & Notes)**: Categorized file protection with a native **"Add Files / Media"** picker (`NSOpenPanel`) and instant encrypted note creation.
- 🖐️ **Apple Touch ID Integration**: Native macOS Touch ID authentication (`LocalAuthentication.framework`) to instantly unlock protected files with your fingerprint.
- 🔑 **Master Password & PIN Support**: Configure a custom Master Password or PIN code fallback stored in macOS Keychain (`Security.framework`).
- 📸 **Local Face ID Recognition**: Captures 5 scale-invariant facial landmark templates (`VNFaceLandmarks2D`) for camera-based unlock. Zero cloud uploads.
- 🎲 **Interactive Mini Games**: Built-in authentic 15x15 **Ludo King** board game and a **Car Parking Simulation** built with SwiftUI graphics.
- 🖥️ **Mac Auto-Lock System Integration**: Automatically locks display and vault when stepping away from your Mac.

---

## 🏗️ Architecture & Project Structure

Organized cleanly using the **MVVM (Model-View-ViewModel)** architectural pattern:

```
FaceVault/
├── FaceVault-v1.0.dmg          # Pre-compiled macOS Disk Image Installer
├── Package.swift               # SPM Manifest with FaceLockCore & Executable targets
├── Info.plist                  # Camera & Touch ID Privacy Entitlements
├── LICENSE                     # MIT Open-Source License
├── Sources/
│   ├── FaceLockAI/             # App Entrypoint
│   │   └── FaceLockApp.swift
│   └── FaceLockCore/           # Core Framework Module
│       ├── Models/
│       │   └── VaultItem.swift
│       ├── Services/
│       │   ├── CameraManager.swift         # AVFoundation Stream Manager
│       │   ├── FaceDetectionService.swift  # Vision Landmark Extractor
│       │   ├── FaceRecognitionService.swift# Cosine Similarity Engine
│       │   ├── TouchIDService.swift        # LocalAuthentication Fingerprint Handler
│       │   ├── SecureStorageService.swift  # Keychain Wrapper (Password, PIN & Vectors)
│       │   ├── SystemLockManager.swift     # AppleScript Display Lock
│       │   └── SettingsManager.swift       # Preferences & Thresholds
│       ├── ViewModels/
│       │   └── AppViewModel.swift          # Main Coordinator & State Handler
│       └── Views/
│           ├── MainContentView.swift       # Modern Vault Sidebar Layout
│           ├── VaultView.swift             # Categorized Secret Vault & Multi-Auth Panel
│           ├── DashboardView.swift         # Mini Games & Camera Stream
│           ├── LudoGameView.swift          # Authentic Ludo King Board
│           ├── CarParkingGameView.swift    # Steering Car Simulation
│           ├── EnrollmentView.swift        # Guided Face Sample Capture
│           └── SettingsView.swift          # Threshold & Timeout Controls
└── Tests/
    └── FaceLockAITests/
        └── FaceLockAITests.swift       # Standalone Executable Test Suite
```

---

## ⚡ Quick Start & Development Guide

### Prerequisites
- **macOS Sonoma 14.0** or newer (Apple Silicon & Intel supported)
- **Swift 6.0+** toolchain

### Build & Run via Terminal

```bash
# 1. Clone the repository
git clone https://github.com/AJforge-dev/FaceLockAI-mac.git
cd FaceLockAI-mac

# 2. Run Unit Test Suite
swift run FaceVaultTests

# 3. Build & Run the App Executable
swift run FaceVault
```

---

## 📜 Unit Testing

The repository includes a standalone test suite verifying cosine similarity vector matching, threshold verification, and vault category mappings:

```bash
swift run FaceVaultTests
```

---

## 🔒 Privacy & Security Disclaimer

> **Note**: All biometric feature vectors processed by FaceVault are computed and stored 100% locally on your Mac in Keychain. No image data or vectors ever leave your machine.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
