# Security notes

## Implemented
- Audio is encrypted using AES-256-GCM before it is written to permanent app-private storage.
- The AES key is generated and held by Android Keystore and is not exported by the app.
- GCM authentication is checked during decryption; corrupted ciphertext should fail closed.
- Android backup is disabled because ciphertext cannot be restored without its device-bound key.
- Playback plaintext is written to a dedicated app-cache directory and deleted on normal completion/error.
- No network transcription fallback is implemented.

## Limitations / risks
- Metadata and transcripts in Room are not encrypted. Transcripts may be sensitive.
- Plaintext exists briefly in a staging file while recording and in cache during playback; abrupt process termination may leave temporary files.
- Recording lifecycle, interruptions, device-specific codecs, crash cleanup, and long-file memory usage require device testing.
- Keystore key loss makes ciphertext unrecoverable; key rotation/recovery is not implemented.
- On-device speech recognition availability varies by OS, provider, and language model.
- This starter has not undergone a security audit and must not be described as production-certified.