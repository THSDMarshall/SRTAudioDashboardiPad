import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var audio: AudioDiagnosticEngine
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("UMC22 Hardware Validation")
                        .font(.title2.bold())
                    Text("Connect the UMC22 before starting. Keep the amplifier volume low. This app uses native iPadOS audio, not Safari.")
                        .foregroundStyle(.secondary)
                    GroupBox("Current audio route") {
                        Text(audio.route).frame(maxWidth: .infinity, alignment: .leading)
                            .font(.system(.body, design: .monospaced))
                    }
                    HStack {
                        Button("Refresh route") { audio.refreshRoute() }
                        Spacer()
                        Button("Start audio engine") { Task { await audio.start() } }
                            .buttonStyle(.borderedProminent)
                    }
                    Button("Play test tone (440 Hz)") { audio.playTone() }
                        .buttonStyle(.borderedProminent)
                        .disabled(!audio.running)
                    Button("Stop engine") { audio.stop() }
                        .disabled(!audio.running)
                    GroupBox("Microphone") {
                        VStack(alignment: .leading) {
                            Text("Permission: \(audio.permission)")
                            ProgressView(value: Double(audio.micLevel))
                            Text("Speak into the microphone connected to UMC22 input 1. Watch the level meter. This app does not monitor the mic through software.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Text(audio.status).font(.callout).foregroundStyle(.secondary)
                }.padding(24).frame(maxWidth: 720)
            }
            .navigationTitle("SRT Audio Dashboard")
            .onAppear { audio.refreshRoute() }
        }
    }
}
