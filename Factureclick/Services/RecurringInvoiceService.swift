//
//  RecurringInvoiceService.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import Foundation
import SwiftData

struct RecurringInvoiceTemplateSummary: Identifiable {
    let template: RecurringInvoiceTemplate
    let nextPlannedDate: Date?
    let dueCycleDates: [Date]

    var id: UUID { template.id }
}

struct RecurringInvoiceGenerationResult {
    let createdInvoices: [Invoice]
    let skippedTemplateIDs: [UUID]
}

struct RecurringInvoiceService {
    private let calendar: Calendar
    private let invoiceRepository: InvoiceRepository
    private let calculationService: InvoiceFinancialCalculationService

    init(
        calendar: Calendar = .current,
        invoiceRepository: InvoiceRepository = InvoiceRepository(),
        calculationService: InvoiceFinancialCalculationService = InvoiceFinancialCalculationService()
    ) {
        self.calendar = calendar
        self.invoiceRepository = invoiceRepository
        self.calculationService = calculationService
    }

    func summaries(
        from templates: [RecurringInvoiceTemplate],
        referenceDate: Date = .now
    ) -> [RecurringInvoiceTemplateSummary] {
        templates
            .map { template in
                RecurringInvoiceTemplateSummary(
                    template: template,
                    nextPlannedDate: nextPlannedInvoiceDate(for: template, referenceDate: referenceDate),
                    dueCycleDates: dueCycleDates(for: template, referenceDate: referenceDate)
                )
            }
            .sorted {
                switch ($0.nextPlannedDate, $1.nextPlannedDate) {
                case let (lhs?, rhs?):
                    return lhs < rhs
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                case (nil, nil):
                    return $0.template.createdAt > $1.template.createdAt
                }
            }
    }

    func nextPlannedInvoiceDate(
        for template: RecurringInvoiceTemplate,
        referenceDate: Date = .now
    ) -> Date? {
        guard template.isActive else { return nil }

        let generatedCycleKeys = Set(template.generations.map { cycleKey(for: $0.cycleDate) })
        var candidate = calendar.startOfDay(for: template.startDate)
        let endDate = template.endDate.map { calendar.startOfDay(for: $0) }
        let referenceDay = calendar.startOfDay(for: referenceDate)

        while endDate == nil || candidate <= endDate! {
            if !generatedCycleKeys.contains(cycleKey(for: candidate)) && candidate >= referenceDay {
                return candidate
            }

            guard let next = advance(candidate, frequency: template.frequency) else { break }
            candidate = next
        }

        return nil
    }

    func dueCycleDates(
        for template: RecurringInvoiceTemplate,
        referenceDate: Date = .now
    ) -> [Date] {
        guard template.isActive else { return [] }

        let generatedCycleKeys = Set(template.generations.map { cycleKey(for: $0.cycleDate) })
        let referenceDay = calendar.startOfDay(for: referenceDate)
        let endDate = template.endDate.map { calendar.startOfDay(for: $0) }
        var candidate = calendar.startOfDay(for: template.startDate)
        var dueDates: [Date] = []

        while candidate <= referenceDay, endDate == nil || candidate <= endDate! {
            if !generatedCycleKeys.contains(cycleKey(for: candidate)) {
                dueDates.append(candidate)
            }

            guard let next = advance(candidate, frequency: template.frequency) else { break }
            candidate = next
        }

        return dueDates
    }

    func generateDraftInvoices(
        from templates: [RecurringInvoiceTemplate],
        existingInvoices: [Invoice],
        referenceDate: Date = .now,
        invoiceNumberPrefix: String,
        invoiceNumberSequencePadding: Int,
        activeCompanyProfile: CompanyProfile?,
        in context: ModelContext
    ) throws -> RecurringInvoiceGenerationResult {
        var allInvoices = existingInvoices
        var createdInvoices: [Invoice] = []
        var skippedTemplateIDs: [UUID] = []

        for template in templates {
            let cycleDates = dueCycleDates(for: template, referenceDate: referenceDate)
            guard !cycleDates.isEmpty else {
                skippedTemplateIDs.append(template.id)
                continue
            }

            for cycleDate in cycleDates {
                let lineDrafts = template.lines
                    .sorted { $0.sortOrder < $1.sortOrder }
                    .map {
                        InvoiceLineDraft(
                            description: $0.description,
                            quantity: $0.quantity,
                            unitPrice: $0.unitPrice,
                            vatRate: $0.vatRate
                        )
                    }
                let totals = calculationService.makeTotals(lines: lineDrafts, collaborationRule: nil)
                let invoice = Invoice(
                    invoiceNumber: invoiceRepository.nextInvoiceNumber(
                        existingInvoices: allInvoices,
                        invoiceDate: cycleDate,
                        prefix: invoiceNumberPrefix,
                        sequencePadding: invoiceNumberSequencePadding
                    ),
                    client: template.client,
                    date: cycleDate,
                    dueDate: calendar.date(byAdding: .day, value: template.paymentTermDays, to: cycleDate) ?? cycleDate,
                    status: .draft,
                    notes: template.notes,
                    totalAmount: totals.total,
                    vatAmount: totals.vat,
                    createdAt: .now,
                    sourceRecurringTemplate: template,
                    recurringCycleDate: cycleDate,
                    companyProfile: template.companyProfile ?? template.client.companyProfile ?? activeCompanyProfile
                )

                invoice.lines = template.lines
                    .sorted { $0.sortOrder < $1.sortOrder }
                    .map { line in
                        InvoiceLine(
                            description: line.description,
                            quantity: line.quantity,
                            unitPrice: line.unitPrice,
                            vatRate: line.vatRate,
                            invoice: invoice
                        )
                    }

                let generation = RecurringInvoiceGeneration(
                    cycleDate: cycleDate,
                    generatedInvoiceID: invoice.id,
                    generatedInvoiceNumber: invoice.invoiceNumber,
                    template: template
                )

                context.insert(invoice)
                context.insert(generation)
                createdInvoices.append(invoice)
                allInvoices.append(invoice)
            }
        }

        if !createdInvoices.isEmpty {
            try context.save()
        }

        return RecurringInvoiceGenerationResult(
            createdInvoices: createdInvoices,
            skippedTemplateIDs: skippedTemplateIDs
        )
    }

    private func advance(_ date: Date, frequency: RecurringInvoiceFrequency) -> Date? {
        switch frequency {
        case .weekly:
            return calendar.date(byAdding: .day, value: 7, to: date)
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date)
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: date)
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date)
        }
    }

    private func cycleKey(for date: Date) -> String {
        calendar.startOfDay(for: date).formatted(.iso8601.year().month().day())
    }
}
