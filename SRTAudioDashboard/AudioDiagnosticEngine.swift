import Foundation
import AVFoundation

@MainActor
final class AudioDiagnosticEngine: ObservableObject {
    @Published var status = "Ready to configure audio"
    @Published var route = "Not configured"
    @Published var micLevel: Float = 0
    @Published var inputAvailable = false
    @Published var running = false
    @Published var permission = "Not requested"

    private var engine: AVAudioEngine?
    private var player: AVAudioPlayerNode?
    private var meterInstalled = false

    init() {
        NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification,
                                               object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.refreshRoute() }
        }
    }

    func refreshRoute() {
        let session = AVAudioSession.sharedInstance()
        let ins = session.currentRoute.inputs.map { "\($0.portName) [\($0.portType.rawValue)]" }
        let outs = session.currentRoute.outputs.map { "\($0.portName) [\($0.portType.rawValue)]" }
        route = "Input: \(ins.isEmpty ? "none" : ins.joined(separator: ", "))\nOutput: \(outs.isEmpty ? "none" : outs.joined(separator: ", "))"
        inputAvailable = !session.currentRoute.inputs.isEmpty
    }

    func start() async {
        stop()
        let session = AVAudioSession.sharedInstance()
        do {
            // Native play-and-record session. USB routing is controlled by iPadOS.
            // Do not force the built-in speaker with .defaultToSpeaker.
            try session.setCategory(.playAndRecord, mode: .default, options: [])
            try session.setPreferredSampleRate(48_000)
            try session.setActive(true)
            refreshRoute()
            let granted: Bool = await withCheckedContinuation { continuation in
                session.requestRecordPermission { continuation.resume(returning: $0) }
            }
            permission = granted ? "Granted" : "Denied"
            guard granted else { status = "Microphone permission denied in iPad Settings"; return }
            let newEngine = AVAudioEngine()
            let newPlayer = AVAudioPlayerNode()
            newEngine.attach(newPlayer)
            let format = newEngine.outputNode.inputFormat(forBus: 0)
            newEngine.connect(newPlayer, to: newEngine.mainMixerNode, format: format)
            let input = newEngine.inputNode
            let inputFormat = input.outputFormat(forBus: 0)
            if inputFormat.channelCount > 0 {
                input.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
                    guard let samples = buffer.floatChannelData?[0] else { return }
                    let count = Int(buffer.frameLength)
                    guard count > 0 else { return }
                    var sum: Float = 0
                    for i in 0..<count { sum += samples[i] * samples[i] }
                    let rms = sqrt(sum / Float(count))
                    Task { @MainActor [weak self] in self?.micLevel = min(1, rms * 10) }
                }
                meterInstalled = true
            }
            try newEngine.start()
            engine = newEngine
            player = newPlayer
            running = true
            refreshRoute()
            status = "Native audio engine running"
        } catch {
            status = "Audio setup error: \(error.localizedDescription)"
            refreshRoute()
        }
    }

    func playTone() {
        guard let engine, let player, running else {
            status = "Start audio engine first"; return
        }
        let outputFormat = engine.outputNode.inputFormat(forBus: 0)
        let sampleRate = outputFormat.sampleRate
        let frames = AVAudioFrameCount(sampleRate * 2)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: frames),
              let channels = buffer.floatChannelData else {
            status = "Cannot create tone buffer for current output format"; return
        }
        buffer.frameLength = frames
        for ch in 0..<Int(outputFormat.channelCount) {
            for i in 0..<Int(frames) {
                let fade = min(1.0, Double(i) / (sampleRate * 0.02), Double(Int(frames) - i) / (sampleRate * 0.02))
                channels[ch][i] = Float(sin(2 * Double.pi * 440 * Double(i) / sampleRate) * 0.10 * max(0, fade))
            }
        }
        player.stop()
        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        player.play()
        status = "Playing 440 Hz test tone for 2 seconds"
    }

    func stop() {
        player?.stop()
        if meterInstalled { engine?.inputNode.removeTap(onBus: 0) }
        meterInstalled = false
        engine?.stop()
        engine = nil
        player = nil
        running = false
        micLevel = 0
        refreshRoute()
    }
}
