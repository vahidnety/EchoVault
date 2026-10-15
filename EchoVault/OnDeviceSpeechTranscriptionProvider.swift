import Foundation
import Speech

/// Optional Apple Speech implementation. Recognition is requested on-device when the OS/model supports it.
/// Availability and language support vary by device and locale; this provider never calls a custom server.
struct OnDeviceSpeechTranscriptionProvider: TranscriptionProvider {
    let displayName = "Apple Speech (on-device when available)"
    private let locale: Locale

    init(locale: Locale = .current) { self.locale = locale }

    func transcribe(audioURL: URL) async throws -> TranscriptResult {
        let authorization = await requestAuthorization()
        guard authorization == .authorized else {
            throw TranscriptionError.providerFailure("Speech Recognition permission was not granted.")
        }
        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            throw TranscriptionError.providerFailure("Speech recognition is unavailable for this language or device right now.")
        }
        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = false
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        } else {
            throw TranscriptionError.providerFailure("On-device recognition is not supported for this locale. No network fallback is enabled.")
        }

        return try await withCheckedThrowingContinuation { continuation in
            var finished = false
            _ = recognizer.recognitionTask(with: request) { result, error in
                if let error {
                    guard !finished else { return }
                    finished = true
                    continuation.resume(throwing: TranscriptionError.providerFailure(error.localizedDescription))
                    return
                }
                guard let result, result.isFinal, !finished else { return }
                finished = true
                let text = result.bestTranscription.formattedString
                guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    continuation.resume(throwing: TranscriptionError.emptyResult)
                    return
                }
                continuation.resume(returning: TranscriptResult(text: text, language: locale.identifier))
            }
        }
    }

    private func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
    }
}
