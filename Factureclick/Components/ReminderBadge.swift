//
//  ReminderBadge.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import SwiftUI

struct ReminderBadge: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(AppTheme.captionFont)
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.12), in: Capsule())
    }
}

#Preview {
    ReminderBadge(title: "Friendly Reminder", systemImage: "bell", tint: .blue)
        .padding()
        .background(AppTheme.screenBackground)
}
