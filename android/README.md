# EchoVault Android

Native Android counterpart to EchoVault, built with Kotlin, Jetpack Compose Material 3, Room, Android Keystore, and Android audio APIs. Local-first and privacy-oriented.

## Features
- Compose library UI and runtime microphone permission handling.
- Record, save/discard, playback, search, and deletion.
- AES-256-GCM audio encryption before permanent app storage, with a non-exportable Android Keystore key.
- Room metadata persistence; temporary app-cache playback plaintext is deleted after playback completes or fails.
- On-device speech-recognizer availability check with no silent online fallback. Existing-recording transcription is not implemented in this starter.
- Unit/instrumentation tests and GitHub Actions CI.

## Requirements
Android Studio, JDK 17, Android SDK Platform 35. Minimum Android API 26. Speech availability depends on Android version, recognizer service, and installed language models.

Open this directory in Android Studio and allow Gradle sync. Run `app` on a device/emulator with a microphone. Or, with Gradle 8.9 and Android SDK installed, run `gradle testDebugUnitTest` and `gradle assembleDebug`.

**Status:** starter implementation, not a security audit or production-ready release. Metadata/transcripts are not encrypted, saved-recording transcription is not implemented, and device lifecycle/security testing remains necessary. See `docs/SECURITY.md` and `docs/ARCHITECTURE.md`.

## Stack
Kotlin 2.0.21, Android Gradle Plugin 8.7.3, Jetpack Compose Material 3, Room 2.6.1, KSP, MediaRecorder/MediaPlayer, AES/GCM/NoPadding, Android Keystore. MIT license.