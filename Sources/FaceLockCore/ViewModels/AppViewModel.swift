import Foundation
import CoreMedia
import SwiftUI
import Combine
import AppKit

public enum AuthStatus: String, Sendable {
    case unauthenticated = "Unauthenticated"
    case scanning = "Scanning..."
    case recognized = "Face Recognized"
    case unrecognized = "Unrecognized Face"
    case noFaceDetected = "No Face Detected"
    case locked = "Vault Locked"
}

public enum AppTab: String, CaseIterable, Identifiable {
    case vault = "My Vault"
    case faceAccess = "Face Access"
    case activity = "Activity"
    case settings = "Security Settings"
    
    public var id: String { rawValue }
}

public struct ActivityEvent: Identifiable, Sendable, Codable {
    public var id: UUID = UUID()
    public let timestamp: Date
    public let title: String
    public let category: String
    public let iconName: String
}

@MainActor
public final class AppViewModel: ObservableObject, CameraManagerDelegate {
    @Published public var selectedTab: AppTab = .vault
    @Published public var authStatus: AuthStatus = .unauthenticated
    @Published public var isVaultUnlocked: Bool = false
    @Published public var isEnrolled: Bool = false
    @Published public var confidence: Float = 0.0
    @Published public var statusMessage: String = "Ready"
    
    // Activity Log Entries
    @Published public var activityEvents: [ActivityEvent] = []
    
    // Camera Control (On-Demand only)
    @Published public var isCameraActive: Bool = false
    
    // Enrollment state
    @Published public var enrollmentProgress: Double = 0.0
    @Published public var capturedSamplesCount: Int = 0
    @Published public var isEnrolling: Bool = false
    public let requiredSamplesCount: Int = 5
    private var pendingEnrollmentVectors: [[Float]] = []
    
    // Auto lock timer state
    private var lastFaceDetectedTime: Date = Date()
    
    // Categorized Vault Items & Filtering
    @Published public var vaultItems: [VaultItem] = []
    @Published public var selectedVaultCategory: VaultCategory = .all
    @Published public var searchQuery: String = ""
    @Published public var pinInput: String = ""
    @Published public var passwordInput: String = ""
    @Published public var authError: String? = nil
    
    // Temporary decrypted URLs to cleanup on lock
    private var temporaryDecryptedURLs: [URL] = []
    
    public init() {
        self.isEnrolled = SecureStorageService.shared.isEnrolled()
        CameraManager.shared.delegate = self
        setupVaultDirectories()
        loadActivityEvents()
    }
    
    public func startCamera() {
        guard !isCameraActive else { return }
        isCameraActive = true
        CameraManager.shared.checkPermissionsAndSetup()
        CameraManager.shared.startSession()
    }
    
    public func stopCamera() {
        isCameraActive = false
        CameraManager.shared.stopSession()
    }
    
    // MARK: - Camera Output Handling
    nonisolated public func cameraManager(_ manager: CameraManager, didOutput sampleBuffer: CMSampleBuffer) {
        guard let result = FaceDetectionService.shared.extractFeatureVector(from: sampleBuffer) else {
            Task { @MainActor in
                self.handleNoFaceDetected()
            }
            return
        }
        
        let liveVector = result.vector
        Task { @MainActor in
            self.handleFaceDetected(liveVector: liveVector)
        }
    }
    
    private func handleNoFaceDetected() {
        if isEnrolling {
            statusMessage = "Position your face in camera frame"
            return
        }
        authStatus = .noFaceDetected
        confidence = 0.0
    }
    
    private func handleFaceDetected(liveVector: [Float]) {
        lastFaceDetectedTime = Date()
        
        if isEnrolling {
            processEnrollmentSample(vector: liveVector)
            return
        }
        
        guard isEnrolled, let templates = SecureStorageService.shared.getFaceTemplates() else {
            authStatus = .unauthenticated
            statusMessage = "No face template enrolled"
            return
        }
        
        authStatus = .scanning
        let threshold = SettingsManager.shared.confidenceThreshold
        let match = FaceRecognitionService.shared.matchVector(liveVector, enrolledTemplates: templates, threshold: threshold)
        
        self.confidence = match.confidence
        
        if match.isMatch {
            authStatus = .recognized
            statusMessage = "Face Recognized"
            if !isVaultUnlocked {
                unlockVaultSuccess(method: "Face Verification")
            }
        } else {
            authStatus = .unrecognized
            statusMessage = "Unrecognized Face"
        }
    }
    
    // MARK: - Enrollment Workflow
    public func startEnrollment() {
        startCamera()
        pendingEnrollmentVectors.removeAll()
        capturedSamplesCount = 0
        enrollmentProgress = 0.0
        isEnrolling = true
        statusMessage = "Hold still for face capture..."
    }
    
    public func processEnrollmentSample(vector: [Float]) {
        guard isEnrolling else { return }
        
        if let last = pendingEnrollmentVectors.last {
            let sim = FaceRecognitionService.shared.cosineSimilarity(last, vector)
            if sim > 0.98 { return }
        }
        
        pendingEnrollmentVectors.append(vector)
        capturedSamplesCount = pendingEnrollmentVectors.count
        enrollmentProgress = Double(capturedSamplesCount) / Double(requiredSamplesCount)
        
        if capturedSamplesCount >= requiredSamplesCount {
            isEnrolling = false
            let saved = SecureStorageService.shared.saveFaceTemplates(pendingEnrollmentVectors)
            stopCamera()
            if saved {
                isEnrolled = true
                statusMessage = "Face enrollment completed."
                recordActivity(title: "Enrolled New Face Template", category: "Face Access", icon: "faceid")
            } else {
                statusMessage = "Failed to save face templates."
            }
        } else {
            statusMessage = "Captured \(capturedSamplesCount)/\(requiredSamplesCount) samples."
        }
    }
    
    public func resetEnrollment() {
        _ = SecureStorageService.shared.clearAllData()
        isEnrolled = false
        isVaultUnlocked = false
        pendingEnrollmentVectors.removeAll()
        capturedSamplesCount = 0
        enrollmentProgress = 0.0
        statusMessage = "Facial templates reset."
        stopCamera()
        recordActivity(title: "Reset Facial Templates", category: "Face Access", icon: "trash")
    }
    
    // MARK: - Vault Lock & Unlock Handlers
    private func unlockVaultSuccess(method: String) {
        isVaultUnlocked = true
        authStatus = .recognized
        authError = nil
        statusMessage = "Unlocked via \(method)"
        recordActivity(title: "Vault Unlocked via \(method)", category: "Authentication", icon: "lock.open.fill")
    }

    public func lockVault(triggerSystemLock: Bool = false) {
        isVaultUnlocked = false
        authStatus = .locked
        statusMessage = "Vault locked."
        cleanupTemporaryFiles()
        stopCamera()
        recordActivity(title: "Vault Locked", category: "Security", icon: "lock.fill")
        
        if triggerSystemLock && SettingsManager.shared.autoLockOnFaceAbsence {
            SystemLockManager.shared.lockMacScreen()
        }
    }
    
    public func authenticateWithTouchID() {
        Task {
            let success = await TouchIDService.shared.authenticateWithTouchID(reason: "Unlock FaceVault")
            if success {
                self.unlockVaultSuccess(method: "Touch ID")
            } else {
                self.authError = "Touch ID authentication failed."
                self.recordActivity(title: "Failed Touch ID Attempt", category: "Security Alert", icon: "exclamationmark.triangle.fill")
            }
        }
    }

    public func authenticateWithPIN() {
        guard SecureStorageService.shared.verifyPIN(pinInput) else {
            authError = "Incorrect PIN."
            recordActivity(title: "Failed PIN Attempt", category: "Security Alert", icon: "exclamationmark.triangle.fill")
            return
        }
        pinInput = ""
        unlockVaultSuccess(method: "PIN")
    }

    public func authenticateWithPassword() {
        guard SecureStorageService.shared.verifyPassword(passwordInput) else {
            authError = "Incorrect Password."
            recordActivity(title: "Failed Password Attempt", category: "Security Alert", icon: "exclamationmark.triangle.fill")
            return
        }
        passwordInput = ""
        unlockVaultSuccess(method: "Master Password")
    }
    
    public func setupPIN(_ newPIN: String) {
        _ = SecureStorageService.shared.savePIN(newPIN)
        recordActivity(title: "Configured Security PIN", category: "Settings", icon: "number")
    }

    public func setupPassword(_ newPass: String) {
        _ = SecureStorageService.shared.savePassword(newPass)
        recordActivity(title: "Configured Master Password", category: "Settings", icon: "key.fill")
    }
    
    // MARK: - Activity Logger
    public func recordActivity(title: String, category: String, icon: String) {
        let event = ActivityEvent(timestamp: Date(), title: title, category: category, iconName: icon)
        activityEvents.insert(event, at: 0)
        saveActivityEvents()
    }
    
    private func saveActivityEvents() {
        if let data = try? JSONEncoder().encode(Array(activityEvents.prefix(50))) {
            UserDefaults.standard.set(data, forKey: "FaceVault_ActivityEvents")
        }
    }
    
    private func loadActivityEvents() {
        if let data = UserDefaults.standard.data(forKey: "FaceVault_ActivityEvents"),
           let events = try? JSONDecoder().decode([ActivityEvent].self, from: data) {
            self.activityEvents = events
        } else {
            self.activityEvents = [
                ActivityEvent(timestamp: Date(), title: "FaceVault Initialized", category: "System", iconName: "shield.fill")
            ]
        }
    }

    // MARK: - Categorized Secret Vault & AES-GCM Encrypted Storage
    private func setupVaultDirectories() {
        let fm = FileManager.default
        guard let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let vaultRoot = docs.appendingPathComponent("FaceVault_EncryptedData")
        
        let subfolders = ["Photos_Media", "Documents", "SecretNotes"]
        for sub in subfolders {
            let dir = vaultRoot.appendingPathComponent(sub)
            if !fm.fileExists(atPath: dir.path) {
                try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
            }
        }
        refreshVaultItems()
    }
    
    public func refreshVaultItems() {
        let fm = FileManager.default
        guard let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let vaultRoot = docs.appendingPathComponent("FaceVault_EncryptedData")
        
        var items: [VaultItem] = []
        let categoryMappings: [(String, VaultCategory)] = [
            ("Photos_Media", .photos),
            ("Documents", .documents),
            ("SecretNotes", .secrets)
        ]
        
        for (sub, cat) in categoryMappings {
            let dir = vaultRoot.appendingPathComponent(sub)
            if let urls = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
                for url in urls {
                    if !url.lastPathComponent.hasPrefix(".") {
                        items.append(VaultItem(name: url.lastPathComponent, category: cat, fileURL: url))
                    }
                }
            }
        }
        
        self.vaultItems = items
    }

    public func importFilesToVault() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.prompt = "Import & Encrypt"
        panel.title = "Select Files to Encrypt into FaceVault"
        
        panel.begin { [weak self] response in
            guard let self = self, response == .OK else { return }
            let fm = FileManager.default
            guard let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
            let vaultRoot = docs.appendingPathComponent("FaceVault_EncryptedData")
            
            var importedCount = 0
            for sourceURL in panel.urls {
                let ext = sourceURL.pathExtension.lowercased()
                let targetSubfolder: String
                if ["png", "jpg", "jpeg", "gif", "mp4", "mov", "heic", "m4v", "avi", "webp"].contains(ext) {
                    targetSubfolder = "Photos_Media"
                } else {
                    targetSubfolder = "Documents"
                }
                
                let destDir = vaultRoot.appendingPathComponent(targetSubfolder)
                let destURL = destDir.appendingPathComponent(sourceURL.lastPathComponent + ".enc")
                
                do {
                    try VaultEncryptionService.shared.encryptFile(at: sourceURL, destinationURL: destURL)
                    importedCount += 1
                } catch {
                    print("Encryption error: \(error)")
                }
            }
            
            Task { @MainActor in
                self.refreshVaultItems()
                self.recordActivity(title: "Encrypted & Imported \(importedCount) Files", category: "Vault", icon: "lock.doc.fill")
            }
        }
    }

    public func decryptAndOpenFile(item: VaultItem) {
        guard let encryptedURL = item.fileURL else { return }
        do {
            let decryptedData = try VaultEncryptionService.shared.decryptFile(at: encryptedURL)
            
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("FaceVault_Preview")
            try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            
            // Original filename without .enc suffix
            var originalName = item.name
            if originalName.hasSuffix(".enc") {
                originalName = String(originalName.dropLast(4))
            }
            
            let tempFileURL = tempDir.appendingPathComponent(originalName)
            try decryptedData.write(to: tempFileURL)
            
            temporaryDecryptedURLs.append(tempFileURL)
            NSWorkspace.shared.open(tempFileURL)
            
            recordActivity(title: "Opened Encrypted File: \(originalName)", category: "Vault", icon: "doc.text.fill")
        } catch {
            print("Failed to decrypt file: \(error)")
        }
    }

    public func addSecretNote(title: String, note: String) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(title).txt")
        try? note.write(to: tempURL, atomically: true, encoding: .utf8)
        
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let notesDir = docs.appendingPathComponent("FaceVault_EncryptedData/SecretNotes")
        let destURL = notesDir.appendingPathComponent("\(title).txt.enc")
        
        try? VaultEncryptionService.shared.encryptFile(at: tempURL, destinationURL: destURL)
        try? FileManager.default.removeItem(at: tempURL)
        
        refreshVaultItems()
        recordActivity(title: "Created Encrypted Note: \(title)", category: "Vault", icon: "square.and.pencil")
    }

    private func cleanupTemporaryFiles() {
        for url in temporaryDecryptedURLs {
            try? FileManager.default.removeItem(at: url)
        }
        temporaryDecryptedURLs.removeAll()
    }
}
