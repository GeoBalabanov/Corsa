//
//  PlayerView.swift
//  car_audio
//
//  Created by Zhan Hrsitov on 17/10/2025.
//

import SwiftUI
import AVFoundation
import Speech
import UIKit


// MARK: - Model

struct Song: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let artist: String
    let url: URL
    let artworkName: String?
}

// MARK: - Player Controller (multi-song, seek-to-start, toggle)

final class SimpleAVPlayerController: NSObject, ObservableObject {
    @Published private(set) var songs: [Song] = []
    @Published private(set) var currentIndex: Int = 0
    @Published private(set) var isPlaying: Bool = false

    private let player = AVQueuePlayer()
    private var items: [AVPlayerItem] = []

    var currentSong: Song? { songs.indices.contains(currentIndex) ? songs[currentIndex] : nil }

    init(songs: [Song]) {
        super.init()
        self.songs = songs
        self.items = songs.map { AVPlayerItem(url: $0.url) }
        if let first = items.first { player.replaceCurrentItem(with: first) }

        // Allow playback to continue while recording for speech
        try? AVAudioSession.sharedInstance().setCategory(
            .playAndRecord,
            mode: .default,
            options: [.mixWithOthers, .defaultToSpeaker]
        )
        try? AVAudioSession.sharedInstance().setActive(true)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(itemDidFinish),
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )
    }

    func play()  { player.play();  isPlaying = true }
    func pause() { player.pause(); isPlaying = false }
    func toggle() { isPlaying ? pause() : play() }

    // Always restart from the beginning when switching
    func next() {
        guard !items.isEmpty else { return }
        currentIndex = (currentIndex + 1) % items.count
        player.replaceCurrentItem(with: items[currentIndex])
        player.seek(to: .zero)
        play()
    }

    func previous() {
        guard !items.isEmpty else { return }
        currentIndex = (currentIndex - 1 + items.count) % items.count
        player.replaceCurrentItem(with: items[currentIndex])
        player.seek(to: .zero)
        play()
    }

    func setVolume(relative delta: Float) {
        let v = max(0, min(1, player.volume + delta))
        player.volume = v
    }

    func playQuery(_ text: String) {
        if let idx = songs.firstIndex(where: { $0.title.lowercased().contains(text.lowercased()) }) {
            currentIndex = idx
            player.replaceCurrentItem(with: items[currentIndex])
            player.seek(to: .zero)
        }
        play()
    }

    @objc private func itemDidFinish(_ note: Notification) {
        next()
    }
}

// MARK: - Speech Recognizer (fires on partials, callback-based)

final class VoiceCommander: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var isListening = false
    @Published var lastHeard: String = ""

    /// Called on every partial/full recognition update with the *raw* text (lowercased).
    var onRecognized: ((String) -> Void)?

    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async { self.isAuthorized = (status == .authorized) }
        }
        AVAudioSession.sharedInstance().requestRecordPermission { _ in }
    }

    func start() throws {
        guard !isListening else { return }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord,
                                mode: .measurement,
                                options: [.mixWithOthers, .defaultToSpeaker, .allowBluetooth])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

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
                let text = r.bestTranscription.formattedString.lowercased()
                DispatchQueue.main.async { self.lastHeard = text }
                // Route instantly on every partial update (fast + responsive)
                self.onRecognized?(text)
            }
            if error != nil {
                self.stop()
            }
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
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        DispatchQueue.main.async { self.isListening = false }
    }
}

// MARK: - Voice Commands (robust, tolerant matching)

struct VoiceCommandRouter {
    static func handle(text: String, player: SimpleAVPlayerController) {
        let t = text // already lowercased by caller

        // --- Pause ---
        if t.contains("pause") || t.contains("stop") || t.contains("quiet") {
            player.pause(); return
        }

        // --- Next ---
        if t.contains("next") || t.contains("skip") || t.contains("forward") || t.contains("skip track") || t.contains("skip song") {
            player.next(); return
        }

        // --- Previous ---
        if t.contains("previous") || t.contains("prev") || t.contains("back") || t.contains("go back") || t.contains("last song") {
            player.previous(); return
        }

        // --- Volume Up ---
        if t.contains("volume up") || t.contains("turn up") || t.contains("turn it up") || t.contains("louder") || t.contains("increase volume") || t.contains("raise volume") {
            player.setVolume(relative: +0.15); return
        }

        // --- Volume Down ---
        if t.contains("volume down") || t.contains("turn down") || t.contains("turn it down") || t.contains("quieter") || t.contains("decrease volume") || t.contains("lower volume") {
            player.setVolume(relative: -0.15); return
        }

        // --- Play Specific Song / Play ---
        if t.contains("play") {
            if let idx = player.songs.firstIndex(where: { t.contains($0.title.lowercased()) }) {
                player.playQuery(player.songs[idx].title)
                return
            }
            player.play()
        }
    }
}

// MARK: - Animated Orb

struct CorsaSiriImage: View {
    var isListening: Bool
    private let baseSize: CGFloat = 170

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
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
            .frame(width: 300, height: 200)
        }
        .drawingGroup()
    }
}

// MARK: - Player View

struct PlayerView: View {
    @StateObject private var voice = VoiceCommander()

    // 🎵 Add as many songs as you like here (ensure files exist in bundle)
    @StateObject private var player = SimpleAVPlayerController(songs: [
        Song(title: "Legends",
             artist: "Lil Baby ft. Quavo",
             url: Bundle.main.url(forResource: "Legends", withExtension: "mp3")!,
             artworkName: "image5"),
        Song(title: "Out Of My Hands",
             artist: "Future",
             url: Bundle.main.url(forResource: "Out Of My Hands", withExtension: "mp3")!,
             artworkName: "image5"),
        Song(title: "Plastic Bag",
             artist: "Future ft. Drake",
             url: Bundle.main.url(forResource: "Plastic Bag", withExtension: "mp3")!,
             artworkName: "image5")
    ])

    var body: some View {
        ZStack {
            // Background
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
                            Image(player.currentSong?.artworkName ?? "image5")
                                .resizable()
                                .scaledToFill()
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        )

                    Text("\(player.currentSong?.title ?? "—") is currently playing")
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

                VStack(spacing: 12) {
                    CorsaSiriImage(isListening: voice.isListening)
                    Text(voice.isListening ? "Corsa is listening" : "Tap mic to start voice commands")
                        .italic()
                        .foregroundStyle(.white.opacity(0.85))
                }

                Spacer()

                // Song info
                VStack(spacing: 6) {
                    Text(player.currentSong?.title ?? "—")
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(player.currentSong?.artist ?? "—")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white.opacity(0.75))
                }
                .padding(.bottom, 8)

                // Controls
                HStack(spacing: 46) {
                    Button {
                        player.previous()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Image(systemName: "backward.end.alt.fill")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    Button {
                        player.toggle()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        ZStack {
                            Circle().fill(.white.opacity(0.15)).frame(width: 68, height: 68)
                                .overlay(Circle().stroke(.white.opacity(0.25), lineWidth: 1))
                            Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }

                    Button {
                        player.next()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Image(systemName: "forward.end.alt.fill")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.bottom, 30)
            }

            // Mic Button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        if voice.isListening {
                            voice.stop()
                        } else {
                            if !voice.isAuthorized { voice.requestAuthorization() }
                            Task { try? voice.start() }
                        }
                        UINotificationFeedbackGenerator().notificationOccurred(.success)

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
        }
        .onAppear {
            voice.requestAuthorization()
            // Wire the voice recognizer to your player
            voice.onRecognized = { recognizedText in
                VoiceCommandRouter.handle(text: recognizedText, player: player)
            }
        }
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
