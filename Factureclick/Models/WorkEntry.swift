//
//  WorkEntry.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation
import SwiftData

@Model
final class WorkEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    var hoursWorked: Double
    var hourlyRateOverride: Double?
    var quantity: Double
    var notes: String
    var includeInInvoice: Bool
    var isInvoiced: Bool

    var client: Client

    var product: Product?

    var invoiceLine: InvoiceLine?

    var collaborationRule: CollaborationRule?

    @Relationship(deleteRule: .cascade, inverse: \Attachment.workEntry)
    var attachments: [Attachment]

    @Relationship(deleteRule: .nullify, inverse: \Receipt.linkedWorkEntry)
    var receipts: [Receipt]

    @Relationship(deleteRule: .cascade, inverse: \CustomerSignature.workEntry)
    var customerSignature: CustomerSignature?

    var companyProfile: CompanyProfile?

    var effectiveHourlyRate: Double {
        if let hourlyRateOverride, hourlyRateOverride > 0 {
            return hourlyRateOverride
        }

        if let product, product.unitType == .hour, product.price > 0 {
            return product.price
        }

        if client.defaultHourlyRate > 0 {
            return client.defaultHourlyRate
        }

        return 0
    }

    var billableAmount: Double {
        if let product, product.unitType != .hour {
            return quantity * product.price
        }

        return hoursWorked * effectiveHourlyRate
    }

    init(
        id: UUID = UUID(),
        date: Date = .now,
        client: Client,
        hoursWorked: Double = 0,
        hourlyRateOverride: Double? = nil,
        product: Product? = nil,
        quantity: Double = 1,
        notes: String = "",
        includeInInvoice: Bool = true,
        isInvoiced: Bool = false,
        invoiceLine: InvoiceLine? = nil,
        collaborationRule: CollaborationRule? = nil,
        attachments: [Attachment] = [],
        receipts: [Receipt] = [],
        customerSignature: CustomerSignature? = nil,
        companyProfile: CompanyProfile? = nil
    ) {
        self.id = id
        self.date = date
        self.client = client
        self.hoursWorked = hoursWorked
        self.hourlyRateOverride = hourlyRateOverride
        self.product = product
        self.quantity = quantity
        self.notes = notes
        self.includeInInvoice = includeInInvoice
        self.isInvoiced = isInvoiced
        self.invoiceLine = invoiceLine
        self.collaborationRule = collaborationRule
        self.attachments = attachments
        self.receipts = receipts
        self.customerSignature = customerSignature
        self.companyProfile = companyProfile
    }
}
