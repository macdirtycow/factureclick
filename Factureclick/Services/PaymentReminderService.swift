//
//  PaymentReminderService.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import Foundation
import SwiftData

struct PaymentReminderDraft: Identifiable {
    let id: UUID
    let invoiceID: UUID
    let existingReminderID: UUID?
    var level: InvoiceReminderLevel
    var subject: String
    var messageBody: String
    let clientName: String
    let invoiceNumber: String
    let amountDue: Double
    let dueDate: Date

    init(
        id: UUID = UUID(),
        invoiceID: UUID,
        existingReminderID: UUID? = nil,
        level: InvoiceReminderLevel,
        subject: String,
        messageBody: String,
        clientName: String,
        invoiceNumber: String,
        amountDue: Double,
        dueDate: Date
    ) {
        self.id = id
        self.invoiceID = invoiceID
        self.existingReminderID = existingReminderID
        self.level = level
        self.subject = subject
        self.messageBody = messageBody
        self.clientName = clientName
        self.invoiceNumber = invoiceNumber
        self.amountDue = amountDue
        self.dueDate = dueDate
    }
}

struct PaymentReminderService {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func canCreateReminder(for invoice: Invoice) -> Bool {
        !invoice.isCreditInvoice && invoice.status != .paid
    }

    func suggestedLevel(for invoice: Invoice) -> InvoiceReminderLevel {
        guard let lastReminder = invoice.reminders.sorted(by: { $0.createdAt > $1.createdAt }).first else {
            return .friendly
        }

        switch lastReminder.level {
        case .friendly:
            return .second
        case .second, .final:
            return .final
        }
    }

    func makeDraft(
        for invoice: Invoice,
        level: InvoiceReminderLevel? = nil,
        localeIdentifier: String? = nil
    ) -> PaymentReminderDraft {
        if let level,
           let existingDraft = latestDraft(for: invoice, level: level) {
            return draft(from: existingDraft, for: invoice)
        }

        if level == nil,
           let existingDraft = latestDraft(for: invoice) {
            return draft(from: existingDraft, for: invoice)
        }

        let selectedLevel = level ?? suggestedLevel(for: invoice)
        let localization = AppLocalization(localeIdentifier: localeIdentifier)
        let recipientName = invoice.client.contactPerson.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? invoice.client.name
            : invoice.client.contactPerson
        let amountDue = invoice.totalAmount.formatted(.currency(code: Locale.current.currency?.identifier ?? "EUR"))
        let originalDueDate = invoice.dueDate.formatted(date: .long, time: .omitted)
        let reminderDueDate = reminderDueDate(for: invoice, level: selectedLevel)
        let deadlineText = reminderDueDate.formatted(date: .long, time: .omitted)

        let body = [
            localization.reminderGreeting(recipientName: recipientName),
            localization.reminderIntro(
                level: selectedLevel,
                invoiceNumber: invoice.invoiceNumber,
                amountDue: amountDue,
                originalDueDate: originalDueDate
            ),
            localization.reminderPaymentDeadline(deadlineText),
            localization.reminderDisregardNotice(),
            localization.reminderClosing()
        ].joined(separator: "\n\n")

        return PaymentReminderDraft(
            invoiceID: invoice.id,
            level: selectedLevel,
            subject: localization.reminderSubject(level: selectedLevel, invoiceNumber: invoice.invoiceNumber),
            messageBody: body,
            clientName: invoice.client.name,
            invoiceNumber: invoice.invoiceNumber,
            amountDue: invoice.totalAmount,
            dueDate: reminderDueDate
        )
    }

    func createReminder(
        from draft: PaymentReminderDraft,
        for invoice: Invoice,
        createdAt: Date = .now,
        sentAt: Date? = nil
    ) -> InvoiceReminder {
        if let existingReminderID = draft.existingReminderID,
           let existingReminder = invoice.reminders.first(where: { $0.id == existingReminderID }) {
            existingReminder.level = draft.level
            existingReminder.subject = draft.subject.trimmingCharacters(in: .whitespacesAndNewlines)
            existingReminder.messageBody = draft.messageBody.trimmingCharacters(in: .whitespacesAndNewlines)
            existingReminder.invoiceNumberSnapshot = draft.invoiceNumber
            existingReminder.clientNameSnapshot = draft.clientName
            existingReminder.amountDueSnapshot = draft.amountDue
            existingReminder.dueDateSnapshot = draft.dueDate
            if let sentAt {
                existingReminder.sentAt = sentAt
            }
            return existingReminder
        }

        return InvoiceReminder(
            level: draft.level,
            subject: draft.subject.trimmingCharacters(in: .whitespacesAndNewlines),
            messageBody: draft.messageBody.trimmingCharacters(in: .whitespacesAndNewlines),
            invoiceNumberSnapshot: draft.invoiceNumber,
            clientNameSnapshot: draft.clientName,
            amountDueSnapshot: draft.amountDue,
            dueDateSnapshot: draft.dueDate,
            createdAt: createdAt,
            sentAt: sentAt,
            invoice: invoice
        )
    }

    @discardableResult
    func generateAutomaticDrafts(
        for invoices: [Invoice],
        localeIdentifier: String?,
        referenceDate: Date = .now,
        in modelContext: ModelContext
    ) throws -> Int {
        var createdCount = 0

        for invoice in invoices where canCreateReminder(for: invoice) {
            guard let automaticLevel = automaticDraftLevel(for: invoice, referenceDate: referenceDate) else {
                continue
            }

            let reminder = createReminder(
                from: makeDraft(for: invoice, level: automaticLevel, localeIdentifier: localeIdentifier),
                for: invoice,
                createdAt: referenceDate,
                sentAt: nil
            )
            modelContext.insert(reminder)
            createdCount += 1
        }

        if createdCount > 0 {
            try modelContext.save()
        }

        return createdCount
    }

    private func reminderDueDate(for invoice: Invoice, level: InvoiceReminderLevel) -> Date {
        let start = calendar.startOfDay(for: invoice.dueDate)
        let extensionDays: Int

        switch level {
        case .friendly:
            extensionDays = 7
        case .second:
            extensionDays = 14
        case .final:
            extensionDays = 17
        }

        return calendar.date(byAdding: .day, value: extensionDays, to: start) ?? invoice.dueDate
    }

    private func automaticDraftLevel(for invoice: Invoice, referenceDate: Date) -> InvoiceReminderLevel? {
        let existingLevels = Set(invoice.reminders.map(\.level))
        let referenceDay = calendar.startOfDay(for: referenceDate)

        if !existingLevels.contains(.friendly),
           calendar.startOfDay(for: invoice.dueDate) < referenceDay {
            return .friendly
        }

        let friendlyDueDate = calendar.startOfDay(for: reminderDueDate(for: invoice, level: .friendly))
        if existingLevels.contains(.friendly),
           !existingLevels.contains(.second),
           friendlyDueDate < referenceDay {
            return .second
        }

        let secondDueDate = calendar.startOfDay(for: reminderDueDate(for: invoice, level: .second))
        if existingLevels.contains(.second),
           !existingLevels.contains(.final),
           secondDueDate < referenceDay {
            return .final
        }

        return nil
    }

    private func latestDraft(for invoice: Invoice, level: InvoiceReminderLevel? = nil) -> InvoiceReminder? {
        invoice.reminders
            .filter { reminder in
                reminder.status == .draft && (level == nil || reminder.level == level)
            }
            .sorted { $0.createdAt > $1.createdAt }
            .first
    }

    private func draft(from reminder: InvoiceReminder, for invoice: Invoice) -> PaymentReminderDraft {
        PaymentReminderDraft(
            id: reminder.id,
            invoiceID: invoice.id,
            existingReminderID: reminder.id,
            level: reminder.level,
            subject: reminder.subject,
            messageBody: reminder.messageBody,
            clientName: reminder.clientNameSnapshot,
            invoiceNumber: reminder.invoiceNumberSnapshot,
            amountDue: reminder.amountDueSnapshot,
            dueDate: reminder.dueDateSnapshot
        )
    }
}
