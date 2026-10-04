import Foundation
import LocalAuthentication

public final class TouchIDService: Sendable {
    public static let shared = TouchIDService()
    
    private init() {}

    public func isTouchIDAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return canEvaluate
    }

    @MainActor
    public func authenticateWithTouchID(reason: String = "Unlock your FaceVault Protected Files") async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Use Face ID / PIN"
        
        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
        } catch {
            print("Touch ID authentication error: \(error)")
            return false
        }
    }
}
