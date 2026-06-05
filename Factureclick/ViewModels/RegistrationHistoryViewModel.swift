//
//  RegistrationHistoryViewModel.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation
import Observation

enum RegistrationDateFilter: String, CaseIterable, Identifiable {
    case all
    case thisWeek
    case thisMonth
    case invoiced
    case open

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            "All"
        case .thisWeek:
            "This Week"
        case .thisMonth:
            "This Month"
        case .invoiced:
            "Invoiced"
        case .open:
            "Open"
        }
    }
}

@Observable
final class RegistrationHistoryViewModel {
    var searchText = ""
    var selectedClientID: UUID?
    var selectedFilter: RegistrationDateFilter = .all

    var filteredEntries: [WorkEntry] = []
    var filteredSummary = TimeTrackingPeriodSummary(
        totalHours: 0,
        billableHours: 0,
        totalAmount: 0,
        pendingInvoiceHours: 0,
        partnerShare: 0,
        userNetAmount: 0
    )

    private let repository: TimeTrackingRepository

    init(repository: TimeTrackingRepository = TimeTrackingRepository()) {
        self.repository = repository
    }

    func refresh(with entries: [WorkEntry], referenceDate: Date = .now) {
        filteredEntries = repository.filteredHistoryEntries(
            from: entries,
            clientID: selectedClientID,
            searchText: searchText,
            filter: selectedFilter,
            referenceDate: referenceDate
        )
        filteredSummary = repository.makeSummary(for: filteredEntries)
    }
}
