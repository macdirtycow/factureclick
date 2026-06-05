//
//  TimeTrackingRepository.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation
import SwiftData

struct TimeTrackingPeriodSummary {
    let totalHours: Double
    let billableHours: Double
    let totalAmount: Double
    let pendingInvoiceHours: Double
    let partnerShare: Double
    let userNetAmount: Double
}

struct TimeTrackingDaySummary: Identifiable {
    let date: Date
    let totalHours: Double
    let totalAmount: Double
    let entryCount: Int
    let partnerShare: Double
    let userNetAmount: Double

    var id: Date { date }
}

struct TimeTrackingClientSummary: Identifiable {
    let clientID: UUID
    let clientName: String
    let totalHours: Double
    let totalAmount: Double
    let entryCount: Int
    let partnerShare: Double
    let userNetAmount: Double

    var id: UUID { clientID }
}

struct TimeTrackingLogItem: Identifiable {
    let entry: WorkEntry

    var id: UUID { entry.id }
}

struct TimeTrackingRepository {
    private let calendar: Calendar
    private let collaborationRevenueService: CollaborationRevenueService
    private let attachmentStorageService: AttachmentStorageService
    private let signatureStorageService: SignatureStorageService

    init(
        calendar: Calendar = .current,
        collaborationRevenueService: CollaborationRevenueService = CollaborationRevenueService(),
        attachmentStorageService: AttachmentStorageService = AttachmentStorageService(),
        signatureStorageService: SignatureStorageService = SignatureStorageService()
    ) {
        self.calendar = calendar
        self.collaborationRevenueService = collaborationRevenueService
        self.attachmentStorageService = attachmentStorageService
        self.signatureStorageService = signatureStorageService
    }

    func entriesForWeek(from entries: [WorkEntry], referenceDate: Date) -> [WorkEntry] {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: referenceDate) else {
            return []
        }

        return filteredEntries(in: interval.start...interval.end, from: entries)
    }

    func entriesForInvoicePeriod(from entries: [WorkEntry], startDate: Date, endDate: Date) -> [WorkEntry] {
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
        return filteredEntries(in: start...end, from: entries)
    }

    func makeSummary(for entries: [WorkEntry]) -> TimeTrackingPeriodSummary {
        let totalHours = entries.reduce(0) { $0 + $1.hoursWorked }
        let billableEntries = entries.filter(\.includeInInvoice)
        let billableHours = billableEntries.reduce(0) { $0 + $1.hoursWorked }
        let totalAmount = billableEntries.reduce(0) { $0 + $1.billableAmount }
        let pendingInvoiceHours = billableEntries.filter { !$0.isInvoiced }.reduce(0) { $0 + $1.hoursWorked }
        let collaborationSummary = collaborationRevenueService.makeSummary(for: entries)

        return TimeTrackingPeriodSummary(
            totalHours: totalHours,
            billableHours: billableHours,
            totalAmount: totalAmount,
            pendingInvoiceHours: pendingInvoiceHours,
            partnerShare: collaborationSummary.partnerShare,
            userNetAmount: collaborationSummary.userNetAmount
        )
    }

    func makeDailySummaries(for entries: [WorkEntry]) -> [TimeTrackingDaySummary] {
        let grouped = Dictionary(grouping: entries) { calendar.startOfDay(for: $0.date) }

        return grouped.keys.sorted(by: >).compactMap { date in
            guard let group = grouped[date] else { return nil }

            return TimeTrackingDaySummary(
                date: date,
                totalHours: group.reduce(0) { $0 + $1.hoursWorked },
                totalAmount: group.filter(\.includeInInvoice).reduce(0) { $0 + $1.billableAmount },
                entryCount: group.count,
                partnerShare: collaborationRevenueService.makeSummary(for: group).partnerShare,
                userNetAmount: collaborationRevenueService.makeSummary(for: group).userNetAmount
            )
        }
    }

    func makeClientSummaries(for entries: [WorkEntry]) -> [TimeTrackingClientSummary] {
        let grouped = Dictionary(grouping: entries, by: \.client.id)

        return grouped.values.compactMap { group in
            guard let first = group.first else { return nil }

            return TimeTrackingClientSummary(
                clientID: first.client.id,
                clientName: first.client.name,
                totalHours: group.reduce(0) { $0 + $1.hoursWorked },
                totalAmount: group.filter(\.includeInInvoice).reduce(0) { $0 + $1.billableAmount },
                entryCount: group.count,
                partnerShare: collaborationRevenueService.makeSummary(for: group).partnerShare,
                userNetAmount: collaborationRevenueService.makeSummary(for: group).userNetAmount
            )
        }
        .sorted { $0.totalHours > $1.totalHours }
    }

    func makeTimeLogs(for entries: [WorkEntry]) -> [TimeTrackingLogItem] {
        entries
            .sorted { $0.date > $1.date }
            .map(TimeTrackingLogItem.init(entry:))
    }

    func makeCollaborationSummary(for entries: [WorkEntry]) -> CollaborationRevenueSummary {
        collaborationRevenueService.makeSummary(for: entries)
    }

    func delete(_ entry: WorkEntry, in context: ModelContext) throws {
        guard entry.invoiceLine == nil, !entry.isInvoiced else {
            throw TimeTrackingRepositoryError.entryLinkedToInvoice
        }

        for attachment in entry.attachments {
            attachmentStorageService.deleteStoredFile(at: attachment.localPath)
        }

        if let signature = entry.customerSignature {
            signatureStorageService.deleteStoredSignature(
                imageLocalPath: signature.imageLocalPath,
                strokeLocalPath: signature.strokeLocalPath
            )
        }

        for receipt in entry.receipts {
            receipt.linkedWorkEntry = nil
        }

        context.delete(entry)
        try context.save()
    }

    func filteredHistoryEntries(
        from entries: [WorkEntry],
        clientID: UUID?,
        searchText: String,
        filter: RegistrationDateFilter,
        referenceDate: Date
    ) -> [WorkEntry] {
        let normalizedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return entries.filter { entry in
            let matchesClient = clientID == nil || entry.client.id == clientID
            let matchesSearch = normalizedSearch.isEmpty || [
                entry.client.name,
                entry.product?.name ?? "",
                entry.notes
            ]
            .joined(separator: " ")
            .lowercased()
            .contains(normalizedSearch)
            let matchesFilter = matches(entry: entry, filter: filter, referenceDate: referenceDate)
            return matchesClient && matchesSearch && matchesFilter
        }
        .sorted { $0.date > $1.date }
    }

    private func filteredEntries(in range: ClosedRange<Date>, from entries: [WorkEntry]) -> [WorkEntry] {
        entries.filter { range.contains($0.date) }
    }

    private func matches(entry: WorkEntry, filter: RegistrationDateFilter, referenceDate: Date) -> Bool {
        switch filter {
        case .all:
            return true
        case .thisWeek:
            guard let interval = calendar.dateInterval(of: .weekOfYear, for: referenceDate) else { return true }
            return interval.contains(entry.date)
        case .thisMonth:
            guard let interval = calendar.dateInterval(of: .month, for: referenceDate) else { return true }
            return interval.contains(entry.date)
        case .invoiced:
            return entry.isInvoiced
        case .open:
            return entry.includeInInvoice && !entry.isInvoiced
        }
    }
}

enum TimeTrackingRepositoryError: LocalizedError {
    case entryLinkedToInvoice

    var errorDescription: String? {
        switch self {
        case .entryLinkedToInvoice:
            return "This registration is already linked to an invoice and cannot be deleted."
        }
    }
}
