//
//  Invoice.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation
import SwiftData

@Model
final class Invoice {
    @Attribute(.unique) var id: UUID
    var invoiceNumber: String
    var date: Date
    var dueDate: Date
    var documentTypeRawValue: String = InvoiceDocumentType.standard.rawValue
    var statusRawValue: String
    var emailDeliveryStatusRawValue: String
    var paidDate: Date?
    var emailInitiatedAt: Date?
    var emailSentAt: Date?
    var lastEmailRecipient: String
    var lastEmailSubject: String
    var notes: String
    var totalAmount: Double
    var vatAmount: Double
    var creditedInvoiceID: UUID?
    var creditedInvoiceNumber: String = ""
    var createdAt: Date

    var client: Client

    var sourceRecurringTemplate: RecurringInvoiceTemplate?
    var recurringCycleDate: Date?

    var sourceQuote: Quote?

    @Relationship(deleteRule: .cascade, inverse: \InvoiceLine.invoice)
    var lines: [InvoiceLine]

    @Relationship(deleteRule: .cascade, inverse: \Attachment.invoice)
    var attachments: [Attachment]

    @Relationship(deleteRule: .cascade, inverse: \InvoiceReminder.invoice)
    var reminders: [InvoiceReminder]

    @Relationship(deleteRule: .nullify, inverse: \MileageEntry.invoice)
    var mileageEntries: [MileageEntry]

    @Relationship(deleteRule: .nullify, inverse: \Receipt.linkedInvoice)
    var receipts: [Receipt]

    @Relationship(deleteRule: .cascade, inverse: \CustomerSignature.invoice)
    var customerSignature: CustomerSignature?

    var companyProfile: CompanyProfile?

    var status: InvoiceStatus {
        get { InvoiceStatus(rawValue: statusRawValue) ?? .draft }
        set { statusRawValue = newValue.rawValue }
    }

    var documentType: InvoiceDocumentType {
        get { InvoiceDocumentType(rawValue: documentTypeRawValue) ?? .standard }
        set { documentTypeRawValue = newValue.rawValue }
    }

    var isCreditInvoice: Bool {
        documentType == .credit
    }

    var emailDeliveryStatus: InvoiceEmailDeliveryStatus {
        get { InvoiceEmailDeliveryStatus(rawValue: emailDeliveryStatusRawValue) ?? .notSent }
        set { emailDeliveryStatusRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        invoiceNumber: String = "",
        client: Client,
        date: Date = .now,
        dueDate: Date = .now,
        documentType: InvoiceDocumentType = .standard,
        status: InvoiceStatus = .draft,
        emailDeliveryStatus: InvoiceEmailDeliveryStatus = .notSent,
        paidDate: Date? = nil,
        emailInitiatedAt: Date? = nil,
        emailSentAt: Date? = nil,
        lastEmailRecipient: String = "",
        lastEmailSubject: String = "",
        notes: String = "",
        totalAmount: Double = 0,
        vatAmount: Double = 0,
        creditedInvoiceID: UUID? = nil,
        creditedInvoiceNumber: String = "",
        createdAt: Date = .now,
        sourceRecurringTemplate: RecurringInvoiceTemplate? = nil,
        recurringCycleDate: Date? = nil,
        sourceQuote: Quote? = nil,
        lines: [InvoiceLine] = [],
        attachments: [Attachment] = [],
        reminders: [InvoiceReminder] = [],
        mileageEntries: [MileageEntry] = [],
        receipts: [Receipt] = [],
        customerSignature: CustomerSignature? = nil,
        companyProfile: CompanyProfile? = nil
    ) {
        self.id = id
        self.invoiceNumber = invoiceNumber
        self.client = client
        self.date = date
        self.dueDate = dueDate
        self.documentTypeRawValue = documentType.rawValue
        self.statusRawValue = status.rawValue
        self.emailDeliveryStatusRawValue = emailDeliveryStatus.rawValue
        self.paidDate = paidDate
        self.emailInitiatedAt = emailInitiatedAt
        self.emailSentAt = emailSentAt
        self.lastEmailRecipient = lastEmailRecipient
        self.lastEmailSubject = lastEmailSubject
        self.notes = notes
        self.totalAmount = totalAmount
        self.vatAmount = vatAmount
        self.creditedInvoiceID = creditedInvoiceID
        self.creditedInvoiceNumber = creditedInvoiceNumber
        self.createdAt = createdAt
        self.sourceRecurringTemplate = sourceRecurringTemplate
        self.recurringCycleDate = recurringCycleDate
        self.sourceQuote = sourceQuote
        self.lines = lines
        self.attachments = attachments
        self.reminders = reminders
        self.mileageEntries = mileageEntries
        self.receipts = receipts
        self.customerSignature = customerSignature
        self.companyProfile = companyProfile
    }
}
