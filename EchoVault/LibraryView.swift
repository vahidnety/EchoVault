import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var library: RecordingLibrary
    @State private var showingPrivacy = false
    @State private var searchText = ""

    private var filtered: [Recording] {
        guard !searchText.isEmpty else { return library.recordings }
        return library.recordings.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) || ($0.transcript ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.035, green: 0.055, blue: 0.09).ignoresSafeArea()
                VStack(spacing: 18) {
                    header
                    recordingPanel
                    if let message = library.infoMessage { Label(message, systemImage: "checkmark.shield.fill").font(.footnote).foregroundStyle(.green).frame(maxWidth: .infinity, alignment: .leading) }
                    if let message = library.errorMessage { Label(message, systemImage: "exclamationmark.triangle.fill").font(.footnote).foregroundStyle(.orange).frame(maxWidth: .infinity, alignment: .leading) }
                    HStack { Text("YOUR VAULT").font(.caption.weight(.bold)).tracking(1.5).foregroundStyle(.secondary); Spacer(); Text("\(library.recordings.count) items").font(.caption).foregroundStyle(.secondary) }
                    if filtered.isEmpty {
                        ContentUnavailableView(searchText.isEmpty ? "Nothing recorded yet" : "No matches", systemImage: "waveform", description: Text(searchText.isEmpty ? "Your recordings stay on this device, encrypted at rest." : "Try another title or transcript keyword."))
                            .frame(maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(filtered) { recording in
                                RecordingRow(recording: recording)
                                    .listRowBackground(Color.white.opacity(0.045))
                                    .listRowSeparatorTint(.white.opacity(0.08))
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .navigationBarHidden(true)
            .searchable(text: $searchText, prompt: "Search recordings and transcripts")
            .sheet(isPresented: $showingPrivacy) { PrivacyView() }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 15).fill(LinearGradient(colors: [.cyan.opacity(0.9), .blue.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing))
                Image(systemName: "waveform.and.lock").font(.title2.weight(.semibold)).foregroundStyle(.white)
            }.frame(width: 52, height: 52)
            VStack(alignment: .leading, spacing: 3) {
                Text("EchoVault").font(.title2.bold())
                Text("Private voice intelligence").font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Button { showingPrivacy = true } label: { Image(systemName: "lock.shield").font(.title3).padding(10).background(.white.opacity(0.07), in: Circle()) }
                .accessibilityLabel("Privacy and security information")
        }
    }

    private var recordingPanel: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(library.isRecording ? "Recording in progress" : "Ready when you are")
                        .font(.headline)
                    Text(library.isRecording ? "Audio is captured locally" : "Private by default. No automatic uploads.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text(formatTime(library.elapsed)).font(.system(.title3, design: .monospaced).weight(.medium)).contentTransition(.numericText())
            }
            HStack(spacing: 4) {
                ForEach(0..<38, id: \.self) { index in
                    Capsule().fill(library.isRecording ? Color.cyan : Color.white.opacity(0.16))
                        .frame(maxWidth: .infinity).frame(height: CGFloat([12, 19, 26, 15, 32, 22, 13, 28][index % 8]))
                }
            }.frame(height: 34).accessibilityLabel(library.isRecording ? "Recording waveform animation" : "Idle waveform illustration")
            Button {
                if library.isRecording { library.stopRecording() }
                else { Task { await library.startRecording() } }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: library.isRecording ? "stop.fill" : "mic.fill")
                    Text(library.isRecording ? "Stop and secure recording" : "Start a recording")
                }
                .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(library.isRecording ? Color.red.opacity(0.88) : Color.cyan.opacity(0.9), in: RoundedRectangle(cornerRadius: 15))
                .foregroundStyle(.white)
            }
            .accessibilityHint(library.isRecording ? "Stops recording and encrypts the audio on this device" : "Requests microphone access and starts recording")
        }
        .padding(18)
        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.08), lineWidth: 1))
        .task(id: library.isRecording) {
            while library.isRecording {
                try? await Task.sleep(for: .milliseconds(250))
                library.updateElapsed()
            }
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let total = Int(time)
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

private struct RecordingRow: View {
    @EnvironmentObject private var library: RecordingLibrary
    let recording: Recording
    @State private var showTranscript = false
    @State private var showDeleteConfirmation = false
    @State private var isTranscribing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: "waveform.circle.fill").font(.system(size: 34)).foregroundStyle(.cyan)
                VStack(alignment: .leading, spacing: 4) {
                    Text(recording.title).font(.subheadline.weight(.semibold)).lineLimit(1)
                    Text("\(recording.createdAt.formatted(date: .abbreviated, time: .shortened)) · \(Int(recording.duration)) sec")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Button { library.play(recording) } label: { Image(systemName: "play.fill").frame(width: 36, height: 36).background(.white.opacity(0.08), in: Circle()) }
                    .accessibilityLabel("Play \(recording.title)")
                Menu {
                    Button { Task { isTranscribing = true; await library.transcribe(recording); isTranscribing = false } } label: { Label("Transcribe", systemImage: "text.quote") }
                    if recording.transcript != nil { Button { showTranscript.toggle() } label: { Label("View transcript", systemImage: "doc.text") } }
                    Button(role: .destructive) { showDeleteConfirmation = true } label: { Label("Delete permanently", systemImage: "trash") }
                } label: { Image(systemName: "ellipsis").padding(8) }
                .accessibilityLabel("More actions for \(recording.title)")
            }
            if isTranscribing { ProgressView("Preparing transcription…").font(.caption) }
            if showTranscript, let transcript = recording.transcript {
                Text(transcript).font(.footnote).foregroundStyle(.secondary).textSelection(.enabled)
            }
            if recording.transcript != nil && !showTranscript {
                Button("Show transcript") { showTranscript = true }.font(.caption.weight(.medium))
            }
        }
        .padding(.vertical, 5)
        .confirmationDialog("Delete this recording permanently?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete recording", role: .destructive) { library.delete(recording) }
            Button("Cancel", role: .cancel) { }
        } message: { Text("The encrypted audio file will be removed from this device.") }
    }
}

private struct PrivacyView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section("Storage") {
                    Label("Audio encrypted with AES-256-GCM", systemImage: "lock.fill")
                    Label("Encryption key stored in iOS Keychain", systemImage: "key.fill")
                    Label("Audio stays on-device by default", systemImage: "iphone")
                }
                Section("AI and transcription") {
                    Label("No audio is uploaded by the starter provider", systemImage: "icloud.slash")
                    Text("Apple Speech transcription is requested only when you choose Transcribe and runs on-device when the device and locale support it. No network fallback is enabled.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Important limitations") {
                    Text("This is an independent portfolio prototype, not a certified secure recorder. The decrypted playback file exists temporarily while playing. Device compromise, backups, screenshots, and OS-level behavior are outside this prototype's complete control.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Privacy & Security")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
}
