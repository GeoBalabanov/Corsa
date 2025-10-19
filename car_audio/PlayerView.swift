//
//  PlayerView.swift
//  car_audio
//
//  Created by Zhan Hrsitov on 17/10/2025.
//

import SwiftUI
import AVFoundation
import Speech

// MARK: - Model

struct Song: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let artist: String
    let url: URL
    let artworkName: String?
}

// MARK: - Player Controller (with multiple songs)

final class SimpleAVPlayerController: NSObject, ObservableObject {
    @Published private(set) var songs: [Song] = []
    @Published private(set) var currentIndex: Int = 0

    private let player = AVQueuePlayer()
    private var items: [AVPlayerItem] = []

    var currentSong: Song? { songs.indices.contains(currentIndex) ? songs[currentIndex] : nil }

    init(songs: [Song]) {
        super.init()
        self.songs = songs
        self.items = songs.map { AVPlayerItem(url: $0.url) }
        if let first = items.first { player.replaceCurrentItem(with: first) }

        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(itemDidFinish),
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )
    }

    func play()  { player.play() }
    func pause() { player.pause() }

    func next() {
        guard !items.isEmpty else { return }
        currentIndex = (currentIndex + 1) % items.count
        player.replaceCurrentItem(with: items[currentIndex])
        player.play()
    }

    func previous() {
        guard !items.isEmpty else { return }
        currentIndex = (currentIndex - 1 + items.count) % items.count
        player.replaceCurrentItem(with: items[currentIndex])
        player.play()
    }

    func setVolume(relative delta: Float) {
        let v = max(0, min(1, player.volume + delta))
        player.volume = v
    }

    func playQuery(_ text: String) {
        if let idx = songs.firstIndex(where: { $0.title.lowercased().contains(text.lowercased()) }) {
            currentIndex = idx
            player.replaceCurrentItem(with: items[currentIndex])
        }
        play()
    }

    @objc private func itemDidFinish(_ note: Notification) {
        next()
    }
}

// MARK: - Speech Recognizer

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

// MARK: - Voice Commands

struct VoiceCommandRouter {
    static func handle(text: String, player: SimpleAVPlayerController) {
        let t = text.lowercased()

        if t.contains("pause") || t.contains("stop") { player.pause(); return }
        if t.contains("next") || t.contains("skip")  { player.next(); return }
        if t.contains("previous") || t.contains("back") { player.previous(); return }
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

// MARK: - Animated Orb (no glow)

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
            .frame(width: baseSize, height: baseSize)
        }
        .drawingGroup()
    }
}

// MARK: - Player View

struct PlayerView: View {
    @StateObject private var voice = VoiceCommander()

    // 🎵 Add as many songs as you like here
    @StateObject private var player = SimpleAVPlayerController(songs: [
        Song(title: "Legends",
             artist: "Lil Baby ft. Quavo",
             url: Bundle.main.url(forResource: "Legends", withExtension: "mp3")!,
             artworkName: "image5"),
        Song(title: "Out Of My Hands", artist: "Future",
             url: Bundle.main.url(forResource: "Out Of My Hands", withExtension: "mp3")!,
             artworkName: "image5"),
        Song(title: "Plastic Bag", artist: "Future ft. Drake",
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
                    Text(voice.isListening ? "Corsa is listening" : "Tap mic or say 'Hey Corsa'")
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
                    Button { player.previous(); UIImpactFeedbackGenerator(style: .light).impactOccurred() } label: {
                        Image(systemName: "backward.end.alt.fill")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    Button {
                        player.play()
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

            // Mic Button
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

