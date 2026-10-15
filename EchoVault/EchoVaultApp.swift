import SwiftUI

@main
struct EchoVaultApp: App {
    @StateObject private var library = RecordingLibrary()

    var body: some Scene {
        WindowGroup {
            LibraryView()
                .environmentObject(library)
                .preferredColorScheme(.dark)
        }
    }
}
