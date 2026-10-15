# EchoVault — Private Voice Intelligence

**An independent mobile engineering portfolio project. Not affiliated with Cohere.**

EchoVault explores native audio capture, encrypted local storage, a replaceable transcription boundary, and privacy-oriented UX. It includes separate native implementations for iOS and Android. Both are working starters rather than production security certifications.

## Platforms

- **iOS (SwiftUI):** native audio capture, AES-GCM encrypted recordings, Keychain-backed key, local metadata, playback/deletion, and an on-device Apple Speech provider.
- **Android (Kotlin + Jetpack Compose):** native recording, AES-256-GCM encryption using Android Keystore, Room metadata, playback/deletion/search, and an on-device speech-recognition availability adapter.

See the [Android project](android/README.md), [Android architecture](android/docs/ARCHITECTURE.md), and [Android security notes](android/docs/SECURITY.md).

## iOS implementation

- SwiftUI screens with accessible controls and clear recording states.
- Native audio capture with permission handling, AAC recording, elapsed-time updates, and audio-session activation/deactivation.
- AES-GCM authenticated encryption of recordings before they are persisted.
- A 256-bit symmetric key stored in iOS Keychain with `WhenUnlockedThisDeviceOnly` accessibility.
- Local metadata persistence, search across titles/transcripts, playback, delete, and user-visible errors.
- A `TranscriptionProvider` abstraction plus an Apple Speech implementation that requires on-device recognition support and does not silently fall back to a network service.
- XCTest coverage for encrypted round-trip behavior, missing files, model serialization, and unconfigured-provider behavior.
- GitHub Actions CI for simulator build and tests.

## Current limitations (read before demoing)

- iOS transcription uses Apple Speech and requires OS authorization and on-device recognition support for the current locale. It fails visibly if local recognition is unavailable; it does not silently fall back to a network service.
- iOS playback decrypts to a temporary file for AVAudioPlayer. The temporary file is removed when playback finishes, is stopped, or another playback starts; abrupt process termination may still leave a temporary file.
- Android saved-recording transcription is not implemented. Its current adapter only checks on-device recognizer availability and exposes a microphone transcription API.
- Android metadata and transcripts in Room are not encrypted; iOS metadata is also not independently encrypted. Treat transcripts as sensitive.
- Neither platform currently implements biometric app locking, remote sync, or a retention scheduler. Audio interruptions, route changes, crash recovery, and device-level behavior require more testing.
- AES-GCM is one security control, not proof that an app is “enterprise secure.” Threat modeling, key lifecycle, backups, logs, memory, accessibility, and policy all matter.

## Requirements

### iOS
- macOS with Xcode 16 or later
- iOS 17+ simulator or device
- XcodeGen (`brew install xcodegen`)

### Android
- Android Studio with JDK 17
- Android SDK Platform 35
- Android 8.0 / API 26 or later

## Build and run — iOS

```bash
brew install xcodegen
xcodegen generate
open EchoVault.xcodeproj
```

Choose an iOS simulator or signed development device, then run the `EchoVault` scheme.

Run tests with:

```bash
xcodebuild test \
  -project EchoVault.xcodeproj \
  -scheme EchoVault \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  CODE_SIGNING_ALLOWED=NO
```

## Build and run — Android

Open the `android/` directory in Android Studio, allow Gradle sync, and run the `app` configuration on an emulator or device with a microphone. With Gradle 8.9 and Android SDK installed:

```bash
gradle -p android testDebugUnitTest
gradle -p android assembleDebug
```

## Repository layout

```text
EchoVault/                 SwiftUI iOS app
EchoVaultTests/            XCTest coverage
Documentation/             iOS architecture and threat model
android/                   Kotlin + Jetpack Compose Android app
.github/workflows/         iOS and Android CI
project.yml                XcodeGen project definition
```

## Roadmap

1. Add crash-safe temporary-file cleanup and explicit audio interruption handling on both platforms.
2. Encrypt metadata and transcript content with a versioned envelope format.
3. Implement saved-recording on-device transcription on Android and test locale/device coverage.
4. Add biometric gating without treating biometrics as a substitute for file encryption.
5. Add retention policy, performance tests, accessibility audits, and a device matrix.
6. Review dependency supply chain and platform privacy disclosures.

## License

MIT — see [LICENSE](LICENSE).
