//
//  PlayerView.swift
//  car_audio
//
//  Created by Zhan Hrsitov on 17/10/2025.
//

import SwiftUI
import AVFoundation
import Speech

// MARK: - Playback abstraction (swap to Spotify/MusicKit later if you want)

protocol PlayerController {
    func play()
    func pause()
    func next()
    func previous()
    func setShuffle(_ on: Bool)
    func setRepeat(_ on: Bool)
    func setVolume(relative delta: Float) // -1...+1
    func playQuery(_ text: String)
}

// MARK: - Simple AVPlayer-backed controller (actually plays audio)

final class SimpleAVPlayerController: NSObject, PlayerController {
    private let player = AVQueuePlayer()
    private var items: [AVPlayerItem] = []
    private var index = 0

    /// Provide your own audio URLs (remote HTTPS streams or local bundle files).
    init(urls: [URL] = [
        // Replace these with your tracks
        URL(string: "https://files.freemusicarchive.org/storage-freemusicarchive-org/music/no_curator/Komiku/It_is_time_for_adventure/Komiku_-_03_-_Friends.mp3")!,
        URL(string: "https://files.freemusicarchive.org/storage-freemusicarchive-org/music/no_curator/Komiku/It_is_time_for_adventure/Komiku_-_13_-_Battle_of_Pogs.mp3")!
    ]) {
        super.init()
        self.items = urls.map { AVPlayerItem(url: $0) }
        if let first = items.first { player.replaceCurrentItem(with: first) }

        // Playback category so app audio is audible even if mic is active at times.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func play()  { player.play() }
    func pause() { player.pause() }

    func next() {
        guard !items.isEmpty else { return }
        index = (index + 1) % items.count
        player.replaceCurrentItem(with: items[index])
        player.play()
    }

    func previous() {
        guard !items.isEmpty else { return }
        index = (index - 1 + items.count) % items.count
        player.replaceCurrentItem(with: items[index])
        player.play()
    }

    func setShuffle(_ on: Bool) {
        guard on, !items.isEmpty else { return }
        items.shuffle()
        index = 0
        player.replaceCurrentItem(with: items[index])
        player.play()
    }

    func setRepeat(_ on: Bool) {
        // Simple repeat-all behavior
        if on {
            NotificationCenter.default.addObserver(self, selector: #selector(loopIfNeeded), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        } else {
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        }
    }

    @objc private func loopIfNeeded() {
        next()
    }

    func setVolume(relative delta: Float) {
        let v = max(0, min(1, player.volume + delta))
        player.volume = v
    }

    func playQuery(_ text: String) {
        // Demo: just starts playing (hook actual search here if desired)
        play()
    }
}

// MARK: - Speech recognizer (unchanged)

final class VoiceCommander: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var isListening = false
    @Published var lastHeard: String = ""

    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async { self.isAuthorized = (status == .authorized) }
        }
    }

    func start() throws {
        guard !isListening else { return }
        try AVAudioSession.sharedInstance().setCategory(.record, mode: .measurement, options: .duckOthers)
        try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)

        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        request = req

        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        task = recognizer?.recognitionTask(with: req) { [weak self] result, error in
            guard let self else { return }
            if let r = result {
                DispatchQueue.main.async { self.lastHeard = r.bestTranscription.formattedString }
            }
            if error != nil || (result?.isFinal == true) { self.stop() }
        }

        DispatchQueue.main.async { self.isListening = true }
    }

    func stop() {
        if audioEngine.isRunning { audioEngine.stop() }
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        DispatchQueue.main.async { self.isListening = false }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

// MARK: - Voice → actions

struct VoiceCommandRouter {
    static func handle(text: String, player: PlayerController) {
        let t = text.lowercased()

        if t.contains("pause") || t.contains("stop") { player.pause(); return }
        if t.contains("next") || t.contains("skip")  { player.next(); return }
        if t.contains("previous") || t.contains("back") { player.previous(); return }

        if t.contains("shuffle on")  { player.setShuffle(true);  return }
        if t.contains("shuffle off") { player.setShuffle(false); return }
        if t.contains("repeat on")   { player.setRepeat(true);   return }
        if t.contains("repeat off")  { player.setRepeat(false);  return }

        if t.contains("volume up")   || t.contains("turn it up")   { player.setVolume(relative: +0.15); return }
        if t.contains("volume down") || t.contains("turn it down") { player.setVolume(relative: -0.15); return }

        if let r = t.range(of: "play ") {
            let q = String(t[r.upperBound...]).trimmingCharacters(in: .whitespaces)
            if q.isEmpty { player.play() } else { player.playQuery(q) }
        } else if t.contains("play") {
            player.play()
        }
    }
}

// MARK: - Siri-style animated orb 

struct CorsaSiriImage: View {
    var isListening: Bool
    private let baseSize: CGFloat = 170

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate

            // Faster, livelier motion when listening
            let speed  = isListening ? 1.8 : 0.7
            let pulseA = isListening ? 0.08 : 0.035
            let wiggle = isListening ? 10.0 : 4.0

            let scale = 1 + pulseA * CGFloat(sin(t * speed))
            let rot   = Angle(degrees: Double(sin(t * speed * 0.6)) * (isListening ? 4 : 1.6))
            let x     = CGFloat(sin(t * speed * 0.9)) * wiggle * 0.4
            let y     = CGFloat(cos(t * speed * 0.8)) * wiggle

            ZStack {
                Image("image5")
                    .resizable()
                    .scaledToFit()
                    .frame(width: baseSize, height: baseSize)
                    .rotationEffect(rot)
                    .scaleEffect(scale)
                    .offset(x: x, y: y)
                    .shadow(color: .white.opacity(0.18), radius: isListening ? 12 : 6, y: 2)
            }
            .frame(width: baseSize, height: baseSize)
        }
        .drawingGroup()
        .accessibilityHidden(true)
    }
}

// MARK: - Player Screen

struct PlayerView: View {
    @StateObject private var voice = VoiceCommander()
    private let player: PlayerController = SimpleAVPlayerController() // 🔊 now plays real audio

    // Demo text; replace with live "now playing" if you wire to a service
    @State private var trackTitle = "Blinding Lights"
    @State private var trackArtist = "The Weeknd"
    @State private var nowPlayingBanner = "Late night drive is currently playing"

    var body: some View {
        ZStack {
            // Background leather (image3)
            GeometryReader { geo in
                Image("image3")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea()
            }

            VStack(spacing: 24) {
                // Now playing banner
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.white.opacity(0.15))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image("image5")
                                .resizable().scaledToFill()
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        )
                    Text(nowPlayingBanner)
                        .foregroundStyle(.white.opacity(0.92))
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                    Spacer()
                }
                .padding(10)
                .background(.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 14))
                .padding(.top, 8)
                .padding(.horizontal, 12)

                Spacer()

                // Siri-like animated image + subtitle
                VStack(spacing: 12) {
                    CorsaSiriImage(isListening: voice.isListening)
                    Text(voice.isListening ? "Corsa is listening" : "Tap mic or say 'Hey Corsa'")
                        .italic()
                        .foregroundStyle(.white.opacity(0.85))
                }

                Spacer()

                // Title + artist
                VStack(spacing: 6) {
                    Text(trackTitle)
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(trackArtist)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white.opacity(0.75))
                }
                .padding(.bottom, 8)

                // Transport controls
                HStack(spacing: 46) {
                    Button { player.previous(); UIImpactFeedbackGenerator(style: .light).impactOccurred() } label: {
                        Image(systemName: "backward.end.alt.fill")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    Button {
                        player.play() // toggle with your real state if needed
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        ZStack {
                            Circle().fill(.white.opacity(0.15)).frame(width: 68, height: 68)
                                .overlay(Circle().stroke(.white.opacity(0.25), lineWidth: 1))
                            Image(systemName: "play.fill")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }

                    Button { player.next(); UIImpactFeedbackGenerator(style: .light).impactOccurred() } label: {
                        Image(systemName: "forward.end.alt.fill")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.bottom, 30)
            }

            // Mic toggle
            VStack {
                HStack {
                    Spacer()
                    Button {
                        if voice.isListening { voice.stop() }
                        else {
                            if !voice.isAuthorized { voice.requestAuthorization() }
                            Task { try? voice.start() }
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Image(systemName: voice.isListening ? "mic.fill" : "mic")
                            .font(.system(size: 18, weight: .bold))
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                            .shadow(radius: 4, y: 2)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                Spacer()
            }
            .allowsHitTesting(true)
        }
        .onChange(of: voice.lastHeard) { text in
            VoiceCommandRouter.handle(text: text, player: player)
        }
        .onAppear { voice.requestAuthorization() }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preview

struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView()
            .previewDevice("iPhone 16 Pro")
    }
}
