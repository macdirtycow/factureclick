//
//  OverdueInvoiceService.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import Foundation

struct OverdueInvoiceSummary: Identifiable {
    let invoice: Invoice
    let daysOverdue: Int
    let lastReminder: InvoiceReminder?

    var id: UUID { invoice.id }
}

struct OverdueInvoiceService {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func isOverdue(_ invoice: Invoice, referenceDate: Date = .now) -> Bool {
        guard !invoice.isCreditInvoice else {
            return false
        }

        guard invoice.status != .draft, invoice.status != .paid else {
            return false
        }

        return calendar.startOfDay(for: invoice.dueDate) < calendar.startOfDay(for: referenceDate)
    }

    func daysOverdue(for invoice: Invoice, referenceDate: Date = .now) -> Int {
        guard isOverdue(invoice, referenceDate: referenceDate) else { return 0 }

        let dueDay = calendar.startOfDay(for: invoice.dueDate)
        let currentDay = calendar.startOfDay(for: referenceDate)
        return max(calendar.dateComponents([.day], from: dueDay, to: currentDay).day ?? 0, 0)
    }

    func overdueInvoices(from invoices: [Invoice], referenceDate: Date = .now) -> [OverdueInvoiceSummary] {
        invoices
            .filter { isOverdue($0, referenceDate: referenceDate) }
            .map { invoice in
                OverdueInvoiceSummary(
                    invoice: invoice,
                    daysOverdue: daysOverdue(for: invoice, referenceDate: referenceDate),
                    lastReminder: invoice.reminders.sorted { $0.createdAt > $1.createdAt }.first
                )
            }
            .sorted {
                if $0.daysOverdue != $1.daysOverdue {
                    return $0.daysOverdue > $1.daysOverdue
                }
                return $0.invoice.dueDate < $1.invoice.dueDate
            }
    }
}
