//
//  Color+Hex.swift
//  Car app
//
//  Created by Georgi Balabanov on 16/10/2025.
//

import SwiftUI

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self = Color(red: r, green: g, blue: b, opacity: alpha)
    }
}
