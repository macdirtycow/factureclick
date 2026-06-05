//
//  FilterChip.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import SwiftUI

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.captionFont)
                .foregroundStyle(isSelected ? Color.white : AppTheme.primaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? AppTheme.accentColor : AppTheme.elevatedBackground, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
