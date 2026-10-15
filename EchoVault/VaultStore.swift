import Foundation
import CryptoKit
import Security

/// Encrypts audio blobs with AES-GCM before they are persisted in the vault.
/// Production uses Keychain-backed keys and complete file protection.
/// Tests may inject an ephemeral key and use simulator-compatible file writes.
final class VaultStore {
    private let fileManager = FileManager.default
    private let folderName = "EchoVault"
    private let keyTag = "com.example.echovault.audio-key.v1"
    private let injectedKeyProvider: (() throws -> SymmetricKey)?

    private var directory: URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent(folderName, isDirectory: true)
    }

    /// Supplying a key provider isolates cryptographic tests from Keychain entitlements.
    /// File-protection attributes are retained in production and omitted only for injected-key tests.
    init(keyProvider: (() throws -> SymmetricKey)? = nil) {
        self.injectedKeyProvider = keyProvider
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    private var secureWriteOptions: Data.WritingOptions {
        injectedKeyProvider == nil ? [.atomic, .completeFileProtection] : [.atomic]
    }

    private var temporaryWriteOptions: Data.WritingOptions {
        injectedKeyProvider == nil ? [.atomic, .completeFileProtectionUnlessOpen] : [.atomic]
    }

    func saveEncryptedAudio(from plaintextURL: URL, id: UUID) throws -> String {
        let plaintext = try Data(contentsOf: plaintextURL)
        let sealed = try AES.GCM.seal(plaintext, using: encryptionKey())
        guard let combined = sealed.combined else { throw EchoVaultError.encryptionFailed }
        let filename = "\(id.uuidString).evault"
        let destination = directory.appendingPathComponent(filename)
        try combined.write(to: destination, options: secureWriteOptions)
        return filename
    }

    func decryptToTemporaryFile(filename: String) throws -> URL {
        let encryptedURL = directory.appendingPathComponent(filename)
        guard fileManager.fileExists(atPath: encryptedURL.path) else { throw EchoVaultError.recordingNotFound }
        let combined = try Data(contentsOf: encryptedURL)
        let box = try AES.GCM.SealedBox(combined: combined)
        let plaintext = try AES.GCM.open(box, using: encryptionKey())
        let tempURL = fileManager.temporaryDirectory.appendingPathComponent("ev-play-\(UUID().uuidString).m4a")
        try plaintext.write(to: tempURL, options: temporaryWriteOptions)
        return tempURL
    }

    func delete(filename: String) throws {
        let url = directory.appendingPathComponent(filename)
        if fileManager.fileExists(atPath: url.path) { try fileManager.removeItem(at: url) }
    }

    private func encryptionKey() throws -> SymmetricKey {
        if let injectedKeyProvider { return try injectedKeyProvider() }
        if let existing = try readKeyFromKeychain() { return SymmetricKey(data: existing) }
        let key = SymmetricKey(size: .bits256)
        let data = key.withUnsafeBytes { Data($0) }
        try saveKeyToKeychain(data)
        return key
    }

    private func readKeyFromKeychain() throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyTag,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
        return data
    }

    private func saveKeyToKeychain(_ data: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyTag,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess || status == errSecDuplicateItem else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
    }
}
