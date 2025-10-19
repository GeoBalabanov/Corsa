//
//  ContentView.swift
//  car_audio
//
//  Created by Zhan Hrsitov on 16/10/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        // LibraryView already contains its own NavigationStack
        // and pushes to ReadyToGoView / PlayerView from its buttons.
        LibraryView()
    }
}

#Preview {
    ContentView()
}

