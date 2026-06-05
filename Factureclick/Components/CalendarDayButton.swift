//
//  CalendarDayButton.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import SwiftUI

struct CalendarDayButton: View {
    let day: AgendaDay
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(day.dayLabel.uppercased())
                    .font(.system(.caption2, design: .rounded).weight(.semibold))
                    .foregroundStyle(labelColor)

                Text(day.dayNumber)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(labelColor)
                    .frame(width: 34, height: 34)
                    .background(badgeBackground)
                    .clipShape(Circle())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(containerBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var containerBackground: Color {
        if isSelected {
            return AppTheme.accentColor.opacity(0.14)
        }
        if day.isToday {
            return AppTheme.cardBackground
        }
        return Color.clear
    }

    private var badgeBackground: Color {
        isSelected ? AppTheme.accentColor : Color.clear
    }

    private var labelColor: Color {
        isSelected ? AppTheme.accentColor : AppTheme.primaryText
    }
}

#Preview {
    HStack {
        CalendarDayButton(
            day: AgendaDay(date: .now, isToday: true),
            isSelected: true
        ) { }
    }
    .padding()
    .background(AppTheme.screenBackground)
}
