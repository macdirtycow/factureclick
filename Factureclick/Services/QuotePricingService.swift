//
//  QuotePricingService.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation

struct QuoteLineDraft: Identifiable, Hashable {
    let id: UUID
    var linkedProductID: UUID?
    var description: String
    var quantity: Double
    var unitPrice: Double
    var vatRate: Double

    init(
        id: UUID = UUID(),
        linkedProductID: UUID? = nil,
        description: String = "",
        quantity: Double = 1,
        unitPrice: Double = 0,
        vatRate: Double = 21
    ) {
        self.id = id
        self.linkedProductID = linkedProductID
        self.description = description
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.vatRate = vatRate
    }
}

struct QuoteLineTotals: Hashable {
    let netAmount: Double
    let vatAmount: Double
    let totalAmount: Double
}

struct QuoteTotals: Hashable {
    let subtotal: Double
    let vat: Double
    let total: Double
}

struct QuotePricingService {
    func calculation(for line: QuoteLineDraft) -> QuoteLineTotals {
        let netAmount = line.quantity * line.unitPrice
        let vatAmount = netAmount * (line.vatRate / 100)

        return QuoteLineTotals(
            netAmount: netAmount,
            vatAmount: vatAmount,
            totalAmount: netAmount + vatAmount
        )
    }

    func makeTotals(lines: [QuoteLineDraft]) -> QuoteTotals {
        let calculations = lines.map(calculation(for:))
        return QuoteTotals(
            subtotal: calculations.reduce(0) { $0 + $1.netAmount },
            vat: calculations.reduce(0) { $0 + $1.vatAmount },
            total: calculations.reduce(0) { $0 + $1.totalAmount }
        )
    }
}
