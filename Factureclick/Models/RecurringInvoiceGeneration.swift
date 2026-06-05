//
//  RecurringInvoiceGeneration.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import Foundation
import SwiftData

@Model
final class RecurringInvoiceGeneration {
    @Attribute(.unique) var id: UUID
    var cycleDate: Date
    var generatedAt: Date
    var generatedInvoiceID: UUID
    var generatedInvoiceNumber: String

    var template: RecurringInvoiceTemplate

    init(
        id: UUID = UUID(),
        cycleDate: Date,
        generatedAt: Date = .now,
        generatedInvoiceID: UUID,
        generatedInvoiceNumber: String,
        template: RecurringInvoiceTemplate
    ) {
        self.id = id
        self.cycleDate = cycleDate
        self.generatedAt = generatedAt
        self.generatedInvoiceID = generatedInvoiceID
        self.generatedInvoiceNumber = generatedInvoiceNumber
        self.template = template
    }
}
