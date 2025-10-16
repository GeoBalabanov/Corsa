//
//  LandingView.swift
//  Car app
//
//  Created by Georgi Balabanov on 16/10/2025.
//

import SwiftUI

struct LandingView: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: 0x2B0B54),
                    Color(hex: 0x6D2BCE)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Head image fixed to bottom-left
            Image("landingHead")  // make sure this matches the asset name
                .resizable()
                .scaledToFit()
                .ignoresSafeArea(edges: .bottom)
                .padding(.bottom, -50)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Text content
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Just listen.")
                    Text("Corsa handles the rest.")
                }
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(.white)

                NavigationLink {
                    RegistrationView()
                } label: {
                    HStack(spacing: 6) {
                        Text("To register")
                        Image(systemName: "arrow.right")
                            .font(.body.weight(.semibold))
                            .baselineOffset(-1)
                    }
                    .foregroundStyle(.white.opacity(0.9))
                    .underline()
                }

                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.top, 90)
        }
        .statusBarHidden(true)
    }
}

#Preview {
    LandingView()
}

