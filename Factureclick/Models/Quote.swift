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
    var convertedAt: Date?
    var createdAt: Date
    var updatedAt: Date

    var client: Client

    @Relationship(deleteRule: .nullify, inverse: \Invoice.sourceQuote)
    var convertedInvoice: Invoice?

    @Relationship(deleteRule: .cascade, inverse: \QuoteLine.quote)
    var lines: [QuoteLine]

    @Relationship(deleteRule: .cascade, inverse: \CustomerSignature.quote)
    var customerSignature: CustomerSignature?

    var companyProfile: CompanyProfile?

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
        convertedAt: Date? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        convertedInvoice: Invoice? = nil,
        lines: [QuoteLine] = [],
        customerSignature: CustomerSignature? = nil,
        companyProfile: CompanyProfile? = nil
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
        self.convertedAt = convertedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.convertedInvoice = convertedInvoice
        self.lines = lines
        self.customerSignature = customerSignature
        self.companyProfile = companyProfile
    }
}
