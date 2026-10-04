import Foundation
import CryptoKit
import Security

public final class VaultEncryptionService: Sendable {
    public static let shared = VaultEncryptionService()
    
    private let keychainKeyAlias = "com.facevault.ai.masterkey"
    
    private init() {}
    
    // Retrieve or generate 256-bit Symmetric Key from Keychain
    public func getOrCreateMasterKey() throws -> SymmetricKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKeyAlias,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecSuccess, let keyData = item as? Data {
            return SymmetricKey(data: keyData)
        }
        
        // Generate new key
        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }
        
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKeyAlias,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
        
        return newKey
    }
    
    // Encrypt file at rest using AES-GCM
    public func encryptFile(at sourceURL: URL, destinationURL: URL) throws {
        let key = try getOrCreateMasterKey()
        let fileData = try Data(contentsOf: sourceURL)
        let sealedBox = try AES.GCM.seal(fileData, using: key)
        guard let combined = sealedBox.combined else {
            throw NSError(domain: "VaultEncryptionService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to combine AES.GCM sealed box"])
        }
        try combined.write(to: destinationURL)
    }
    
    // Decrypt file temporarily for viewing
    public func decryptFile(at encryptedURL: URL) throws -> Data {
        let key = try getOrCreateMasterKey()
        let combinedData = try Data(contentsOf: encryptedURL)
        let sealedBox = try AES.GCM.SealedBox(combined: combinedData)
        return try AES.GCM.open(sealedBox, using: key)
    }
}
