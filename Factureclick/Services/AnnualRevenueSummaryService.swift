//
//  AnnualRevenueSummaryService.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import Foundation

struct AnnualRevenueClientSummary: Identifiable {
    let client: Client
    let revenue: Double
    let invoiceCount: Int

    var id: UUID { client.id }
}

struct AnnualRevenueMonthSummary: Identifiable {
    let month: Int
    let monthName: String
    let revenue: Double
    let vatCharged: Double
    let invoiceCount: Int

    var id: Int { month }
}

struct AnnualRevenueSummarySnapshot {
    let year: Int
    let totalRevenue: Double
    let totalVATCharged: Double
    let totalPaidInvoices: Double
    let totalUnpaidInvoices: Double
    let totalHoursWorked: Double
    let totalProductsServicesDelivered: Double
    let topClients: [AnnualRevenueClientSummary]
    let monthlyBreakdown: [AnnualRevenueMonthSummary]
}

struct AnnualRevenueSummaryService {
    private let calendar: Calendar
    private let invoiceRepository: InvoiceRepository

    init(
        calendar: Calendar = .current,
        invoiceRepository: InvoiceRepository = InvoiceRepository()
    ) {
        self.calendar = calendar
        self.invoiceRepository = invoiceRepository
    }

    func availableYears(
        invoices: [Invoice],
        workEntries: [WorkEntry],
        fallbackYear: Int = Calendar.current.component(.year, from: .now)
    ) -> [Int] {
        let invoiceYears = invoices.map { calendar.component(.year, from: $0.date) }
        let workEntryYears = workEntries.map { calendar.component(.year, from: $0.date) }
        return Array(Set(invoiceYears + workEntryYears + [fallbackYear])).sorted(by: >)
    }

    func makeSnapshot(
        year: Int,
        invoices: [Invoice],
        workEntries: [WorkEntry],
        referenceDate: Date = .now
    ) -> AnnualRevenueSummarySnapshot {
        let filteredInvoices = invoices
            .filter { calendar.component(.year, from: $0.date) == year }
            .sorted { $0.date > $1.date }
        let filteredWorkEntries = workEntries
            .filter { calendar.component(.year, from: $0.date) == year }

        let monthlyBreakdown = (1...12).map { month -> AnnualRevenueMonthSummary in
            let monthInvoices = filteredInvoices.filter { calendar.component(.month, from: $0.date) == month }
            return AnnualRevenueMonthSummary(
                month: month,
                monthName: calendar.monthSymbols[month - 1],
                revenue: monthInvoices.reduce(0) { $0 + $1.totalAmount },
                vatCharged: monthInvoices.reduce(0) { $0 + $1.vatAmount },
                invoiceCount: monthInvoices.count
            )
        }

        let groupedByClient = Dictionary(grouping: filteredInvoices, by: \.client.id)
        let topClients = groupedByClient.values
            .compactMap { clientInvoices -> AnnualRevenueClientSummary? in
                guard let client = clientInvoices.first?.client else { return nil }
                return AnnualRevenueClientSummary(
                    client: client,
                    revenue: clientInvoices.reduce(0) { $0 + $1.totalAmount },
                    invoiceCount: clientInvoices.count
                )
            }
            .sorted { lhs, rhs in
                if lhs.revenue != rhs.revenue {
                    return lhs.revenue > rhs.revenue
                }
                return lhs.client.name < rhs.client.name
            }

        let paidInvoices = filteredInvoices.filter {
            invoiceRepository.normalizedStatus(for: $0, referenceDate: referenceDate) == .paid
        }
        let unpaidInvoices = filteredInvoices.filter {
            invoiceRepository.normalizedStatus(for: $0, referenceDate: referenceDate) != .paid
        }

        return AnnualRevenueSummarySnapshot(
            year: year,
            totalRevenue: filteredInvoices.reduce(0) { $0 + $1.totalAmount },
            totalVATCharged: filteredInvoices.reduce(0) { $0 + $1.vatAmount },
            totalPaidInvoices: paidInvoices.reduce(0) { $0 + $1.totalAmount },
            totalUnpaidInvoices: unpaidInvoices.reduce(0) { $0 + $1.totalAmount },
            totalHoursWorked: filteredWorkEntries.reduce(0) { $0 + $1.hoursWorked },
            totalProductsServicesDelivered: filteredWorkEntries.reduce(0) { $0 + $1.quantity },
            topClients: Array(topClients.prefix(5)),
            monthlyBreakdown: monthlyBreakdown
        )
    }
}
