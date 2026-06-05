//
//  QuickActionCard.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import SwiftUI

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.accentColor)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.accentColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppTheme.sectionTitleFont)
                        .foregroundStyle(AppTheme.primaryText)

                    Text(subtitle)
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SectionCard {
        QuickActionCard(
            title: "Create Invoice",
            subtitle: "Jump to unpaid billing workflows",
            systemImage: "doc.badge.plus"
        ) { }
    }
    .padding()
    .background(AppTheme.screenBackground)
}
