# Security and privacy threat model (starter)

## Assets

- Recorded audio and derived transcripts
- Recording titles, timestamps, duration, and usage patterns
- Encryption key and user consent state

## Intended protections

- Audio files are encrypted with AES-GCM before being written to the vault.
- The key is stored in Keychain with `WhenUnlockedThisDeviceOnly` accessibility.
- The default transcription provider does not send data over the network.
- The UI describes local-first behavior and makes deletion available.

## Trust boundaries

1. Microphone and iOS audio subsystem → temporary recording file.
2. Temporary plaintext → encryption boundary.
3. Encrypted file storage ↔ Keychain key access.
4. Decrypted playback/transcription temporary file → AVFoundation/provider.
5. Transcript result → metadata persistence.

## Out of scope / known gaps

- A compromised or jailbroken device, malicious OS, screen capture, or a user with device-unlock access.
- Metadata and transcript confidentiality: metadata is not encrypted in this starter.
- Guaranteed deletion from flash storage, filesystem snapshots, device backups, or forensic recovery.
- Plaintext temporary-file cleanup after force termination.
- Biometric gating, key rotation, multi-user separation, enterprise MDM policy, remote endpoint security, and regulatory compliance.

## Required before production

- Encrypt metadata and transcripts; specify backup and retention policy.
- Reduce plaintext lifetime and use crash-safe cleanup; evaluate streaming encryption.
- Use per-install/per-user key identifiers and define key loss/rotation behavior.
- Add explicit consent flows and recording indicators appropriate to local law and workplace policy.
- Audit all network calls and telemetry; never log audio, transcripts, keys, or sensitive titles.
- Conduct dependency, privacy-manifest, accessibility, and penetration reviews.
- Validate behavior on supported physical devices and iOS versions.

**Security claims are limited to the implemented controls above. This document is not a certification or legal assessment.**
