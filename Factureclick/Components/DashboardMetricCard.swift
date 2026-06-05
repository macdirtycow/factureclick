//
//  DashboardMetricCard.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import SwiftUI

struct DashboardMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: systemImage)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppTheme.accentColor)

                    Spacer()
                }

                Text(value)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(AppTheme.primaryText)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppTheme.sectionTitleFont)
                        .foregroundStyle(AppTheme.primaryText)

                    Text(subtitle)
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    DashboardMetricCard(
        title: "Weekly revenue",
        value: "EUR 2,300",
        subtitle: "From invoices dated this week",
        systemImage: "chart.line.uptrend.xyaxis"
    )
    .padding()
    .background(AppTheme.screenBackground)
}
