//
//  AppTheme.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import SwiftUI

enum AppTheme {
    static let accentColorDefaultsKey = "app.preferredAccentColorHex"
    static var accentColor: Color {
        color(hex: UserDefaults.standard.string(forKey: accentColorDefaultsKey) ?? AppAccentTheme.ocean.hex)
    }
    static let screenBackground = Color(uiColor: .systemGroupedBackground)
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let elevatedBackground = Color(uiColor: .tertiarySystemGroupedBackground)
    static let primaryText = Color(uiColor: .label)
    static let secondaryText = Color(uiColor: .secondaryLabel)
    static let shadowOpacity = 0.08

    static let titleFont = Font.system(.title2, design: .rounded).weight(.semibold)
    static let sectionTitleFont = Font.system(.headline, design: .rounded).weight(.semibold)
    static let bodyFont = Font.system(.body, design: .rounded)
    static let captionFont = Font.system(.caption, design: .rounded).weight(.medium)

    static func color(hex: String) -> Color {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard cleaned.count == 6, let value = Int(cleaned, radix: 16) else {
            return Color(
                red: 31 / 255,
                green: 111 / 255,
                blue: 229 / 255
            )
        }

        return Color(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}
