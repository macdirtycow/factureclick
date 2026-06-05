//
//  InvoiceReminder.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import Foundation
import SwiftData

@Model
final class InvoiceReminder {
    @Attribute(.unique) var id: UUID
    var levelRawValue: String
    var subject: String
    var messageBody: String
    var invoiceNumberSnapshot: String
    var clientNameSnapshot: String
    var amountDueSnapshot: Double
    var dueDateSnapshot: Date
    var createdAt: Date
    var sentAt: Date?

    var invoice: Invoice

    var level: InvoiceReminderLevel {
        get { InvoiceReminderLevel(rawValue: levelRawValue) ?? .friendly }
        set { levelRawValue = newValue.rawValue }
    }

    var status: InvoiceReminderStatus {
        sentAt == nil ? .draft : .sent
    }

    init(
        id: UUID = UUID(),
        level: InvoiceReminderLevel,
        subject: String,
        messageBody: String,
        invoiceNumberSnapshot: String,
        clientNameSnapshot: String,
        amountDueSnapshot: Double,
        dueDateSnapshot: Date,
        createdAt: Date = .now,
        sentAt: Date? = nil,
        invoice: Invoice
    ) {
        self.id = id
        self.levelRawValue = level.rawValue
        self.subject = subject
        self.messageBody = messageBody
        self.invoiceNumberSnapshot = invoiceNumberSnapshot
        self.clientNameSnapshot = clientNameSnapshot
        self.amountDueSnapshot = amountDueSnapshot
        self.dueDateSnapshot = dueDateSnapshot
        self.createdAt = createdAt
        self.sentAt = sentAt
        self.invoice = invoice
    }
}
