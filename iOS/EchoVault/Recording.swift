import Foundation

struct Recording: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    let createdAt: Date
    var duration: TimeInterval
    var encryptedFilename: String
    var transcript: String?

    init(id: UUID = UUID(), title: String, createdAt: Date = .now,
         duration: TimeInterval = 0, encryptedFilename: String, transcript: String? = nil) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.duration = duration
        self.encryptedFilename = encryptedFilename
        self.transcript = transcript
    }
}

enum EchoVaultError: LocalizedError {
    case microphonePermissionDenied
    case recorderUnavailable
    case recordingNotFound
    case encryptionFailed
    case playbackFailed
    case invalidAudio

    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied: return "Microphone access is required to record audio. You can enable it in Settings."
        case .recorderUnavailable: return "The audio recorder could not be started. Check audio permissions and available storage."
        case .recordingNotFound: return "This recording could not be found. It may have been deleted."
        case .encryptionFailed: return "The recording could not be secured. The temporary audio was removed."
        case .playbackFailed: return "This recording could not be played."
        case .invalidAudio: return "The audio file is invalid or unavailable."
        }
    }
}
