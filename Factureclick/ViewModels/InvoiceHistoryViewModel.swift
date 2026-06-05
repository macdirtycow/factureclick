//
//  InvoiceHistoryViewModel.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation
import Observation

enum InvoiceHistoryStatusFilter: String, CaseIterable, Identifiable {
    case all
    case open
    case paid
    case overdue
    case draft

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            "All"
        case .open:
            "Open"
        case .paid:
            "Paid"
        case .overdue:
            "Overdue"
        case .draft:
            "Draft"
        }
    }
}

struct InvoiceHistoryOverview {
    let weeklyRevenue: Double
    let monthlyRevenue: Double
    let openInvoiceCount: Int
    let paidInvoiceCount: Int
    let overdueInvoiceCount: Int
    let expectedIncomingAmount: Double
}

@Observable
final class InvoiceHistoryViewModel {
    var searchText = ""
    var selectedClientID: UUID?
    var selectedStatus: InvoiceHistoryStatusFilter = .all
    var startDate: Date?
    var endDate: Date?

    var filteredInvoices: [Invoice] = []
    var overview = InvoiceHistoryOverview(
        weeklyRevenue: 0,
        monthlyRevenue: 0,
        openInvoiceCount: 0,
        paidInvoiceCount: 0,
        overdueInvoiceCount: 0,
        expectedIncomingAmount: 0
    )

    private let repository: InvoiceRepository

    init(repository: InvoiceRepository = InvoiceRepository()) {
        self.repository = repository
    }

    func refresh(with invoices: [Invoice], referenceDate: Date = .now) {
        filteredInvoices = repository.filteredInvoices(
            from: invoices,
            clientID: selectedClientID,
            statusFilter: selectedStatus,
            searchText: searchText,
            startDate: startDate,
            endDate: endDate,
            referenceDate: referenceDate
        )
        overview = InvoiceHistoryOverview(
            weeklyRevenue: repository.revenueForWeek(from: invoices, referenceDate: referenceDate),
            monthlyRevenue: repository.revenueForMonth(from: invoices, referenceDate: referenceDate),
            openInvoiceCount: repository.openInvoiceCount(from: invoices, referenceDate: referenceDate),
            paidInvoiceCount: repository.paidInvoiceCount(from: invoices, referenceDate: referenceDate),
            overdueInvoiceCount: repository.overdueInvoiceCount(from: invoices, referenceDate: referenceDate),
            expectedIncomingAmount: repository.expectedIncomingAmount(from: invoices, referenceDate: referenceDate)
        )
    }
}
