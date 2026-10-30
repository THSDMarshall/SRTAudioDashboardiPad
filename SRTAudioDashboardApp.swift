import SwiftUI

@main
struct SRTAudioDashboardApp: App {
    @StateObject private var audio = AudioDiagnosticEngine()
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(audio)
        }
    }
}
