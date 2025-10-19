//
//  LibraryView.swift
//  car_audio
//
//  Created by Zhan Hrsitov on 16/10/2025.
//

import SwiftUI

// MARK: - Model

struct Playlist: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let coverURL: URL?
}

// MARK: - View

struct LibraryView: View {
    @State private var selected: Playlist? = nil
    @State private var showReady = false

    private let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 18), count: 3)

    private let playlists: [Playlist] = [
        Playlist(title: "Chill",      subtitle: "zhanhristov",   coverURL: URL(string: "https://picsum.photos/id/10/300/300")),
        Playlist(title: "Bangers",    subtitle: "zhanhristov",   coverURL: URL(string: "https://picsum.photos/id/1027/300/300")),
        Playlist(title: "Sleeping",   subtitle: "zhanhristov",   coverURL: URL(string: "https://picsum.photos/id/1069/300/300")),
        Playlist(title: "Late drive", subtitle: "zhanhristov",   coverURL: URL(string: "https://picsum.photos/id/111/300/300")),
        Playlist(title: "Friends",    subtitle: "zhan & georgi", coverURL: URL(string: "https://picsum.photos/id/237/300/300")),
        Playlist(title: "Focus",      subtitle: "corsa",         coverURL: URL(string: "https://picsum.photos/id/28/300/300"))
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                // ✅ REAL, FULL-SCREEN BACKDROP (covers under the home indicator)
                LeatherBackdropReplica()

                VStack(spacing: 16) {
                    // Header — left icons, middle spacer, right title+avatar
                    HStack(spacing: 12) {
                        HStack(spacing: 12) {
                            RoundIcon(system: "magnifyingglass")
                            RoundIcon(system: "plus")
                        }

                        Spacer(minLength: 8)

                        HStack(spacing: 12) {
                            Text("Your Library")
                                .font(.system(size: 28, weight: .semibold, design: .rounded))
                                .kerning(0.3)
                                .lineLimit(1)
                            Avatar()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 6)

                    // Grid
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, alignment: .center, spacing: 18) {
                            ForEach(playlists) { item in
                                PlaylistCard(item: item, isSelected: selected?.id == item.id)
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            selected = item
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 15)

                        InstructionCard()
                            .padding(.horizontal, 16)
                            .padding(.top, 50)

                        // CTA Button
                        Button {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            showReady = true
                        } label: {
                            Text("Click & Select")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(.white.opacity(0.12))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(.white.opacity(0.18), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)

                        VStack(spacing: 4) {
                            Text("Want to change platforms?")
                                .foregroundStyle(.white.opacity(0.65))
                                .font(.footnote)
                            Button { } label: {
                                Text("Go back to Login page.")
                                    .font(.footnote.weight(.semibold))
                                    .underline()
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding(.vertical, 18)
                    }
                    .padding(.top, 18)
                }

                // Hidden NavigationLink trigger
                NavigationLink(destination: ReadyToGoView(), isActive: $showReady) { EmptyView() }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Background (robust loader for file OR asset)

struct LeatherBackdropReplica: View {
    var body: some View {
        Group {
            if let ui = UIImage(named: "image4") {      // file in bundle OR asset
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
            } else if UIImage(named: "image4.png") != nil,   // sometimes extension matters
                      let ui = UIImage(named: "image4.png") {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
            } else {
                // Last resort: neutral gradient
                LinearGradient(colors: [Color.black, Color.black.opacity(0.94)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
        .ignoresSafeArea() // <- important
    }
}

// MARK: - Small UI components

struct RoundIcon: View {
    var system: String
    var body: some View {
        Image(systemName: system)
            .font(.system(size: 16, weight: .semibold))
            .frame(width: 36, height: 36)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .foregroundStyle(.white)
    }
}

struct Avatar: View {
    var body: some View {
        Circle()
            .fill(AngularGradient(colors: [.purple, .pink, .blue, .purple], center: .center))
            .overlay(Circle().stroke(.white.opacity(0.35), lineWidth: 1))
            .frame(width: 36, height: 36)
            .accessibilityLabel("Profile")
    }
}

struct PlaylistCard: View {
    let item: Playlist
    var isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            AsyncImage(url: item.coverURL) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.white.opacity(0.06))
                        .overlay(ProgressView().tint(.white.opacity(0.7)))
                case .success(let image):
                    image.resizable()
                        .scaledToFill()
                        .frame(height: 92)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                case .failure:
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.white.opacity(0.06))
                        .overlay(
                            Image(systemName: "music.note.list")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.65))
                        )
                @unknown default:
                    EmptyView()
                }
            }
            .frame(height: 92)
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.9), .white.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                }
            }

            Text(item.title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .lineLimit(1)

            Text(item.subtitle)
                .foregroundStyle(.white.opacity(0.7))
                .font(.system(size: 11, weight: .regular))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

struct InstructionCard: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.black.opacity(0.35))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            RadialGradient(colors: [.white.opacity(0.22), .clear],
                           center: .center, startRadius: 20, endRadius: 240)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .blendMode(.plusLighter)

            VStack(alignment: .leading, spacing: 8) {
                Text("Quick instructions:")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))

                VStack(alignment: .leading, spacing: 8) {
                    Label("Playlist will be played on shuffle", systemImage: "dot.square.fill")
                    Label("No access to queue",               systemImage: "dot.square.fill")
                    Label("No album covers",                  systemImage: "dot.square.fill")
                    Label("Only media player access",         systemImage: "dot.square.fill")
                }
                .labelStyle(InstructionBulletStyle())
                .foregroundStyle(.white.opacity(0.8))
                .font(.system(size: 14))
            }
            .padding(18)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
    }
}

struct InstructionBulletStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            configuration.icon
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(.white.opacity(0.55))
            configuration.title
        }
    }
}

// MARK: - Preview

struct LibraryView_Previews: PreviewProvider {
    static var previews: some View {
        LibraryView()
            .previewDevice("iPhone 16 Pro")
    }
}
