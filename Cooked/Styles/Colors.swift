//
//  Colors.swift
//  Cooked
//
//  Created by David James on 04/04/2026.
//

import SwiftUI

extension Color {
    
    static let primaryColor = Color(hex: 0xFFA22F)
    static let secondaryColor = Color(hex: 0xE050B5)
}


private extension Color {
    init(hex: Int, opacity: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}
