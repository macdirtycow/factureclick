//
//  CompanyProfile.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation
import SwiftData

@Model
final class CompanyProfile {
    @Attribute(.unique) var id: UUID
    var name: String
    var ownerName: String
    var kvkNumber: String
    var vatNumber: String
    var iban: String
    var email: String
    var phone: String
    var address: String
    var logoData: Data?
    var defaultInvoiceText: String
    var defaultPaymentText: String
    var isPayPalPaymentEnabled: Bool?
    var paypalPaymentURL: String?
    var showSEPAPaymentQRCode: Bool?
    var accentColor: String
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \Client.companyProfile)
    var clients: [Client]

    @Relationship(deleteRule: .nullify, inverse: \Invoice.companyProfile)
    var invoices: [Invoice]

    @Relationship(deleteRule: .nullify, inverse: \Quote.companyProfile)
    var quotes: [Quote]

    @Relationship(deleteRule: .nullify, inverse: \WorkEntry.companyProfile)
    var workEntries: [WorkEntry]

    @Relationship(deleteRule: .nullify, inverse: \RecurringInvoiceTemplate.companyProfile)
    var recurringInvoiceTemplates: [RecurringInvoiceTemplate]

    init(
        id: UUID = UUID(),
        name: String = "",
        ownerName: String = "",
        kvkNumber: String = "",
        vatNumber: String = "",
        iban: String = "",
        email: String = "",
        phone: String = "",
        address: String = "",
        logoData: Data? = nil,
        defaultInvoiceText: String = "",
        defaultPaymentText: String = "",
        isPayPalPaymentEnabled: Bool = false,
        paypalPaymentURL: String = "",
        showSEPAPaymentQRCode: Bool = true,
        accentColor: String = "#1F6FE5",
        createdAt: Date = .now,
        clients: [Client] = [],
        invoices: [Invoice] = [],
        quotes: [Quote] = [],
        workEntries: [WorkEntry] = [],
        recurringInvoiceTemplates: [RecurringInvoiceTemplate] = []
    ) {
        self.id = id
        self.name = name
        self.ownerName = ownerName
        self.kvkNumber = kvkNumber
        self.vatNumber = vatNumber
        self.iban = iban
        self.email = email
        self.phone = phone
        self.address = address
        self.logoData = logoData
        self.defaultInvoiceText = defaultInvoiceText
        self.defaultPaymentText = defaultPaymentText
        self.isPayPalPaymentEnabled = isPayPalPaymentEnabled
        self.paypalPaymentURL = paypalPaymentURL
        self.showSEPAPaymentQRCode = showSEPAPaymentQRCode
        self.accentColor = accentColor
        self.createdAt = createdAt
        self.clients = clients
        self.invoices = invoices
        self.quotes = quotes
        self.workEntries = workEntries
        self.recurringInvoiceTemplates = recurringInvoiceTemplates
    }
}
