import Foundation

@MainActor
public final class SettingsManager: ObservableObject {
    public static let shared = SettingsManager()
    
    @Published public var autoLockOnFaceAbsence: Bool {
        didSet { UserDefaults.standard.set(autoLockOnFaceAbsence, forKey: "autoLockOnFaceAbsence") }
    }
    
    @Published public var autoLockDelaySeconds: Int {
        didSet { UserDefaults.standard.set(autoLockDelaySeconds, forKey: "autoLockDelaySeconds") }
    }
    
    @Published public var confidenceThreshold: Float {
        didSet { UserDefaults.standard.set(confidenceThreshold, forKey: "confidenceThreshold") }
    }
    
    @Published public var pinFallbackEnabled: Bool {
        didSet { UserDefaults.standard.set(pinFallbackEnabled, forKey: "pinFallbackEnabled") }
    }
    
    private init() {
        self.autoLockOnFaceAbsence = UserDefaults.standard.object(forKey: "autoLockOnFaceAbsence") as? Bool ?? true
        self.autoLockDelaySeconds = UserDefaults.standard.object(forKey: "autoLockDelaySeconds") as? Int ?? 5
        self.confidenceThreshold = UserDefaults.standard.object(forKey: "confidenceThreshold") as? Float ?? 0.85
        self.pinFallbackEnabled = UserDefaults.standard.object(forKey: "pinFallbackEnabled") as? Bool ?? true
    }
}
