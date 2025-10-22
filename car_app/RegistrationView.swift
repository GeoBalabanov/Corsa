//
//  RegistrationView.swift
//  Car app
//
//  Created by Georgi Balabanov on 16/10/2025.
//

import SwiftUI

// MARK: - Music providers

enum MusicProvider: String, CaseIterable, Identifiable {
    case spotify = "Spotify"
    case appleMusic = "Apple Music"
    case youtubeMusic = "Youtube Music"

    var id: String { rawValue }

    // Brand-tinted backgrounds (tweak to match your Figma)
    var gradient: LinearGradient {
        switch self {
        case .spotify:
            return LinearGradient(colors: [Color(hex: 0x193A22), Color(hex: 0x0F2A1A), .black.opacity(0.9)],
                                  startPoint: .top, endPoint: .bottom)
        case .appleMusic:
            return LinearGradient(colors: [Color(hex: 0x3F0B15), Color(hex: 0x2A0A0E), .black.opacity(0.9)],
                                  startPoint: .top, endPoint: .bottom)
        case .youtubeMusic:
            return LinearGradient(colors: [Color(hex: 0x3F0B0B), Color(hex: 0x220606), .black.opacity(0.9)],
                                  startPoint: .top, endPoint: .bottom)
        }
    }

    var accent: Color {
        switch self {
        case .spotify:      return Color(hex: 0x1DB954)
        case .appleMusic:   return Color(hex: 0xFA2449)
        case .youtubeMusic: return Color(hex: 0xFF3B30)
        }
    }

    var openURL: URL {
        switch self {
        case .spotify:      return URL(string: "https://open.spotify.com/")!
        case .appleMusic:   return URL(string: "https://music.apple.com/")!
        case .youtubeMusic: return URL(string: "https://music.youtube.com/")!
        }
    }

    var instructionsTitle: String {
        switch self {
        case .spotify:      return "Finding the right Spotify link:"
        case .appleMusic:   return "Finding the right Apple Music link:"
        case .youtubeMusic: return "Finding the right YouTube Music link:"
        }
    }

    // Add these logo assets to Assets.xcassets or replace names
    var logoAsset: String {
        switch self {
        case .spotify:      return "logo_spotify"
        case .appleMusic:   return "logo_applemusic"
        case .youtubeMusic: return "logo_youtubemusic"
        }
    }

    var placeholder: String {
        switch self {
        case .spotify:      return "https://open.spotify.com/user/your-id"
        case .appleMusic:   return "https://music.apple.com/user/your-id"
        case .youtubeMusic: return "https://music.youtube.com/channel/your-id"
        }
    }
}

// MARK: - Registration View

struct RegistrationView: View {
    @Environment(\.openURL) private var openURL
    @State private var provider: MusicProvider = .spotify
    @State private var profileURL: String = ""
    @State private var showInvalidAlert = false

    var body: some View {
        ZStack {
            provider.gradient.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {

                    ProviderTabs(provider: $provider)

                    // Logo
                    HStack {
                        Image(provider.logoAsset)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 56, height: 56)
                            .accessibilityHidden(true)
                        Spacer()
                    }
                    .padding(.top, 8)

                    // Title
                    (Text("Enter your ")
                        .foregroundStyle(.white)
                     + Text(provider.rawValue)
                        .foregroundStyle(provider.accent)
                     + Text("\nprofile link")
                        .foregroundStyle(.white))
                        .font(.system(size: 34, weight: .bold))

                    // URL field
                    HStack(spacing: 10) {
                        Image(systemName: "link")
                            .foregroundStyle(.white.opacity(0.7))
                        TextField(provider.placeholder, text: $profileURL)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                            .autocorrectionDisabled(true)
                            .foregroundStyle(.white)
                    }
                    .padding(16)
                    .background(.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.18), lineWidth: 1)
                    )

                    // Open app/site
                    Button {
                        openURL(provider.openURL)
                    } label: {
                        Text("Open \(provider.rawValue)")
                            .font(.headline)
                            .foregroundStyle(provider.accent)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)

                    // Instructions
                    VStack(alignment: .leading, spacing: 10) {
                        Text(provider.instructionsTitle)
                            .font(.headline)
                            .foregroundStyle(.white)

                        VStack(alignment: .leading, spacing: 8) {
                            switch provider {
                            case .spotify:
                                Bullet("Visit your profile page on Spotify")
                                Bullet("Tap the '…' and then the share icon")
                                Bullet("Choose 'Copy Link'")
                                Bullet("Paste the link in the field above")
                            case .appleMusic:
                                Bullet("Open your profile in Apple Music")
                                Bullet("Use the share sheet to copy your link")
                                Bullet("Paste the link in the field above")
                            case .youtubeMusic:
                                Bullet("Open your YouTube Music channel page")
                                Bullet("Use share → copy link")
                                Bullet("Paste the link in the field above")
                            }
                        }
                    }
                    .padding(.top, 4)

                    // Continue
                    Button {
                        if isValidURL(profileURL) {
                            // TODO: navigate to playlist choice (or save to model)
                            print("Valid URL: \(profileURL)")
                        } else {
                            showInvalidAlert = true
                        }
                    } label: {
                        Text("Continue")
                            .font(.system(size: 20, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.white.opacity(0.22))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .padding(.top, 8)
                    .alert("Invalid link", isPresented: $showInvalidAlert) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text("Please paste a valid \(provider.rawValue) profile URL.")
                    }

                    // Skip option — centered + cycles providers
                    Button {
                        switch provider {
                        case .spotify:      provider = .appleMusic
                        case .appleMusic:   provider = .youtubeMusic
                        case .youtubeMusic: provider = .spotify
                        }
                    } label: {
                        Text("Skip, my music isn’t on \(provider.rawValue)")
                            .foregroundStyle(.white.opacity(0.75))
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 8)
                }
                .padding(.horizontal, 24)
                .padding(.top, 22)
                .padding(.bottom, 32)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden) // cleaner top area
    }

    private func isValidURL(_ text: String) -> Bool {
        guard let url = URL(string: text) else { return false }
        return ["http", "https"].contains(url.scheme?.lowercased() ?? "")
    }
}

// MARK: - Tabs

private struct ProviderTabs: View {
    @Binding var provider: MusicProvider

    var body: some View {
        HStack(spacing: 22) {
            ForEach(MusicProvider.allCases) { item in
                VStack(spacing: 8) {
                    Capsule()
                        .fill(item == provider ? .white : .white.opacity(0.35))
                        .frame(width: 92, height: 6)

                    Text(item.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .contentShape(Rectangle())
                .onTapGesture { provider = item }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Bullet row

private struct Bullet: View {
    var text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(.white.opacity(0.9))
                .frame(width: 6, height: 6)
                .padding(.top, 7)
            Text(text)
                .foregroundStyle(.white.opacity(0.92))
                .font(.body)
        }
    }
}





