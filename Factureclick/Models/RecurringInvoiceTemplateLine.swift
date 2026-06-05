//
//  RecurringInvoiceTemplateLine.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import Foundation
import SwiftData

@Model
final class RecurringInvoiceTemplateLine {
    @Attribute(.unique) var id: UUID
    private var lineDescriptionStorage: String
    var quantity: Double
    var unitPrice: Double
    var vatRate: Double
    var sortOrder: Int

    var template: RecurringInvoiceTemplate

    var description: String {
        get { lineDescriptionStorage }
        set { lineDescriptionStorage = newValue }
    }

    init(
        id: UUID = UUID(),
        description: String = "",
        quantity: Double = 1,
        unitPrice: Double = 0,
        vatRate: Double = 21,
        sortOrder: Int = 0,
        template: RecurringInvoiceTemplate
    ) {
        self.id = id
        self.lineDescriptionStorage = description
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.vatRate = vatRate
        self.sortOrder = sortOrder
        self.template = template
    }
}
