import Foundation
import AppKit

public final class SystemLockManager: Sendable {
    public static let shared = SystemLockManager()
    
    private init() {}

    // Lock macOS screen safely using official AppleScript / Quartz API
    @discardableResult
    public func lockMacScreen() -> Bool {
        // macOS AppleScript system lock command
        let scriptSource = """
        tell application "System Events"
            key code 12 using {control down, command down}
        end tell
        """
        
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: scriptSource) {
            appleScript.executeAndReturnError(&error)
            if error == nil {
                print("System screen lock triggered successfully via AppleScript.")
                return true
            } else {
                print("AppleScript lock error: \(String(describing: error))")
            }
        }
        
        // Fallback using SACLockScreenImmediate or pmset / SACLockScreen
        let fallbackProcess = Process()
        fallbackProcess.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        fallbackProcess.arguments = ["displaysleepnow"]
        do {
            try fallbackProcess.run()
            return true
        } catch {
            print("Fallback lock failed: \(error)")
            return false
        }
    }
}
