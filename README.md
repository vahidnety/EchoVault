# EchoVault — Private Voice Intelligence

**An independent mobile engineering portfolio project. Not affiliated with Cohere.**

EchoVault explores native audio capture, encrypted local storage, transcription boundaries, and privacy-oriented UX. The repository contains separate native apps for iOS and Android.

## Project structure

- **[iOS](iOS/)** — SwiftUI app, XCTest suite, XcodeGen configuration, architecture docs, and threat model.
- **[Android](android/)** — Kotlin + Jetpack Compose app, Room metadata, Android Keystore AES-GCM encryption, tests, and security/architecture docs.

Each platform has its own folder and build instructions. Both are starter implementations, not production security certifications.

## iOS

- [iOS app source](iOS/EchoVault/)
- [iOS tests](iOS/EchoVaultTests/)
- [iOS architecture](iOS/Documentation/ARCHITECTURE.md)
- [iOS threat model](iOS/Documentation/THREAT_MODEL.md)

Build on macOS with Xcode 16+ and XcodeGen:

```bash
cd iOS
brew install xcodegen
xcodegen generate
open EchoVault.xcodeproj
```

Run tests using an available iOS simulator:

```bash
cd iOS
xcodebuild test -project EchoVault.xcodeproj -scheme EchoVault -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO
```

## Android

- [Android project and setup](android/README.md)
- [Android architecture](android/docs/ARCHITECTURE.md)
- [Android security notes](android/docs/SECURITY.md)

Open the `android/` directory in Android Studio with JDK 17 and Android SDK Platform 35. With Gradle 8.9 installed:

```bash
gradle -p android testDebugUnitTest
gradle -p android assembleDebug
```

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
