//
//  InvoiceFinancialCalculationService.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation

struct InvoiceLineCalculation: Hashable {
    let netAmount: Double
    let vatAmount: Double
    let grossAmount: Double
}

struct InvoiceFinancialCalculationService {
    func calculation(for line: InvoiceLineDraft) -> InvoiceLineCalculation {
        let netAmount = line.quantity * line.unitPrice
        let vatAmount = netAmount * (line.vatRate / 100)

        return InvoiceLineCalculation(
            netAmount: netAmount,
            vatAmount: vatAmount,
            grossAmount: netAmount + vatAmount
        )
    }

    func makeTotals(lines: [InvoiceLineDraft], collaborationRule: CollaborationRule?) -> InvoiceDraftTotals {
        let calculations = lines.map { ($0, calculation(for: $0)) }

        let subtotal = calculations
            .filter { $0.0.kind == .productService }
            .reduce(0) { $0 + $1.1.netAmount }

        let discounts = calculations
            .filter { $0.0.kind == .discount }
            .reduce(0) { $0 + abs($1.1.netAmount) }

        let extraCharges = calculations
            .filter { $0.0.kind == .extraCharge }
            .reduce(0) { $0 + $1.1.netAmount }

        let travelCosts = calculations
            .filter { $0.0.kind == .travelCost }
            .reduce(0) { $0 + $1.1.netAmount }

        let materialCosts = calculations
            .filter { $0.0.kind == .materialCost }
            .reduce(0) { $0 + $1.1.netAmount }

        let manualAdjustments = calculations
            .filter { $0.0.kind == .manualAdjustment }
            .reduce(0) { $0 + $1.1.netAmount }

        let gross = subtotal + extraCharges + travelCosts + materialCosts + manualAdjustments
        let netSubtotal = gross - discounts
        let vat = calculations.reduce(0) { $0 + $1.1.vatAmount }
        let total = netSubtotal + vat

        let partnerShare = netSubtotal * ((collaborationRule?.percentage ?? 0) / 100)
        let netIncome = netSubtotal - partnerShare

        let vatBreakdown = Dictionary(grouping: calculations) { $0.0.vatRate }
            .map { rate, groupedLines in
                InvoiceVATBreakdown(
                    rate: rate,
                    taxableAmount: groupedLines.reduce(0) { $0 + $1.1.netAmount },
                    vatAmount: groupedLines.reduce(0) { $0 + $1.1.vatAmount }
                )
            }
            .sorted { $0.rate < $1.rate }

        return InvoiceDraftTotals(
            subtotal: subtotal,
            netSubtotal: netSubtotal,
            vat: vat,
            total: total,
            gross: gross,
            discounts: discounts,
            extraCharges: extraCharges,
            travelCosts: travelCosts,
            materialCosts: materialCosts,
            manualAdjustments: manualAdjustments,
            partnerShare: partnerShare,
            netIncome: netIncome,
            vatBreakdown: vatBreakdown
        )
    }
}
