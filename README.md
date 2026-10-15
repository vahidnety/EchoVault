# EchoVault — Private Voice Intelligence

**An independent iOS engineering portfolio project. Not affiliated with Cohere.**

EchoVault explores native audio capture, encrypted local storage, a replaceable transcription boundary, and privacy-oriented UX. It is intentionally a working starter rather than a claim of production certification.

## What it demonstrates

- SwiftUI screens with accessible controls and clear recording states.
- Native audio capture with permission handling, AAC recording, elapsed-time updates, and audio-session activation/deactivation.
- AES-GCM authenticated encryption of recordings before they are persisted.
- A 256-bit symmetric key stored in iOS Keychain with `WhenUnlockedThisDeviceOnly` accessibility.
- Local metadata persistence, search across titles/transcripts, playback, delete, and user-visible errors.
- A `TranscriptionProvider` abstraction plus an Apple Speech implementation that requires on-device recognition support and does not silently fall back to a network service.
- XCTest coverage for encrypted round-trip behavior, missing files, model serialization, and unconfigured-provider behavior.
- GitHub Actions CI for simulator build and tests.

## Current limitations (read before demoing)

- Transcription uses Apple Speech and requires OS authorization and on-device recognition support for the current locale. It fails visibly if local recognition is unavailable; it does not silently fall back to a network service. A private endpoint can be added as a separate provider after a consent and data-handling review.
- The playback flow decrypts to a temporary file for AVAudioPlayer. The temporary file is removed when playback is stopped or another playback starts; abrupt process termination may leave a temporary file. A production version should use a safer lifecycle strategy and test crash recovery.
- The initial version does not implement biometric app locking, background recording guarantees, speaker diarization, remote sync, or a retention scheduler.
- Metadata is stored in a protected local JSON file but is not independently encrypted. Transcripts can contain sensitive information; production should encrypt metadata too and define backup policy.
- Audio interruptions and route changes need further explicit handling and device-level testing. The waveform in this starter is illustrative, not a live amplitude visualization.
- AES-GCM protects file confidentiality/integrity, but this alone does not make an app “enterprise secure.” Threat modeling, key lifecycle, backups, logs, memory, accessibility, and organizational policy all matter.

## Requirements

- macOS with Xcode 16 or later
- iOS 17+ simulator or device
- XcodeGen (`brew install xcodegen`)

## Build and run

```bash
brew install xcodegen
xcodegen generate
open EchoVault.xcodeproj
```

Choose an iOS simulator or your signed development device, then run the `EchoVault` scheme. Microphone permission is requested on the first recording attempt. On a device, check Settings if permission was previously denied.

## Tests

```bash
xcodebuild test \
  -project EchoVault.xcodeproj \
  -scheme EchoVault \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  CODE_SIGNING_ALLOWED=NO
```

The test target shares the app's Keychain account namespace and app-support directory in a test process. Tests remove their sample encrypted file, but the local test key may remain in Keychain. Use a dedicated test bundle/key namespace for a larger suite.

## Repository layout

```text
EchoVault/
  EchoVault/                 SwiftUI app and application services
  EchoVaultTests/            XCTest coverage
  Documentation/             Architecture, threat model, and roadmap
  .github/workflows/         Build/test CI
  project.yml                XcodeGen project definition
```

## Architecture

See [`Documentation/ARCHITECTURE.md`](Documentation/ARCHITECTURE.md) and [`Documentation/THREAT_MODEL.md`](Documentation/THREAT_MODEL.md).

## Roadmap

1. Replace illustrative waveform with metering-based visualization and robust audio interruption handling.
2. Expand the existing `OnDeviceSpeechTranscriptionProvider` with cancellation, lifecycle management, and device/locale coverage; keep network behavior explicit in UI.
3. Encrypt metadata and transcript content with a versioned envelope format.
4. Add biometric gate with `LocalAuthentication`, without treating biometrics as a substitute for file encryption.
5. Add retention policy, crash-safe temp-file cleanup, and background/foreground lifecycle tests.
6. Add performance tests for long recordings and bounded-memory transcription.
7. Add dependency review, privacy manifest review, accessibility audit, and device matrix testing.

## Interview discussion prompts

- Why encrypt after recording rather than write directly to the final vault file? How would you reduce the plaintext exposure window?
- How should key rotation and recovery work if the Keychain item is deleted?
- Which audio session category and interruption policy best match a meeting recorder?
- How would you make transcription cancellation, retries, partial results, and model-versioning testable?
- What is the threat model for a regulated enterprise customer, and which claims require evidence rather than documentation?

## License

MIT — see [`LICENSE`](LICENSE).
