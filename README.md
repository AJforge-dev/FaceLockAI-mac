# 🛡️ FaceLock AI — macOS Native Face ID Security & Secret Vault

[![Swift 6](https://img.shields.io/badge/Swift-6.0-orange.svg?style=flat&logo=swift)](https://swift.org)
[![macOS 14+](https://img.shields.io/badge/macOS-14.0%2B-blue.svg?style=flat&logo=apple)](https://www.apple.com/macos)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**FaceLock AI** is a native macOS security application built using **Swift 6**, **SwiftUI**, **AVFoundation**, and Apple's **Vision framework**. It brings real-time local biometric facial recognition, an encrypted secret file vault, auto-lock workstation integration, and interactive mini games directly to macOS.

---

## ✨ Features

- 📸 **Facial Enrollment & Multi-Sample Vector Extraction**: Captures 5 scale-invariant facial landmark templates (`VNFaceLandmarks2D`) under varying head angles & lighting conditions.
- 🔐 **Local Keychain Security**: Biometric vectors and backup PINs are encrypted and stored 100% locally on-device in macOS Keychain (`Security.framework`). Zero cloud upload.
- 📁 **Secret Vault (Photos, Media, Documents & Notes)**: Categorized file protection with an **"Add Files / Media"** native picker (`NSOpenPanel`) and instant secret note creator.
- 🖥️ **Mac Auto-Lock System Integration**: Automatically locks the Mac display when the enrolled user steps away from the camera.
- 🎲 **Interactive Mini Games Dashboard**: Built-in authentic 15x15 **Ludo King** board game and a **Car Parking Simulation** built with SwiftUI graphics.
- 🔑 **PIN Backup Authentication**: Secure PIN fallback mechanism with attempt rate-limiting.

---

## 🏗️ Architecture & Project Structure

Organized cleanly using the **MVVM (Model-View-ViewModel)** architectural pattern:

```
FaceLockAI/
├── Package.swift               # SPM Manifest with FaceLockCore & Executable targets
├── Info.plist                  # Camera Privacy Entitlements
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
│       │   ├── SecureStorageService.swift  # macOS Keychain Wrapper
│       │   ├── SystemLockManager.swift     # AppleScript Display Lock
│       │   └── SettingsManager.swift       # Preferences & Thresholds
│       ├── ViewModels/
│       │   └── AppViewModel.swift          # Main Coordinator & State Handler
│       └── Views/
│           ├── MainContentView.swift       # Modern Sidebar Layout
│           ├── DashboardView.swift         # Camera Stream & Game Selector
│           ├── LudoGameView.swift          # Authentic Ludo King Board
│           ├── CarParkingGameView.swift    # Steering Car Simulation
│           ├── EnrollmentView.swift        # Guided Face Sample Capture
│           ├── VaultView.swift             # Categorized Secret Vault
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
git clone https://github.com/<your-username>/FaceLockAI.git
cd FaceLockAI

# 2. Run Unit Test Suite
swift run FaceLockAITests

# 3. Build & Run the App Executable
swift run FaceLockAI
```

---

## 📜 Unit Testing

The repository includes a standalone test suite verifying cosine similarity vector matching, threshold verification, and vault category mappings:

```bash
swift run FaceLockAITests
```

**Test Output:**
```
Running FaceLockAI Standalone Unit Tests...
✓ Test 1 Passed: Cosine Similarity Exact Match (0.99999994)
✓ Test 2 Passed: Cosine Similarity Orthogonal (0.0)
✓ Test 3 Passed: Threshold Matching (Confidence: 0.99996215)
✓ Test 4 Passed: Vault Category Photo Icon Mapping

🎉 ALL UNIT TESTS PASSED SUCCESSFULLY!
```

---

## 🔒 Privacy & Security Disclaimer

> **Note**: All biometric feature vectors processed by FaceLock AI are computed and stored 100% locally on your Mac. No image data or vectors ever leave your machine. Webcam-based software recognition complements local file security and workstation auto-lock, and is not a substitute for Apple's Secure Enclave-backed hardware boot authentication (Touch ID).

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
