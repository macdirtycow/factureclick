//
//  WeeklyInvoiceGenerationUseCase.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation
import SwiftData

enum InvoiceGenerationPeriodMode: String, CaseIterable, Identifiable {
    case weekly
    case monthly
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weekly:
            "Weekly"
        case .monthly:
            "Monthly"
        case .custom:
            "Custom"
        }
    }
}

struct PeriodInvoiceReviewItem: Identifiable {
    let id: UUID
    let client: Client
    let invoiceNumber: String
    let invoiceDate: Date
    let dueDate: Date
    let registrationCount: Int
    let registrations: [WorkEntry]
    let lineDrafts: [InvoiceLineDraft]
    let totals: InvoiceDraftTotals
}

struct PeriodInvoiceReview {
    let mode: InvoiceGenerationPeriodMode
    let periodStart: Date
    let periodEnd: Date
    let items: [PeriodInvoiceReviewItem]
}

struct WeeklyInvoiceGenerationUseCase {
    private let repository: InvoiceRepository
    private let builderService: InvoiceBuilderService
    private let calculationService: InvoiceFinancialCalculationService
    private let calendar: Calendar

    init(
        repository: InvoiceRepository = InvoiceRepository(),
        builderService: InvoiceBuilderService = InvoiceBuilderService(),
        calculationService: InvoiceFinancialCalculationService = InvoiceFinancialCalculationService(),
        calendar: Calendar = .current
    ) {
        self.repository = repository
        self.builderService = builderService
        self.calculationService = calculationService
        self.calendar = calendar
    }

    func prepareReview(
        mode: InvoiceGenerationPeriodMode,
        referenceDate: Date,
        customStartDate: Date?,
        customEndDate: Date?,
        clientID: UUID?,
        groupingMode: InvoiceGroupingMode,
        clients: [Client],
        workEntries: [WorkEntry],
        existingInvoices: [Invoice],
        collaborationRules: [CollaborationRule],
        invoiceNumberPrefix: String,
        invoiceNumberSequencePadding: Int,
        defaultVATRate: Double
    ) -> PeriodInvoiceReview {
        let range = periodRange(
            mode: mode,
            referenceDate: referenceDate,
            customStartDate: customStartDate,
            customEndDate: customEndDate
        )

        let registrations = repository.registrations(
            from: workEntries,
            clientID: clientID,
            startDate: range.lowerBound,
            endDate: range.upperBound
        )

        let groupedByClient = Dictionary(grouping: registrations, by: \.client.id)
        var stagedInvoices = existingInvoices

        let items = groupedByClient.values.compactMap { registrations -> PeriodInvoiceReviewItem? in
            guard let first = registrations.first,
                  let client = clients.first(where: { $0.id == first.client.id }) else {
                return nil
            }

            let lineDrafts = builderService.automaticLines(
                from: registrations,
                groupingMode: groupingMode,
                defaultVATRate: defaultVATRate
            )
            let collaborationRule = collaborationRules.first(where: { $0.client?.id == client.id })
            let totals = calculationService.makeTotals(lines: lineDrafts, collaborationRule: collaborationRule)
            let invoiceDate = invoiceDate(for: mode, within: range)
            let dueDate = calendar.date(byAdding: .day, value: client.paymentTermDays, to: invoiceDate) ?? invoiceDate
            let invoiceNumber = repository.nextInvoiceNumber(
                existingInvoices: stagedInvoices,
                invoiceDate: invoiceDate,
                prefix: invoiceNumberPrefix,
                sequencePadding: invoiceNumberSequencePadding
            )

            stagedInvoices.append(
                Invoice(
                    invoiceNumber: invoiceNumber,
                    client: client,
                    date: invoiceDate,
                    dueDate: dueDate,
                    totalAmount: totals.total,
                    vatAmount: totals.vat
                )
            )

            return PeriodInvoiceReviewItem(
                id: client.id,
                client: client,
                invoiceNumber: invoiceNumber,
                invoiceDate: invoiceDate,
                dueDate: dueDate,
                registrationCount: registrations.count,
                registrations: registrations.sorted { $0.date < $1.date },
                lineDrafts: lineDrafts,
                totals: totals
            )
        }
        .sorted { $0.client.name.localizedCaseInsensitiveCompare($1.client.name) == .orderedAscending }

        return PeriodInvoiceReview(
            mode: mode,
            periodStart: range.lowerBound,
            periodEnd: range.upperBound,
            items: items
        )
    }

    func confirm(
        review: PeriodInvoiceReview,
        collaborationRules: [CollaborationRule],
        context: ModelContext
    ) throws {
        for item in review.items {
            let duplicateRegistrations = item.registrations.filter { $0.isInvoiced || $0.invoiceLine != nil }
            guard duplicateRegistrations.isEmpty else {
                throw InvoiceGenerationError.duplicateRegistrationsDetected
            }

            let invoice = Invoice(
                invoiceNumber: item.invoiceNumber,
                client: item.client,
                date: item.invoiceDate,
                dueDate: item.dueDate,
                status: .draft,
                totalAmount: item.totals.total,
                vatAmount: item.totals.vat,
                createdAt: .now
            )

            invoice.lines = item.lineDrafts.map { line in
                let linkedEntry = line.linkedWorkEntryIDs.count == 1
                    ? item.registrations.first(where: { $0.id == line.linkedWorkEntryIDs[0] })
                    : nil

                return InvoiceLine(
                    description: line.description,
                    quantity: line.quantity,
                    unitPrice: line.unitPrice,
                    vatRate: line.vatRate,
                    invoice: invoice,
                    linkedWorkEntry: linkedEntry
                )
            }

            context.insert(invoice)

            for registration in item.registrations {
                registration.isInvoiced = true
            }
        }

        try context.save()
    }

    private func periodRange(
        mode: InvoiceGenerationPeriodMode,
        referenceDate: Date,
        customStartDate: Date?,
        customEndDate: Date?
    ) -> ClosedRange<Date> {
        switch mode {
        case .weekly:
            let interval = calendar.dateInterval(of: .weekOfYear, for: referenceDate)
            let start = interval?.start ?? referenceDate
            let end = calendar.date(byAdding: .day, value: 6, to: start) ?? referenceDate
            return normalizedRange(startDate: start, endDate: end)
        case .monthly:
            let interval = calendar.dateInterval(of: .month, for: referenceDate)
            let start = interval?.start ?? referenceDate
            let end = calendar.date(byAdding: .day, value: -1, to: interval?.end ?? referenceDate) ?? referenceDate
            return normalizedRange(startDate: start, endDate: end)
        case .custom:
            return normalizedRange(startDate: customStartDate ?? referenceDate, endDate: customEndDate ?? referenceDate)
        }
    }

    private func invoiceDate(for mode: InvoiceGenerationPeriodMode, within range: ClosedRange<Date>) -> Date {
        switch mode {
        case .weekly, .monthly, .custom:
            range.upperBound
        }
    }

    private func normalizedRange(startDate: Date, endDate: Date) -> ClosedRange<Date> {
        let start = calendar.startOfDay(for: min(startDate, endDate))
        let endDateValue = max(startDate, endDate)
        let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endDateValue) ?? endDateValue
        return start...end
    }
}
