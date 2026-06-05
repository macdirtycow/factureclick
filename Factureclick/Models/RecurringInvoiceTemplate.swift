//
//  RecurringInvoiceTemplate.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import Foundation
import SwiftData

@Model
final class RecurringInvoiceTemplate {
    @Attribute(.unique) var id: UUID
    var title: String
    var frequencyRawValue: String
    var startDate: Date
    var endDate: Date?
    var paymentTermDays: Int
    var notes: String
    var isActive: Bool
    var createdAt: Date

    var client: Client

    @Relationship(deleteRule: .cascade, inverse: \RecurringInvoiceTemplateLine.template)
    var lines: [RecurringInvoiceTemplateLine]

    @Relationship(deleteRule: .cascade, inverse: \RecurringInvoiceGeneration.template)
    var generations: [RecurringInvoiceGeneration]

    var companyProfile: CompanyProfile?

    var frequency: RecurringInvoiceFrequency {
        get { RecurringInvoiceFrequency(rawValue: frequencyRawValue) ?? .monthly }
        set { frequencyRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        title: String = "",
        frequency: RecurringInvoiceFrequency = .monthly,
        startDate: Date = .now,
        endDate: Date? = nil,
        paymentTermDays: Int = 30,
        notes: String = "",
        isActive: Bool = true,
        createdAt: Date = .now,
        client: Client,
        lines: [RecurringInvoiceTemplateLine] = [],
        generations: [RecurringInvoiceGeneration] = [],
        companyProfile: CompanyProfile? = nil
    ) {
        self.id = id
        self.title = title
        self.frequencyRawValue = frequency.rawValue
        self.startDate = startDate
        self.endDate = endDate
        self.paymentTermDays = paymentTermDays
        self.notes = notes
        self.isActive = isActive
        self.createdAt = createdAt
        self.client = client
        self.lines = lines
        self.generations = generations
        self.companyProfile = companyProfile
    }
}
