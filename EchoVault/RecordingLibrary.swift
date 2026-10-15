import Foundation
import AVFoundation
import Combine

@MainActor
final class RecordingLibrary: NSObject, ObservableObject {
    @Published private(set) var recordings: [Recording] = []
    @Published private(set) var isRecording = false
    @Published private(set) var elapsed: TimeInterval = 0
    @Published var errorMessage: String?
    @Published var infoMessage: String?

    private let vault: VaultStore
    private let metadataURL: URL
    private let transcriptionProvider: TranscriptionProvider
    private var recorder: AVAudioRecorder?
    private var recordingStart: Date?
    private var temporaryRecordingURL: URL?
    private var playback: AVAudioPlayer?
    private var playbackTemporaryURL: URL?

    init(transcriptionProvider: TranscriptionProvider = OnDeviceSpeechTranscriptionProvider()) {
        self.transcriptionProvider = transcriptionProvider
        self.vault = VaultStore()
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("EchoVault", isDirectory: true)
        self.metadataURL = base.appendingPathComponent("recordings.json")
        super.init()
        self.recordings = (try? JSONDecoder().decode([Recording].self, from: Data(contentsOf: metadataURL))) ?? []
    }

    func startRecording() async {
        guard !isRecording else { return }
        let granted: Bool
        if #available(iOS 17.0, *) {
            granted = await AVAudioApplication.requestRecordPermission()
        } else {
            granted = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { continuation.resume(returning: $0) }
            }
        }
        guard granted else { errorMessage = EchoVaultError.microphonePermissionDenied.localizedDescription; return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("ev-record-\(UUID().uuidString).m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC), AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            let newRecorder = try AVAudioRecorder(url: url, settings: settings)
            newRecorder.isMeteringEnabled = true
            guard newRecorder.record() else { throw EchoVaultError.recorderUnavailable }
            recorder = newRecorder
            temporaryRecordingURL = url
            recordingStart = .now
            elapsed = 0
            isRecording = true
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func stopRecording() {
        guard isRecording, let recorder, let tempURL = temporaryRecordingURL else { return }
        recorder.stop()
        let duration = max(0, Date.now.timeIntervalSince(recordingStart ?? .now))
        self.recorder = nil
        self.temporaryRecordingURL = nil
        self.recordingStart = nil
        isRecording = false
        elapsed = duration

        do {
            let id = UUID()
            let filename = try vault.saveEncryptedAudio(from: tempURL, id: id)
            try? FileManager.default.removeItem(at: tempURL)
            let item = Recording(id: id, title: "Recording \(Date.now.formatted(date: .abbreviated, time: .shortened))",
                                 duration: duration, encryptedFilename: filename)
            recordings.insert(item, at: 0)
            try persistMetadata()
            infoMessage = "Recording encrypted and saved on this device."
        } catch {
            try? FileManager.default.removeItem(at: tempURL)
            errorMessage = error.localizedDescription
        }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func updateElapsed() {
        guard isRecording, let start = recordingStart else { return }
        elapsed = Date.now.timeIntervalSince(start)
        recorder?.updateMeters()
    }

    func play(_ recording: Recording) {
        do {
            stopPlayback()
            let url = try vault.decryptToTemporaryFile(filename: recording.encryptedFilename)
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.prepareToPlay()
            guard player.play() else {
                try? FileManager.default.removeItem(at: url)
                throw EchoVaultError.playbackFailed
            }
            playback = player
            playbackTemporaryURL = url
        } catch { errorMessage = error.localizedDescription }
    }

    func stopPlayback() {
        playback?.stop()
        playback = nil
        if let url = playbackTemporaryURL { try? FileManager.default.removeItem(at: url) }
        playbackTemporaryURL = nil
    }

    func delete(_ recording: Recording) {
        do {
            try vault.delete(filename: recording.encryptedFilename)
            recordings.removeAll { $0.id == recording.id }
            try persistMetadata()
            infoMessage = "Recording deleted."
        } catch { errorMessage = error.localizedDescription }
    }

    func transcribe(_ recording: Recording) async {
        do {
            let url = try vault.decryptToTemporaryFile(filename: recording.encryptedFilename)
            defer { try? FileManager.default.removeItem(at: url) }
            let result = try await transcriptionProvider.transcribe(audioURL: url)
            guard !result.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw TranscriptionError.emptyResult }
            guard let index = recordings.firstIndex(where: { $0.id == recording.id }) else { throw EchoVaultError.recordingNotFound }
            recordings[index].transcript = result.text
            try persistMetadata()
            infoMessage = "Transcript saved."
        } catch { errorMessage = error.localizedDescription }
    }

    private func persistMetadata() throws {
        let data = try JSONEncoder().encode(recordings)
        try data.write(to: metadataURL, options: [.atomic, .completeFileProtection])
    }
}

extension RecordingLibrary: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak self, weak player] in
            guard let self, let player, self.playback === player else { return }
            self.stopPlayback()
        }
    }
}
