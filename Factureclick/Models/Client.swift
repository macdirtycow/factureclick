//
//  Client.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation
import SwiftData

@Model
final class Client {
    @Attribute(.unique) var id: UUID
    var name: String
    var contactPerson: String
    var email: String
    var phone: String
    var address: String
    var kvkNumber: String
    var vatNumber: String
    var paymentTermDays: Int
    var defaultHourlyRate: Double
    var notes: String

    @Relationship(deleteRule: .deny, inverse: \WorkEntry.client)
    var workEntries: [WorkEntry]

    @Relationship(deleteRule: .deny, inverse: \Invoice.client)
    var invoices: [Invoice]

    @Relationship(deleteRule: .deny, inverse: \Quote.client)
    var quotes: [Quote]

    @Relationship(deleteRule: .nullify, inverse: \CollaborationRule.client)
    var collaborationRules: [CollaborationRule]

    @Relationship(deleteRule: .deny, inverse: \RecurringInvoiceTemplate.client)
    var recurringInvoiceTemplates: [RecurringInvoiceTemplate]

    @Relationship(deleteRule: .nullify, inverse: \MileageEntry.client)
    var mileageEntries: [MileageEntry]

    @Relationship(deleteRule: .nullify, inverse: \Receipt.linkedClient)
    var receipts: [Receipt]

    var companyProfile: CompanyProfile?

    init(
        id: UUID = UUID(),
        name: String = "",
        contactPerson: String = "",
        email: String = "",
        phone: String = "",
        address: String = "",
        kvkNumber: String = "",
        vatNumber: String = "",
        paymentTermDays: Int = 30,
        defaultHourlyRate: Double = 0,
        notes: String = "",
        workEntries: [WorkEntry] = [],
        invoices: [Invoice] = [],
        quotes: [Quote] = [],
        collaborationRules: [CollaborationRule] = [],
        recurringInvoiceTemplates: [RecurringInvoiceTemplate] = [],
        mileageEntries: [MileageEntry] = [],
        receipts: [Receipt] = [],
        companyProfile: CompanyProfile? = nil
    ) {
        self.id = id
        self.name = name
        self.contactPerson = contactPerson
        self.email = email
        self.phone = phone
        self.address = address
        self.kvkNumber = kvkNumber
        self.vatNumber = vatNumber
        self.paymentTermDays = paymentTermDays
        self.defaultHourlyRate = defaultHourlyRate
        self.notes = notes
        self.workEntries = workEntries
        self.invoices = invoices
        self.quotes = quotes
        self.collaborationRules = collaborationRules
        self.recurringInvoiceTemplates = recurringInvoiceTemplates
        self.mileageEntries = mileageEntries
        self.receipts = receipts
        self.companyProfile = companyProfile
    }
}
