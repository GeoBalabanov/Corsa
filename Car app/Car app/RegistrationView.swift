//
//  RegistrationView.swift
//  Car app
//
//  Created by Georgi Balabanov on 16/10/2025.
//

import SwiftUI

struct RegistrationView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Text("Registration")
                .foregroundStyle(.white)
        }
        .navigationTitle("Register")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview { RegistrationView() }
