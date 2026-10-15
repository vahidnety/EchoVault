# Android architecture

- **Compose UI / ViewModel:** presentation state, permission request, search, record/save/discard, playback, delete.
- **RecordingRepository:** coordinates audio capture, AES-GCM encryption, Room metadata, and temporary playback files.
- **AudioRecorder / AudioPlayer:** platform MediaRecorder and MediaPlayer adapters.
- **AudioCrypto:** AES-256-GCM; random 12-byte IV is prepended to ciphertext; authentication tag is verified by GCM on decrypt.
- **Android Keystore:** non-exportable symmetric key, generated on first use.
- **Room:** stores recording metadata and optional transcript, never audio bytes.
- **OnDeviceTranscriber:** checks OS recognizer availability and exposes microphone transcription only; saved-recording transcription is a future task.

## Data flow

Microphone -> temporary staging audio -> AES-GCM -> app-private encrypted file + Room metadata. Playback decrypts into app cache -> MediaPlayer -> temporary file deleted at completion or failure. Crash recovery and lifecycle edge cases need additional hardening.