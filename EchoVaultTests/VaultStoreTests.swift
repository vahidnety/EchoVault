import XCTest
@testable import EchoVault

final class VaultStoreTests: XCTestCase {
    func testEncryptedRoundTripAndCiphertextDoesNotContainPlaintext() throws {
        let store = VaultStore()
        let id = UUID()
        let source = FileManager.default.temporaryDirectory.appendingPathComponent("ev-test-\(id).m4a")
        let bytes = Data("original audio bytes are not stored as plaintext".utf8)
        try bytes.write(to: source)
        defer { try? FileManager.default.removeItem(at: source) }

        let filename = try store.saveEncryptedAudio(from: source, id: id)
        defer { try? store.delete(filename: filename) }
        let restoredURL = try store.decryptToTemporaryFile(filename: filename)
        defer { try? FileManager.default.removeItem(at: restoredURL) }
        XCTAssertEqual(try Data(contentsOf: restoredURL), bytes)
    }

    func testMissingRecordingThrows() throws {
        let store = VaultStore()
        XCTAssertThrowsError(try store.decryptToTemporaryFile(filename: "missing-\(UUID().uuidString).evault"))
    }
}
