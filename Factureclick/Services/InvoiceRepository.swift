//
//  InvoiceRepository.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation
import SwiftData

struct InvoiceWorkflowLaunchContext: Equatable {
    let sourceTitle: String
    let selectedClientID: UUID?
    let selectedRegistrationIDs: [UUID]
    let suggestedStartDate: Date?
    let suggestedEndDate: Date?

    var fingerprint: String {
        [
            sourceTitle,
            selectedClientID?.uuidString ?? "all",
            selectedRegistrationIDs.map(\.uuidString).joined(separator: ","),
            suggestedStartDate?.formatted(.iso8601) ?? "nil",
            suggestedEndDate?.formatted(.iso8601) ?? "nil"
        ].joined(separator: "|")
    }
}

struct WeeklyBillingPreparation {
    let weekStart: Date
    let weekEnd: Date
    let pendingEntries: [WorkEntry]
    let pendingValue: Double
    let shouldHighlight: Bool
}

struct InvoiceRepository {
    private let calendar: Calendar
    private let attachmentStorageService: AttachmentStorageService
    private let signatureStorageService: SignatureStorageService

    init(
        calendar: Calendar = .current,
        attachmentStorageService: AttachmentStorageService = AttachmentStorageService(),
        signatureStorageService: SignatureStorageService = SignatureStorageService()
    ) {
        self.calendar = calendar
        self.attachmentStorageService = attachmentStorageService
        self.signatureStorageService = signatureStorageService
    }

    func registrations(
        from workEntries: [WorkEntry],
        clientID: UUID?,
        startDate: Date,
        endDate: Date
    ) -> [WorkEntry] {
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate

        return workEntries
            .filter { clientID == nil || $0.client.id == clientID }
            .filter { $0.includeInInvoice && !$0.isInvoiced }
            .filter { $0.date >= start && $0.date <= end }
            .sorted { $0.date > $1.date }
    }

    func dateRangeForQuarter(year: Int, quarter: Int) -> ClosedRange<Date> {
        let normalizedQuarter = min(max(quarter, 1), 4)
        let startMonth = ((normalizedQuarter - 1) * 3) + 1
        let startComponents = DateComponents(year: year, month: startMonth, day: 1)
        let startDate = calendar.date(from: startComponents) ?? .now
        let endDate = calendar.date(byAdding: DateComponents(month: 3, day: -1), to: startDate) ?? startDate
        let normalizedStart = calendar.startOfDay(for: startDate)
        let normalizedEnd = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
        return normalizedStart...normalizedEnd
    }

    func invoicesForQuarter(from invoices: [Invoice], year: Int, quarter: Int) -> [Invoice] {
        let range = dateRangeForQuarter(year: year, quarter: quarter)
        return invoices
            .filter { range.contains($0.date) }
            .sorted { lhs, rhs in
                if lhs.date != rhs.date {
                    return lhs.date > rhs.date
                }
                return lhs.createdAt > rhs.createdAt
            }
    }

    func canCreateInvoice(for entry: WorkEntry) -> Bool {
        entry.includeInInvoice && !entry.isInvoiced && entry.invoiceLine == nil
    }

    func eligibleRegistrations(
        from workEntries: [WorkEntry],
        clientID: UUID? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) -> [WorkEntry] {
        workEntries
            .filter(canCreateInvoice(for:))
            .filter { clientID == nil || $0.client.id == clientID }
            .filter { startDate == nil || $0.date >= calendar.startOfDay(for: startDate!) }
            .filter { endDate == nil || $0.date <= (calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endDate!) ?? endDate!) }
            .sorted { $0.date > $1.date }
    }

    func makeLaunchContext(from entries: [WorkEntry], sourceTitle: String) -> InvoiceWorkflowLaunchContext? {
        let eligibleEntries = entries
            .filter(canCreateInvoice(for:))
            .sorted { $0.date > $1.date }
        guard !eligibleEntries.isEmpty else { return nil }

        let clientIDs = Set(eligibleEntries.map(\.client.id))

        return InvoiceWorkflowLaunchContext(
            sourceTitle: sourceTitle,
            selectedClientID: clientIDs.count == 1 ? eligibleEntries.first?.client.id : nil,
            selectedRegistrationIDs: eligibleEntries.map(\.id),
            suggestedStartDate: eligibleEntries.map(\.date).min(),
            suggestedEndDate: eligibleEntries.map(\.date).max()
        )
    }

    func makeSuggestedLaunchContext(
        from workEntries: [WorkEntry],
        preferredClientID: UUID? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        sourceTitle: String = "Suggested uninvoiced registrations"
    ) -> InvoiceWorkflowLaunchContext? {
        let eligible = eligibleRegistrations(
            from: workEntries,
            clientID: preferredClientID,
            startDate: startDate,
            endDate: endDate
        )

        guard !eligible.isEmpty else { return nil }

        if let preferredClientID {
            return makeLaunchContext(
                from: eligible.filter { $0.client.id == preferredClientID },
                sourceTitle: sourceTitle
            )
        }

        let grouped = Dictionary(grouping: eligible, by: \.client.id)
        let bestGroup = grouped.values
            .sorted { lhs, rhs in
                if lhs.count != rhs.count {
                    return lhs.count > rhs.count
                }
                return (lhs.map(\.date).max() ?? .distantPast) > (rhs.map(\.date).max() ?? .distantPast)
            }
            .first ?? []

        return makeLaunchContext(from: bestGroup, sourceTitle: sourceTitle)
    }

    func makeEndOfWeekPreparation(from workEntries: [WorkEntry], referenceDate: Date = .now) -> WeeklyBillingPreparation {
        let weekInterval = calendar.dateInterval(of: .weekOfYear, for: referenceDate)
        let weekStart = weekInterval?.start ?? referenceDate
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? referenceDate
        let pendingEntries = eligibleRegistrations(from: workEntries, startDate: weekStart, endDate: weekEnd)
        let pendingValue = pendingEntries.reduce(0) { $0 + $1.billableAmount }
        let weekday = calendar.component(.weekday, from: referenceDate)
        let isEndOfWeek = weekday == 6 || weekday == 7 || weekday == 1

        return WeeklyBillingPreparation(
            weekStart: weekStart,
            weekEnd: weekEnd,
            pendingEntries: pendingEntries,
            pendingValue: pendingValue,
            shouldHighlight: isEndOfWeek && !pendingEntries.isEmpty
        )
    }

    func nextInvoiceNumber(
        existingInvoices: [Invoice],
        invoiceDate: Date,
        prefix: String = "",
        sequencePadding: Int = 3
    ) -> String {
        let year = calendar.component(.year, from: invoiceDate)
        let normalizedPrefix = prefix.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedPadding = max(sequencePadding, 2)
        let nextSequence = maxSequenceNumber(
            in: existingInvoices.filter { !$0.isCreditInvoice },
            year: year,
            prefix: normalizedPrefix,
            creditPrefix: nil
        ) + 1
        let baseNumber = String(format: "%d-%0\(normalizedPadding)d", year, nextSequence)
        return normalizedPrefix.isEmpty ? baseNumber : "\(normalizedPrefix)-\(baseNumber)"
    }

    func nextCreditInvoiceNumber(
        existingInvoices: [Invoice],
        invoiceDate: Date,
        prefix: String = "CR",
        sequencePadding: Int = 3
    ) -> String {
        let year = calendar.component(.year, from: invoiceDate)
        let normalizedPadding = max(sequencePadding, 2)
        let normalizedPrefix = prefix.trimmingCharacters(in: .whitespacesAndNewlines)
        let creditPrefix = normalizedPrefix.isEmpty ? "CR" : normalizedPrefix
        let nextSequence = maxSequenceNumber(
            in: existingInvoices.filter(\.isCreditInvoice),
            year: year,
            prefix: "",
            creditPrefix: creditPrefix
        ) + 1
        let baseNumber = String(format: "%d-%0\(normalizedPadding)d", year, nextSequence)
        return "\(creditPrefix)-\(baseNumber)"
    }

    private func maxSequenceNumber(
        in invoices: [Invoice],
        year: Int,
        prefix: String,
        creditPrefix: String?
    ) -> Int {
        invoices
            .filter { calendar.component(.year, from: $0.date) == year }
            .compactMap { parsedSequence(from: $0.invoiceNumber, year: year, prefix: prefix, creditPrefix: creditPrefix) }
            .max() ?? 0
    }

    private func parsedSequence(
        from invoiceNumber: String,
        year: Int,
        prefix: String,
        creditPrefix: String?
    ) -> Int? {
        let trimmed = invoiceNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let yearToken = "\(year)"
        let components = trimmed.split(separator: "-").map(String.init)
        guard let yearIndex = components.firstIndex(of: yearToken),
              yearIndex + 1 < components.count,
              let sequence = Int(components[yearIndex + 1]) else {
            return nil
        }

        if let creditPrefix {
            guard components.first == creditPrefix else { return nil }
            return sequence
        }

        if prefix.isEmpty {
            guard components.count == 2, components[0] == yearToken else { return nil }
            return sequence
        }

        guard components.count == 3,
              components[0] == prefix,
              components[1] == yearToken else {
            return nil
        }
        return sequence
    }

    func normalizedStatus(for invoice: Invoice, referenceDate: Date = .now) -> InvoiceStatus {
        if invoice.status == .paid {
            return .paid
        }
        if invoice.status == .draft {
            return .draft
        }
        if invoice.isCreditInvoice {
            return invoice.status
        }
        if invoice.dueDate < calendar.startOfDay(for: referenceDate) {
            return .overdue
        }
        return invoice.status
    }

    func persistStatus(_ status: InvoiceStatus, on invoice: Invoice) {
        invoice.status = status
        if status != .paid {
            invoice.paidDate = nil
        }
    }

    func markAsSent(_ invoice: Invoice) {
        invoice.status = .sent
        invoice.paidDate = nil
    }

    func markAsPaid(_ invoice: Invoice, paidDate: Date = .now) {
        invoice.status = .paid
        invoice.paidDate = paidDate
    }

    func save(invoice: Invoice, in context: ModelContext) throws {
        context.insert(invoice)
        try context.save()
    }

    func delete(_ invoice: Invoice, from invoices: [Invoice], in context: ModelContext) throws {
        for attachment in invoice.attachments {
            attachmentStorageService.deleteStoredFile(at: attachment.localPath)
        }

        if let signature = invoice.customerSignature {
            signatureStorageService.deleteStoredSignature(
                imageLocalPath: signature.imageLocalPath,
                strokeLocalPath: signature.strokeLocalPath
            )
        }

        for line in invoice.lines {
            if let linkedWorkEntry = line.linkedWorkEntry {
                linkedWorkEntry.invoiceLine = nil
                linkedWorkEntry.isInvoiced = false
            }
        }

        for mileageEntry in invoice.mileageEntries {
            mileageEntry.invoice = nil
        }

        for receipt in invoice.receipts {
            receipt.linkedInvoice = nil
        }

        if let sourceQuote = invoice.sourceQuote {
            sourceQuote.convertedInvoice = nil
            sourceQuote.convertedAt = nil
            sourceQuote.updatedAt = .now
        }

        for creditInvoice in invoices where creditInvoice.creditedInvoiceID == invoice.id {
            creditInvoice.creditedInvoiceID = nil
            creditInvoice.creditedInvoiceNumber = ""
        }

        context.delete(invoice)
        try context.save()
    }

    func filteredInvoices(
        from invoices: [Invoice],
        clientID: UUID?,
        statusFilter: InvoiceHistoryStatusFilter,
        searchText: String,
        startDate: Date?,
        endDate: Date?,
        referenceDate: Date = .now
    ) -> [Invoice] {
        let normalizedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return invoices.filter { invoice in
            let matchesClient = clientID == nil || invoice.client.id == clientID
            let normalizedStatus = normalizedStatus(for: invoice, referenceDate: referenceDate)
            let matchesStatus: Bool = {
                switch statusFilter {
                case .all:
                    true
                case .open:
                    normalizedStatus == .draft || normalizedStatus == .sent || normalizedStatus == .overdue
                case .paid:
                    normalizedStatus == .paid
                case .overdue:
                    normalizedStatus == .overdue
                case .draft:
                    normalizedStatus == .draft
                }
            }()
            let matchesSearch = normalizedSearch.isEmpty || [
                invoice.invoiceNumber,
                invoice.client.name
            ]
            .joined(separator: " ")
            .lowercased()
            .contains(normalizedSearch)
            let matchesStart = startDate == nil || invoice.date >= calendar.startOfDay(for: startDate!)
            let matchesEnd = endDate == nil || invoice.date <= (calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endDate!) ?? endDate!)

            return matchesClient && matchesStatus && matchesSearch && matchesStart && matchesEnd
        }
        .sorted { $0.date > $1.date }
    }

    func revenueForWeek(from invoices: [Invoice], referenceDate: Date = .now) -> Double {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: referenceDate) else { return 0 }
        return invoices.filter { interval.contains($0.date) }.reduce(0) { $0 + $1.totalAmount }
    }

    func revenueForMonth(from invoices: [Invoice], referenceDate: Date = .now) -> Double {
        guard let interval = calendar.dateInterval(of: .month, for: referenceDate) else { return 0 }
        return invoices.filter { interval.contains($0.date) }.reduce(0) { $0 + $1.totalAmount }
    }

    func openInvoiceCount(from invoices: [Invoice], referenceDate: Date = .now) -> Int {
        invoices
            .filter { !$0.isCreditInvoice }
            .filter { normalizedStatus(for: $0, referenceDate: referenceDate) != .paid }
            .count
    }

    func paidInvoiceCount(from invoices: [Invoice], referenceDate: Date = .now) -> Int {
        invoices.filter { normalizedStatus(for: $0, referenceDate: referenceDate) == .paid }.count
    }

    func overdueInvoiceCount(from invoices: [Invoice], referenceDate: Date = .now) -> Int {
        invoices
            .filter { !$0.isCreditInvoice }
            .filter { normalizedStatus(for: $0, referenceDate: referenceDate) == .overdue }
            .count
    }

    func expectedIncomingAmount(from invoices: [Invoice], referenceDate: Date = .now) -> Double {
        invoices
            .filter { !$0.isCreditInvoice }
            .filter { normalizedStatus(for: $0, referenceDate: referenceDate) != .paid }
            .reduce(0) { $0 + $1.totalAmount }
    }
}
