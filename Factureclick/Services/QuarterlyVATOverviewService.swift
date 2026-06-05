//
//  QuarterlyVATOverviewService.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import Foundation

struct VATQuarter: Identifiable, Hashable {
    let year: Int
    let quarter: Int

    var id: String { "\(year)-Q\(quarter)" }

    var title: String {
        "Q\(quarter) \(year)"
    }
}

struct VATInvoiceBreakdownItem: Identifiable {
    let invoice: Invoice
    let netRevenueExcludingVAT: Double
    let vatCharged: Double
    let totalIncludingVAT: Double
    let isPaid: Bool

    var id: UUID { invoice.id }
}

struct VATClientBreakdownItem: Identifiable {
    let client: Client
    let invoiceCount: Int
    let netRevenueExcludingVAT: Double
    let vatCharged: Double
    let totalIncludingVAT: Double
    let paidTotalIncludingVAT: Double
    let unpaidTotalIncludingVAT: Double

    var id: UUID { client.id }
}

struct QuarterlyVATOverview {
    let quarter: VATQuarter
    let dateRange: ClosedRange<Date>
    let totalRevenueExcludingVAT: Double
    let totalVATCharged: Double
    let totalInvoicesInPeriod: Int
    let paidTotalIncludingVAT: Double
    let unpaidTotalIncludingVAT: Double
    let invoiceBreakdown: [VATInvoiceBreakdownItem]
    let clientBreakdown: [VATClientBreakdownItem]
}

struct QuarterlyVATOverviewService {
    private let calendar: Calendar
    private let repository: InvoiceRepository

    init(calendar: Calendar = .current, repository: InvoiceRepository = InvoiceRepository()) {
        self.calendar = calendar
        self.repository = repository
    }

    func availableYears(from invoices: [Invoice], fallbackYear: Int = Calendar.current.component(.year, from: .now)) -> [Int] {
        let years = Set(invoices.map { calendar.component(.year, from: $0.date) })
        return Array(years.union([fallbackYear])).sorted(by: >)
    }

    func currentQuarter(for date: Date = .now) -> VATQuarter {
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let quarter = ((month - 1) / 3) + 1
        return VATQuarter(year: year, quarter: quarter)
    }

    func overview(for quarter: VATQuarter, from invoices: [Invoice], referenceDate: Date = .now) -> QuarterlyVATOverview {
        let quarterInvoices = repository.invoicesForQuarter(
            from: invoices,
            year: quarter.year,
            quarter: quarter.quarter
        )

        let invoiceBreakdown = quarterInvoices.map { invoice in
            VATInvoiceBreakdownItem(
                invoice: invoice,
                netRevenueExcludingVAT: invoice.totalAmount - invoice.vatAmount,
                vatCharged: invoice.vatAmount,
                totalIncludingVAT: invoice.totalAmount,
                isPaid: repository.normalizedStatus(for: invoice, referenceDate: referenceDate) == .paid
            )
        }

        let clientBreakdown = Dictionary(grouping: invoiceBreakdown, by: { $0.invoice.client.id })
            .compactMap { _, items -> VATClientBreakdownItem? in
                guard let client = items.first?.invoice.client else { return nil }
                return VATClientBreakdownItem(
                    client: client,
                    invoiceCount: items.count,
                    netRevenueExcludingVAT: items.reduce(0) { $0 + $1.netRevenueExcludingVAT },
                    vatCharged: items.reduce(0) { $0 + $1.vatCharged },
                    totalIncludingVAT: items.reduce(0) { $0 + $1.totalIncludingVAT },
                    paidTotalIncludingVAT: items.filter { $0.isPaid && !$0.invoice.isCreditInvoice }.reduce(0) { $0 + $1.totalIncludingVAT },
                    unpaidTotalIncludingVAT: items.filter { !$0.isPaid && !$0.invoice.isCreditInvoice }.reduce(0) { $0 + $1.totalIncludingVAT }
                )
            }
            .sorted { lhs, rhs in
                if lhs.totalIncludingVAT != rhs.totalIncludingVAT {
                    return lhs.totalIncludingVAT > rhs.totalIncludingVAT
                }
                return lhs.client.name < rhs.client.name
            }

        let range = repository.dateRangeForQuarter(year: quarter.year, quarter: quarter.quarter)

        return QuarterlyVATOverview(
            quarter: quarter,
            dateRange: range,
            totalRevenueExcludingVAT: invoiceBreakdown.reduce(0) { $0 + $1.netRevenueExcludingVAT },
            totalVATCharged: invoiceBreakdown.reduce(0) { $0 + $1.vatCharged },
            totalInvoicesInPeriod: invoiceBreakdown.count,
            paidTotalIncludingVAT: invoiceBreakdown.filter { $0.isPaid && !$0.invoice.isCreditInvoice }.reduce(0) { $0 + $1.totalIncludingVAT },
            unpaidTotalIncludingVAT: invoiceBreakdown.filter { !$0.isPaid && !$0.invoice.isCreditInvoice }.reduce(0) { $0 + $1.totalIncludingVAT },
            invoiceBreakdown: invoiceBreakdown,
            clientBreakdown: clientBreakdown
        )
    }
}
