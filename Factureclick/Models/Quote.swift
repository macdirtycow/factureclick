//
//  Quote.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation
import SwiftData

@Model
final class Quote {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var quoteNumber: String
    var date: Date
    var expiryDate: Date
    var statusRawValue: String
    var subtotalAmount: Double
    var vatAmount: Double
    var totalAmount: Double
    var notes: String
    var createdAt: Date
    var updatedAt: Date

    var client: Client

    @Relationship(deleteRule: .cascade, inverse: \QuoteLine.quote)
    var lines: [QuoteLine]

    var status: QuoteStatus {
        get { QuoteStatus(rawValue: statusRawValue) ?? .draft }
        set { statusRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        quoteNumber: String = "",
        client: Client,
        date: Date = .now,
        expiryDate: Date = .now,
        status: QuoteStatus = .draft,
        subtotalAmount: Double = 0,
        vatAmount: Double = 0,
        totalAmount: Double = 0,
        notes: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now,
        lines: [QuoteLine] = []
    ) {
        self.id = id
        self.quoteNumber = quoteNumber
        self.client = client
        self.date = date
        self.expiryDate = expiryDate
        self.statusRawValue = status.rawValue
        self.subtotalAmount = subtotalAmount
        self.vatAmount = vatAmount
        self.totalAmount = totalAmount
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lines = lines
    }
}
