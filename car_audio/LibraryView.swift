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
    @State private var showSearch: Bool = false

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
        ZStack {
            LeatherBackdrop()

            VStack(spacing: 16) {

                // Tiny overline
                HStack {
                    Text("Playlist choice")
                        .foregroundStyle(.white.opacity(0.7))
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .kerning(0.3)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)

                // Header row: search, add, title centered, avatar
                HStack(spacing: 12) {

                    // Search icon button (opens sheet with search field if you want later)
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showSearch.toggle()
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    // Add icon button
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    Spacer(minLength: 8)

                    // Center title
                    Text("Your Library")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .kerning(0.3)

                    Spacer(minLength: 8)

                    // Avatar
                    Circle()
                        .fill(AngularGradient(colors: [.purple, .pink, .blue, .purple], center: .center))
                        .overlay(Circle().stroke(.white.opacity(0.35), lineWidth: 1))
                        .frame(width: 36, height: 36)
                        .accessibilityLabel("Profile")
                }
                .padding(.horizontal, 16)

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
                    .padding(.horizontal, 16)
                    .padding(.top, 6)

                    // Instructions card
                    InstructionCard()
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    // CTA
                    Button {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    } label: {
                        Text("Click & Select")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white.opacity(0.12)))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(.white.opacity(0.18), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 6)

                    // Footer link
                    VStack(spacing: 4) {
                        Text("Want to change platforms?")
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                        Button { } label: {
                            Text("Go back to Login page.")
                                .font(.footnote.weight(.semibold))
                                .underline()
                        }
                    }
                    .padding(.vertical, 18)
                }
            }
            .padding(.bottom, 2)
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSearch) {
            // Optional: simple search sheet to mirror the icon behavior
            SearchSheet()
        }
    }
}

// MARK: - Components

struct PlaylistCard: View {
    let item: Playlist
    var isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: item.coverURL, transaction: .init(animation: .easeInOut)) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.white.opacity(0.06))
                        ProgressView().tint(.white.opacity(0.7))
                    }
                case .success(let image):
                    image
                        .resizable()
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
                        .stroke(LinearGradient(colors: [.white.opacity(0.9), .white.opacity(0.2)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
                }
            }

            Text(item.title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .lineLimit(1)

            Text(item.subtitle)
                .foregroundStyle(.secondary)
                .font(.system(size: 11, weight: .regular))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title) by \(item.subtitle)")
    }
}

struct InstructionCard: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.black.opacity(0.35))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            // Soft spotlight
            RadialGradient(colors: [.white.opacity(0.22), .clear], center: .center, startRadius: 20, endRadius: 240)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .blendMode(.plusLighter)

            VStack(alignment: .leading, spacing: 10) {
                Text("Quick instructions:")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))

                VStack(alignment: .leading, spacing: 8) {
                    Label("Playlist will be played on shuffle", systemImage: "dot.square.fill")
                    Label("No access to queue", systemImage: "dot.square.fill")
                    Label("No album covers", systemImage: "dot.square.fill")
                    Label("Only media player access", systemImage: "dot.square.fill")
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

struct LeatherBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.black, Color.black.opacity(0.92)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            RadialGradient(colors: [.clear, .black.opacity(0.55)],
                           center: .center, startRadius: 0, endRadius: 520)
                .ignoresSafeArea()

            Rectangle()
                .fill(.black.opacity(0.04))
                .blendMode(.overlay)
                .allowsHitTesting(false)
        }
    }
}

// Optional: search sheet shown after tapping the magnifier
struct SearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                TextField("Search", text: $query)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .padding(.horizontal, 12)
                    .frame(height: 44)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 16)
                Spacer()
            }
            .navigationTitle("Search")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preview

struct LibraryView_Previews: PreviewProvider {
    static var previews: some View {
        LibraryView()
            .previewDevice("iPhone 16 Pro")
    }
}
