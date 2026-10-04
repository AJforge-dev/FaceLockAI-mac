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
    case dashboard = "Dashboard & Mini Games"
    case enrollment = "Face Enrollment"
    case vault = "Secret Vault (Photos, Media & Docs)"
    case settings = "Settings"
    
    public var id: String { rawValue }
}

@MainActor
public final class AppViewModel: ObservableObject, CameraManagerDelegate {
    @Published public var selectedTab: AppTab = .dashboard
    @Published public var authStatus: AuthStatus = .unauthenticated
    @Published public var isVaultUnlocked: Bool = false
    @Published public var isEnrolled: Bool = false
    @Published public var confidence: Float = 0.0
    @Published public var statusMessage: String = "Ready"
    
    // Enrollment state
    @Published public var enrollmentProgress: Double = 0.0
    @Published public var capturedSamplesCount: Int = 0
    @Published public var isEnrolling: Bool = false
    public let requiredSamplesCount: Int = 5
    private var pendingEnrollmentVectors: [[Float]] = []
    
    // Auto lock timer state
    private var lastFaceDetectedTime: Date = Date()
    
    // Categorized Vault Items
    @Published public var vaultItems: [VaultItem] = []
    @Published public var selectedVaultCategory: VaultCategory = .all
    @Published public var pinInput: String = ""
    @Published public var pinError: String? = nil
    
    public init() {
        self.isEnrolled = SecureStorageService.shared.isEnrolled()
        CameraManager.shared.delegate = self
        setupVaultDirectories()
    }
    
    public func startCamera() {
        CameraManager.shared.checkPermissionsAndSetup()
        CameraManager.shared.startSession()
    }
    
    public func stopCamera() {
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
            statusMessage = "Position your face clearly in the camera frame"
            return
        }
        
        authStatus = .noFaceDetected
        confidence = 0.0
        
        // Auto-lock check if user absent
        if SettingsManager.shared.autoLockOnFaceAbsence && isVaultUnlocked {
            let elapsed = Date().timeIntervalSince(lastFaceDetectedTime)
            let limit = Double(SettingsManager.shared.autoLockDelaySeconds)
            if elapsed >= limit {
                lockVault(triggerSystemLock: true)
            }
        }
    }
    
    private func handleFaceDetected(liveVector: [Float]) {
        lastFaceDetectedTime = Date()
        
        if isEnrolling {
            processEnrollmentSample(vector: liveVector)
            return
        }
        
        guard isEnrolled, let templates = SecureStorageService.shared.getFaceTemplates() else {
            authStatus = .unauthenticated
            statusMessage = "Please complete face enrollment first"
            return
        }
        
        authStatus = .scanning
        let threshold = SettingsManager.shared.confidenceThreshold
        let match = FaceRecognitionService.shared.matchVector(liveVector, enrolledTemplates: templates, threshold: threshold)
        
        self.confidence = match.confidence
        
        if match.isMatch {
            authStatus = .recognized
            statusMessage = "Enrolled face recognized (\(Int(match.confidence * 100))% match)"
            if !isVaultUnlocked {
                isVaultUnlocked = true
            }
        } else {
            authStatus = .unrecognized
            statusMessage = "Unrecognized face (\(Int(match.confidence * 100))% confidence)"
        }
    }
    
    // MARK: - Enrollment Workflow
    public func startEnrollment() {
        pendingEnrollmentVectors.removeAll()
        capturedSamplesCount = 0
        enrollmentProgress = 0.0
        isEnrolling = true
        statusMessage = "Hold still under good lighting..."
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
            if saved {
                isEnrolled = true
                statusMessage = "Enrollment successful! Saved \(requiredSamplesCount) face samples."
            } else {
                statusMessage = "Failed to save face templates to Keychain."
            }
        } else {
            statusMessage = "Sample \(capturedSamplesCount)/\(requiredSamplesCount) captured. Turn head slightly..."
        }
    }
    
    public func resetEnrollment() {
        _ = SecureStorageService.shared.clearAllData()
        isEnrolled = false
        isVaultUnlocked = false
        pendingEnrollmentVectors.removeAll()
        capturedSamplesCount = 0
        enrollmentProgress = 0.0
        statusMessage = "Face template reset."
    }
    
    // MARK: - Vault & Security Operations
    public func lockVault(triggerSystemLock: Bool = false) {
        isVaultUnlocked = false
        authStatus = .locked
        statusMessage = "Vault locked."
        if triggerSystemLock && SettingsManager.shared.autoLockOnFaceAbsence {
            SystemLockManager.shared.lockMacScreen()
        }
    }
    
    public func authenticateWithPIN() {
        guard SecureStorageService.shared.verifyPIN(pinInput) else {
            pinError = "Incorrect PIN. Please try again."
            return
        }
        pinError = nil
        pinInput = ""
        isVaultUnlocked = true
        authStatus = .recognized
        statusMessage = "Unlocked with PIN fallback"
    }
    
    public func setupPIN(_ newPIN: String) {
        _ = SecureStorageService.shared.savePIN(newPIN)
    }
    
    // MARK: - Categorized Secret Vault Handlers
    private func setupVaultDirectories() {
        let fm = FileManager.default
        guard let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let vaultRoot = docs.appendingPathComponent("FaceLockAI_SecretVault")
        
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
        let vaultRoot = docs.appendingPathComponent("FaceLockAI_SecretVault")
        
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
        panel.prompt = "Import to Secret Vault"
        panel.title = "Select Photos, Videos, or Documents to Secure"
        
        panel.begin { [weak self] response in
            guard let self = self, response == .OK else { return }
            let fm = FileManager.default
            guard let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
            let vaultRoot = docs.appendingPathComponent("FaceLockAI_SecretVault")
            
            for sourceURL in panel.urls {
                let ext = sourceURL.pathExtension.lowercased()
                let targetSubfolder: String
                if ["png", "jpg", "jpeg", "gif", "mp4", "mov", "heic", "m4v", "avi", "webp"].contains(ext) {
                    targetSubfolder = "Photos_Media"
                } else if ["txt", "pdf", "doc", "docx", "pages", "rtf", "key", "numbers", "csv"].contains(ext) {
                    targetSubfolder = "Documents"
                } else {
                    targetSubfolder = "Documents"
                }
                
                let destDir = vaultRoot.appendingPathComponent(targetSubfolder)
                let destURL = destDir.appendingPathComponent(sourceURL.lastPathComponent)
                
                do {
                    if fm.fileExists(atPath: destURL.path) {
                        try fm.removeItem(at: destURL)
                    }
                    try fm.copyItem(at: sourceURL, to: destURL)
                } catch {
                    print("Error copying file to vault: \(error)")
                }
            }
            
            Task { @MainActor in
                self.refreshVaultItems()
            }
        }
    }

    public func addSecretNote(title: String, note: String) {
        let fm = FileManager.default
        guard let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let notesDir = docs.appendingPathComponent("FaceLockAI_SecretVault/SecretNotes")
        let file = notesDir.appendingPathComponent("\(title).txt")
        try? note.write(to: file, atomically: true, encoding: .utf8)
        refreshVaultItems()
    }
}
