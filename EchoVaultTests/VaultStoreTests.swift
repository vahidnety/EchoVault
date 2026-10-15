import XCTest
import CryptoKit
@testable import EchoVault

final class VaultStoreTests: XCTestCase {
    func testEncryptedRoundTripAndCiphertextDoesNotContainPlaintext() throws {
        // Use an injected ephemeral key to avoid Keychain entitlement dependencies in Simulator CI.
        let key = SymmetricKey(size: .bits256)
        let store = VaultStore(keyProvider: { key })
        let id = UUID()
        let source = FileManager.default.temporaryDirectory.appendingPathComponent("ev-test-\(id).m4a")
        let bytes = Data("original audio bytes are not stored as plaintext".utf8)
        try bytes.write(to: source)
        defer { try? FileManager.default.removeItem(at: source) }

        let filename = try store.saveEncryptedAudio(from: source, id: id)
        defer { try? store.delete(filename: filename) }
        let encryptedURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("EchoVault", isDirectory: true).appendingPathComponent(filename)
        let ciphertext = try Data(contentsOf: encryptedURL)
        XCTAssertNil(ciphertext.range(of: bytes))
        let restoredURL = try store.decryptToTemporaryFile(filename: filename)
        defer { try? FileManager.default.removeItem(at: restoredURL) }
        XCTAssertEqual(try Data(contentsOf: restoredURL), bytes)
    }

    func testMissingRecordingThrows() throws {
        let store = VaultStore(keyProvider: { SymmetricKey(size: .bits256) })
        XCTAssertThrowsError(try store.decryptToTemporaryFile(filename: "missing-\(UUID().uuidString).evault"))
    }
}
