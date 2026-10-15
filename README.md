# EchoVault — Private Voice Intelligence

**An independent mobile engineering portfolio project. Not affiliated with Cohere.**

EchoVault explores native audio capture, encrypted local storage, transcription boundaries, and privacy-oriented UX. The repository contains separate native apps for iOS and Android.

## Project structure

- **[iOS](iOS/)** — SwiftUI app, XCTest suite, XcodeGen configuration, architecture docs, and threat model.
- **[Android](android/)** — Kotlin + Jetpack Compose app, Room metadata, Android Keystore AES-GCM encryption, tests, and security/architecture docs.

Each platform has its own folder and build instructions. Both are starter implementations, not production security certifications.

## Suggested technical architecture

The apps should share the same **product-level boundaries**, while keeping platform-specific implementations native. This is a suggested direction for the next iteration, not a claim that every component is already implemented.

### Cross-platform design principles

- **Presentation:** UI renders state and forwards user actions; it should not own encryption or file-storage logic.
- **Application/domain layer:** a library or recording coordinator manages recording sessions, save/discard, playback, search, deletion, and transcription requests.
- **Audio adapters:** isolate operating-system recording and playback APIs behind small interfaces so they can be tested and replaced.
- **Secure storage:** encrypt audio before permanent storage; keep key material in the platform's secure key store; centralize authenticated decryption and deletion.
- **Metadata repository:** persist recording IDs, timestamps, duration, file references, and transcription status. Treat transcripts and other descriptive metadata as sensitive.
- **Transcription boundary:** define a provider interface that makes on-device versus network processing explicit. Do not upload audio unless the user has been informed and has explicitly opted in.
- **Reliability:** model recording/transcription as explicit states, handle permission denial and audio interruptions, and clean up temporary plaintext files on success, failure, cancellation, and app restart where possible.

### iOS architecture (native Swift / SwiftUI)

**Suggested flow:** SwiftUI views → observable view model / app coordinator → recording-library use cases → audio, encrypted-vault, metadata, and transcription interfaces.

\`\`\`mermaid
flowchart TD
    UI[SwiftUI Views] --> VM[ViewModel / Library Coordinator]
    VM --> USE[Recording and Library Use Cases]
    USE --> CAP[AVFoundation Capture / Playback]
    CAP --> STAGE[Temporary Audio Staging]
    STAGE --> VAULT[VaultStore: AES-GCM]
    KEY[Keychain Key] --> VAULT
    VAULT --> FILES[App Support: Encrypted Audio]
    USE --> META[Metadata Repository]
    META --> DB[(Suggested: SQLite / Core Data)]
    USE --> TX[TranscriptionProvider Interface]
    TX --> ONDEVICE[On-device Speech Adapter]
    TX -. optional, disclosed and consented .-> REMOTE[Approved Remote Provider]
\`\`\`

- **Current foundation:** SwiftUI, AVFoundation, `RecordingLibrary`, `VaultStore`, AES-GCM with a Keychain-backed key, metadata persistence, and a `TranscriptionProvider` seam.
- **Suggested next steps:** add explicit protocols for audio capture and persistence, inject storage/key dependencies for tests, move metadata to a transactional database if the library grows, encrypt transcripts, and formalize interruption/cancellation state handling.
- **Speech recognition:** keep provider behavior explicit. A provider that is unconfigured should fail visibly rather than silently sending recordings to a server.

See [iOS architecture details](iOS/Documentation/ARCHITECTURE.md) and the [iOS threat model](iOS/Documentation/THREAT_MODEL.md).

### Android architecture (native Kotlin / Jetpack Compose)

**Suggested flow:** Compose screens → `ViewModel` → recording/library use cases → repository interfaces → MediaRecorder/MediaPlayer, encrypted file storage, Room, and transcription adapters.

\`\`\`mermaid
flowchart TD
    UI[Compose UI] --> VM[ViewModel]
    VM --> USE[Recording and Library Use Cases]
    USE --> REC[RecordingRepository]
    REC --> CAP[MediaRecorder / MediaPlayer Adapters]
    CAP --> STAGE[Temporary Audio Staging]
    STAGE --> CRYPTO[AudioCrypto: AES-256-GCM]
    KEY[Android Keystore Key] --> CRYPTO
    CRYPTO --> FILES[App-private Encrypted Audio Files]
    REC --> META[Metadata DAO / Repository]
    META --> DB[(Room Database)]
    USE --> TX[Transcription Interface]
    TX --> ONDEVICE[On-device Recognition Adapter]
    TX -. optional, disclosed and consented .-> REMOTE[Approved Remote Provider]
\`\`\`

- **Current foundation:** Kotlin, Jetpack Compose, a recording repository, MediaRecorder/MediaPlayer, AES-256-GCM with a non-exportable Android Keystore key, Room metadata, and an on-device recognizer availability adapter.
- **Suggested next steps:** define repository/audio interfaces for easier testing, model recording and playback lifecycle states, implement transcription for saved recordings, encrypt transcript content, and improve cleanup/recovery after process death.
- **Speech recognition:** saved-recording transcription is not implemented in this starter. The current adapter checks on-device recognizer availability and exposes microphone transcription functionality; there is no silent online fallback.

See [Android architecture details](android/docs/ARCHITECTURE.md) and [Android security notes](android/docs/SECURITY.md).

### Recommended recording lifecycle

\`\`\`mermaid
flowchart TD
    A[Request microphone permission] --> B{Granted?}
    B -- No --> C[Show clear permission guidance]
    B -- Yes --> D[Record to temporary staging file]
    D --> E{User saves recording?}
    E -- No --> F[Delete staging file]
    E -- Yes --> G[Encrypt audio with authenticated encryption]
    G --> H{Encryption successful?}
    H -- No --> I[Delete plaintext staging file and show error]
    H -- Yes --> J[Persist encrypted file and metadata]
    J --> K[Offer playback or transcription]
    K --> L[Clean up temporary plaintext after use]
\`\`\`

### Security and production-readiness notes

- Use authenticated encryption with a unique nonce/IV for every encryption operation; never reuse a nonce with the same AES-GCM key.
- Store keys in Keychain / Android Keystore and never hard-code or log keys, plaintext audio, or transcripts.
- Encrypt transcripts and consider sensitive metadata at rest; the current starter does **not** independently encrypt metadata/transcripts on either platform.
- Temporary plaintext may remain after abrupt termination. Add startup recovery/cleanup, interruption handling, and lifecycle tests.
- Define retention and deletion behavior, including temporary files and metadata; test that deleting a recording removes all related local artifacts.
- Consider database migrations, backup exclusions, storage exhaustion, corrupted files, key invalidation, and device-lock behavior.
- Document the threat model and user consent for any remote transcription provider.
- These projects are portfolio starters and have not undergone an independent security audit.

## iOS

- [iOS app source](iOS/EchoVault/)
- [iOS tests](iOS/EchoVaultTests/)
- [iOS architecture](iOS/Documentation/ARCHITECTURE.md)
- [iOS threat model](iOS/Documentation/THREAT_MODEL.md)

Build on macOS with Xcode 16+ and XcodeGen:

\`\`\`bash
cd iOS
brew install xcodegen
xcodegen generate
open EchoVault.xcodeproj
\`\`\`

Run tests using an available iOS simulator:

\`\`\`bash
cd iOS
xcodebuild test -project EchoVault.xcodeproj -scheme EchoVault -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO
\`\`\`

## Android

- [Android project and setup](android/README.md)
- [Android architecture](android/docs/ARCHITECTURE.md)
- [Android security notes](android/docs/SECURITY.md)

Open the `android/` directory in Android Studio with JDK 17 and Android SDK Platform 35. With Gradle 8.9 installed:

\`\`\`bash
gradle -p android testDebugUnitTest
gradle -p android assembleDebug
\`\`\`

## Security and limitations

- iOS audio uses AES-GCM with a Keychain-backed key; Android audio uses AES-256-GCM with Android Keystore.
- Android saved-recording transcription is not implemented yet. Its current adapter checks on-device recognizer availability and exposes a microphone transcription API.
- Metadata and transcripts are not independently encrypted on either platform. Treat transcripts as sensitive.
- Temporary plaintext audio can remain after abrupt process termination; crash cleanup and lifecycle handling need further hardening.
- Neither platform has undergone an independent security audit. AES-GCM alone does not establish production security.

## CI

GitHub Actions workflows build/test the iOS project and run Android unit tests plus a debug APK assembly.

## License

MIT — see [LICENSE](LICENSE).
