//
//  CollaborationRevenueService.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation

struct CollaborationRevenueBreakdown {
    let grossAmount: Double
    let partnerShare: Double
    let userNetAmount: Double
    let partnerName: String?
    let percentage: Double
}

struct CollaborationPartnerSummary: Identifiable {
    let partnerName: String
    let grossAmount: Double
    let partnerShare: Double
    let userNetAmount: Double
    let percentage: Double

    var id: String { partnerName }
}

struct CollaborationRevenueSummary {
    let grossAmount: Double
    let partnerShare: Double
    let userNetAmount: Double
    let partnerSummaries: [CollaborationPartnerSummary]
}

struct CollaborationRevenueService {
    func effectiveRule(for entry: WorkEntry) -> CollaborationRule? {
        entry.collaborationRule ?? entry.client.collaborationRules.first
    }

    func makeBreakdown(grossAmount: Double, rule: CollaborationRule?) -> CollaborationRevenueBreakdown {
        let percentage = rule?.percentage ?? 0
        let partnerShare = grossAmount * (percentage / 100)

        return CollaborationRevenueBreakdown(
            grossAmount: grossAmount,
            partnerShare: partnerShare,
            userNetAmount: grossAmount - partnerShare,
            partnerName: rule?.partnerName.isEmpty == false ? rule?.partnerName : nil,
            percentage: percentage
        )
    }

    func makeSummary(for entries: [WorkEntry]) -> CollaborationRevenueSummary {
        let billableEntries = entries.filter(\.includeInInvoice)
        let grossAmount = billableEntries.reduce(0) { $0 + $1.billableAmount }

        let partnerBuckets = Dictionary(grouping: billableEntries.compactMap { entry -> (String, Double, Double, Double)? in
            guard let rule = effectiveRule(for: entry), !rule.partnerName.isEmpty else { return nil }
            let breakdown = makeBreakdown(grossAmount: entry.billableAmount, rule: rule)
            return (rule.partnerName, rule.percentage, breakdown.partnerShare, entry.billableAmount)
        }) { $0.0 }

        let partnerSummaries = partnerBuckets.map { partnerName, values in
            let totalPartnerShare = values.reduce(0) { $0 + $1.2 }
            let totalGross = values.reduce(0) { $0 + $1.3 }
            let percentage = values.first?.1 ?? 0

            return CollaborationPartnerSummary(
                partnerName: partnerName,
                grossAmount: totalGross,
                partnerShare: totalPartnerShare,
                userNetAmount: totalGross - totalPartnerShare,
                percentage: percentage
            )
        }
        .sorted { $0.partnerShare > $1.partnerShare }

        let partnerShare = partnerSummaries.reduce(0) { $0 + $1.partnerShare }

        return CollaborationRevenueSummary(
            grossAmount: grossAmount,
            partnerShare: partnerShare,
            userNetAmount: grossAmount - partnerShare,
            partnerSummaries: partnerSummaries
        )
    }
}
