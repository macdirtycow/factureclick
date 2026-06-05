//
//  QuoteStatusChip.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import SwiftUI

struct QuoteStatusChip: View {
    let status: QuoteStatus

    var body: some View {
        Text(status.displayName)
            .font(AppTheme.captionFont)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(backgroundColor, in: Capsule())
    }

    private var foregroundColor: Color {
        switch status {
        case .draft:
            AppTheme.secondaryText
        case .sent:
            AppTheme.accentColor
        case .accepted:
            .green
        case .rejected:
            .red
        case .expired:
            .orange
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .draft:
            AppTheme.elevatedBackground
        case .sent:
            AppTheme.accentColor.opacity(0.12)
        case .accepted:
            Color.green.opacity(0.14)
        case .rejected:
            Color.red.opacity(0.14)
        case .expired:
            Color.orange.opacity(0.14)
        }
    }
}
