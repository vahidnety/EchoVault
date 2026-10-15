import XCTest
@testable import EchoVault

final class RecordingModelTests: XCTestCase {
    func testRecordingCodableRoundTrip() throws {
        let original = Recording(title: "Design review", duration: 42.5, encryptedFilename: "sample.evault", transcript: "Follow up next week")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Recording.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func testUnconfiguredProviderFailsClearly() async {
        let provider = UnconfiguredTranscriptionProvider()
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("empty-audio.m4a")
        do {
            _ = try await provider.transcribe(audioURL: url)
            XCTFail("Expected the provider to report that it is not configured")
        } catch {
            XCTAssertEqual(error.localizedDescription, TranscriptionError.notConfigured.localizedDescription)
        }
    }
}
