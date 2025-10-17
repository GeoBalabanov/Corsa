//
//  PlayerView.swift
//  car_audio
//
//  Created by Zhan Hrsitov on 17/10/2025.
//

import SwiftUI
import AVFoundation
import Speech

// MARK: - Playback abstraction (plug your Spotify controller here)

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

// Temporary mock so the view runs. Replace with your real Spotify controller.
final class MockSpotifyController: PlayerController {
    func play() { print("▶️ play") }
    func pause() { print("⏸ pause") }
    func next() { print("⏭ next") }
    func previous() { print("⏮ previous") }
    func setShuffle(_ on: Bool) { print("🔀 shuffle:", on) }
    func setRepeat(_ on: Bool) { print("🔁 repeat:", on) }
    func setVolume(relative delta: Float) { print("🔊 volume delta:", delta) }
    func playQuery(_ text: String) { print("🎯 play query:", text) }
}

// MARK: - Speech recognizer

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

        // "play ..." → search/resolve via Spotify
        if let r = t.range(of: "play ") {
            let q = String(t[r.upperBound...]).trimmingCharacters(in: .whitespaces)
            if q.isEmpty { player.play() } else { player.playQuery(q) }
        } else if t.contains("play") {
            player.play()
        }
    }
}

// MARK: - Siri-style animated image using your asset `image5`

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
                // soft glow
                Circle()
                    .fill(.white.opacity(isListening ? 0.18 : 0.10))
                    .frame(width: baseSize * 1.35, height: baseSize * 1.35)
                    .blur(radius: isListening ? 28 : 18)
                    .scaleEffect(scale)
                    .blendMode(.plusLighter)

                // your image5 orb
                Image("image5")
                    .resizable()
                    .scaledToFit()
                    .frame(width: baseSize, height: baseSize)
                    .rotationEffect(rot)
                    .scaleEffect(scale)
                    .offset(x: x, y: y)
                    .shadow(color: .white.opacity(0.25), radius: isListening ? 16 : 8, y: 3)
            }
            .frame(width: baseSize, height: baseSize)
        }
        .drawingGroup()
        .accessibilityHidden(true)
    }
}

// MARK: - Spotlight overlay (for the leather highlight)

struct EllipticalSpotlight: View {
    var center: UnitPoint
    var radius: CGSize

    var body: some View {
        GeometryReader { geo in
            let m = min(geo.size.width, geo.size.height)
            let w = m * radius.width
            let h = m * radius.height
            let x = geo.size.width  * center.x
            let y = geo.size.height * center.y

            RadialGradient(
                stops: [
                    .init(color: .white.opacity(0.28), location: 0.0),
                    .init(color: .white.opacity(0.10), location: 0.28),
                    .init(color: .clear,               location: 1.0)
                ],
                center: .center, startRadius: 0, endRadius: max(w, h)
            )
            .frame(width: w * 2.0, height: h * 2.0)
            .position(x: x, y: y)
            .scaleEffect(x: 1.0, y: h / w)
            .blur(radius: 22)
            .blendMode(.plusLighter)
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Player Screen

struct PlayerView: View {
    @StateObject private var voice = VoiceCommander()
    private let player: PlayerController = MockSpotifyController() // swap with real controller

    // Demo text; replace with live Spotify now playing
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

            EllipticalSpotlight(center: .init(x: 0.40, y: 0.52),
                                radius: .init(width: 0.95, height: 0.55))

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
                        player.play() // toggle with your real state
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
