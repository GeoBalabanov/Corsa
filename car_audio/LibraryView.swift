//
//  LibraryView.swift
//  car_audio
//
//  Created by Zhan Hrsitov on 16/10/2025.
//

import SwiftUI

// MARK: - Models
struct Playlist: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let imageName: String   // name in Assets
}

// MARK: - Mock data (replace image names with your asset names)
let mockPlaylists: [Playlist] = [
    .init(title: "Chill",      subtitle: "zhanhristov",  imageName: "chill"),
    .init(title: "Bangers",    subtitle: "zhanhristov",  imageName: "bangers"),
    .init(title: "Sleeping",   subtitle: "zhanhristov",  imageName: "sleeping"),
    .init(title: "Late drive", subtitle: "zhanhristov",  imageName: "latedrive"),
    .init(title: "Friends",    subtitle: "zhan & georgi",imageName: "friends")
]

// MARK: - Main View
struct LibraryView: View {
    // 3 equal columns like the screenshot
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 18), count: 3)

    var body: some View {
        ZStack {
            BackgroundTexture()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    // Top title
                    Text("Playlist choice")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)

                    // Toolbar row
                    HStack {
                        HStack(spacing: 22) {
                            Image(systemName: "magnifyingglass")
                            Image(systemName: "plus")
                        }
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.85))

                        Spacer()

                        Text("Your Library")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(.white)

                        Spacer()

                        // Avatar
                        Image("avatar") // add a circular image named "avatar" to Assets
                            .resizable()
                            .scaledToFill()
                            .frame(width: 34, height: 34)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                            .shadow(radius: 3, y: 1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)

                    // Grid
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 18) {
                        ForEach(mockPlaylists) { pl in
                            PlaylistCard(playlist: pl)
                        }
                        // placeholder empty to balance the grid visually
                        Color.clear.frame(height: 0)
                    }
                    .padding(.top, 6)

                    // Quick instructions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick instructions:")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)

                        VStack(alignment: .leading, spacing: 10) {
                            Bullet("Playlist will be played on shuffle")
                            Bullet("No access to queue")
                            Bullet("No album covers")
                            Bullet("Only media player access")
                        }
                    }
                    .padding(.top, 10)

                    // CTA Button
                    Button(action: {
                        // TODO: handle select action
                    }) {
                        Text("Click & Select")
                            .font(.system(size: 20, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(PrimaryPillButton())
                    .padding(.top, 10)

                    // Footer link
                    VStack(spacing: 6) {
                        Text("Want to change platforms?")
                            .foregroundStyle(.secondary)
                        Button {
                            // TODO: navigate to login
                        } label: {
                            Text("Go back to Login page.")
                                .underline()
                        }
                        .tint(.white.opacity(0.9))
                    }
                    .padding(.vertical, 14)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Components
struct PlaylistCard: View {
    let playlist: Playlist

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(playlist.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 96, height: 96)
                .clipped()
                .cornerRadius(2)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )

            Text(playlist.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)

            Text(playlist.subtitle)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(width: 104, alignment: .leading)
    }
}

struct Bullet: View {
    var text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Circle()
                .fill(.white.opacity(0.9))
                .frame(width: 6, height: 6)
                .offset(y: 2)
            Text(text)
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.85))
        }
    }
}

struct PrimaryPillButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(configuration.isPressed ? 0.16 : 0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.6), radius: 12, y: 2)
            .contentShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Background
struct BackgroundTexture: View {
    var body: some View {
        ZStack {
            // If you have a leather/pebble texture, add it as "leatherTexture" in Assets
            // Otherwise, this gradient + noise gives a similar vibe.
            LinearGradient(
                colors: [Color.black, Color(red: 0.08, green: 0.08, blue: 0.09)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Radial spotlight like the screenshot
            RadialGradient(
                colors: [
                    .white.opacity(0.12),
                    .clear
                ],
                center: .center,
                startRadius: 10,
                endRadius: 360
            )
            .blendMode(.screen)
            .ignoresSafeArea()

            // Subtle noise overlay
            NoiseOverlay(opacity: 0.08)
                .ignoresSafeArea()
        }
    }
}

struct NoiseOverlay: View {
    var opacity: CGFloat = 0.1
    var body: some View {
        Canvas { ctx, size in
            let rect = CGRect(origin: .zero, size: size)
            // procedural noise dots
            let density = Int(size.width * size.height / 700)
            for _ in 0..<density {
                let x = CGFloat.random(in: 0...size.width)
                let y = CGFloat.random(in: 0...size.height)
                let dot = Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1))
                ctx.fill(dot, with: .color(.white.opacity(opacity)))
            }
            ctx.fill(Path(rect), with: .color(.clear))
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Preview
#Preview {
    LibraryView()
}
