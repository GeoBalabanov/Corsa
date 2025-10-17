//
//  ReadyToGoView.swift
//  car_audio
//
//  Created by Zhan Hrsitov on 17/10/2025.
//

import SwiftUI

struct ReadyToGoView: View {
    var onUnlock: (() -> Void)?   // optional callback

    var body: some View {
        ZStack {
            // MARK: Background (image3)
            GeometryReader { geo in
                if let ui = UIImage(named: "image4") {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .ignoresSafeArea()
                } else {
                    // Fallback if image3 not found
                    LinearGradient(colors: [Color.black, Color.black.opacity(0.94)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                        .ignoresSafeArea()
                }
            }

            // Slight dark overlay for contrast
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.55), location: 0.0),
                    .init(color: .black.opacity(0.65), location: 0.5),
                    .init(color: .black.opacity(0.75), location: 1.0)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // MARK: Car image (image7)
            GeometryReader { geo in
                if let carImage = UIImage(named: "image7") {
                    Image(uiImage: carImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width * 0.9)
                        .position(x: geo.size.width * 0.38,
                                  y: geo.size.height * 0.73)
                        .opacity(1.6)
                        .allowsHitTesting(false)
                }
            }
            .ignoresSafeArea()

            // MARK: Content
            VStack {
                // Title
                HStack {
                    Text("YOUR CAR IS\nREADY TO GO!")
                        .font(.system(size: 32, weight: .light, design: .default))
                        .italic()
                        .kerning(0.9)
                        .foregroundStyle(.white.opacity(0.95))
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                .padding(.top, 40)
                .padding(.horizontal, 28)

                Spacer()

                // Button
                Button {
                    onUnlock?()
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                } label: {
                    Text("Tap to Unlock")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.white.opacity(0.5))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(.white.opacity(0.18), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 28)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preview
struct ReadyToGoView_Previews: PreviewProvider {
    static var previews: some View {
        ReadyToGoView()
            .previewDevice("iPhone 16 Pro")
    }
}
