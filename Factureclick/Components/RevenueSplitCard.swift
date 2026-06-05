//
//  RevenueSplitCard.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import SwiftUI

struct RevenueSplitCard: View {
    let title: String
    let summary: CollaborationRevenueSummary
    let localization: AppLocalization

    var body: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 14) {
                Text(title)
                    .font(AppTheme.sectionTitleFont)
                    .foregroundStyle(AppTheme.primaryText)

                splitRow(localization.phrase("Gross"), currency(summary.grossAmount))
                splitRow(localization.phrase("Partner share"), currency(summary.partnerShare))
                splitRow(localization.phrase("You keep"), currency(summary.userNetAmount), emphasize: true)

                if !summary.partnerSummaries.isEmpty {
                    Divider()

                    ForEach(summary.partnerSummaries) { partner in
                        splitRow(
                            "\(partner.partnerName) (\(partner.percentage.formatted(.number.precision(.fractionLength(0...2))))%)",
                            currency(partner.partnerShare)
                        )
                    }
                }
            }
        }
    }

    private func splitRow(_ title: String, _ value: String, emphasize: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(emphasize ? AppTheme.sectionTitleFont : AppTheme.bodyFont)
                .foregroundStyle(emphasize ? AppTheme.primaryText : AppTheme.secondaryText)

            Spacer()

            Text(value)
                .font(emphasize ? AppTheme.sectionTitleFont : AppTheme.bodyFont)
                .foregroundStyle(AppTheme.primaryText)
        }
    }

    private func currency(_ value: Double) -> String {
        let formatter = AppFormatters.currencyFormatter()
        return formatter.string(from: NSNumber(value: value)) ?? "EUR 0.00"
    }
}
