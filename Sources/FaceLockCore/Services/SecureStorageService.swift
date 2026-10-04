import Foundation
import Security

public final class SecureStorageService: Sendable {
    public static let shared = SecureStorageService()
    
    private let pinKey = "com.facelock.ai.pin"
    private let templateKey = "com.facelock.ai.facetemplate"
    private let serviceName = "com.facelock.ai.service"

    private init() {}

    // MARK: - Keychain Core Methods
    
    public func saveSecret(_ data: Data, forKey accountKey: String) -> Bool {
        // Delete existing item if present
        deleteSecret(forKey: accountKey)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    public func loadSecret(forKey accountKey: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return data
        }
        return nil
    }

    @discardableResult
    public func deleteSecret(forKey accountKey: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountKey
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - PIN Helper Methods
    
    public func savePIN(_ pin: String) -> Bool {
        guard let data = pin.data(using: .utf8) else { return false }
        return saveSecret(data, forKey: pinKey)
    }

    public func getPIN() -> String? {
        guard let data = loadSecret(forKey: pinKey) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public func verifyPIN(_ pin: String) -> Bool {
        guard let storedPIN = getPIN() else { return false }
        return storedPIN == pin
    }
    
    public func hasPIN() -> Bool {
        return getPIN() != nil
    }

    // MARK: - Face Template Vectors
    
    public func saveFaceTemplates(_ templates: [[Float]]) -> Bool {
        do {
            let data = try JSONEncoder().encode(templates)
            return saveSecret(data, forKey: templateKey)
        } catch {
            print("Error encoding face templates: \(error)")
            return false
        }
    }

    public func getFaceTemplates() -> [[Float]]? {
        guard let data = loadSecret(forKey: templateKey) else { return nil }
        do {
            return try JSONDecoder().decode([[Float]].self, from: data)
        } catch {
            print("Error decoding face templates: \(error)")
            return nil
        }
    }

    public func isEnrolled() -> Bool {
        guard let templates = getFaceTemplates(), !templates.isEmpty else {
            return false
        }
        return true
    }

    public func clearAllData() -> Bool {
        let pinDeleted = deleteSecret(forKey: pinKey)
        let templateDeleted = deleteSecret(forKey: templateKey)
        return pinDeleted && templateDeleted
    }
}
