import Foundation

struct TranscriptResult: Equatable {
    let text: String
    let language: String?
}

/// Implementations can use on-device Speech, a private enterprise endpoint, or a test double.
/// The app does not upload audio unless a provider explicitly implements that behavior.
protocol TranscriptionProvider {
    var displayName: String { get }
    func transcribe(audioURL: URL) async throws -> TranscriptResult
}

/// Honest starter implementation: keeps the interface testable without pretending transcription exists.
struct UnconfiguredTranscriptionProvider: TranscriptionProvider {
    let displayName = "Not configured"
    func transcribe(audioURL: URL) async throws -> TranscriptResult {
        throw TranscriptionError.notConfigured
    }
}

enum TranscriptionError: LocalizedError {
    case notConfigured
    case emptyResult
    case providerFailure(String)
    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Transcription is not configured yet. Add an on-device or approved private provider."
        case .emptyResult: return "The transcription provider returned no text."
        case .providerFailure(let message): return "Transcription failed: \(message)"
        }
    }
}
