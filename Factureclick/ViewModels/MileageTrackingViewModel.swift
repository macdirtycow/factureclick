//
//  MileageTrackingViewModel.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import Foundation
import Observation

enum MileagePeriodPreset: String, CaseIterable, Identifiable {
    case thisWeek
    case thisMonth
    case last30Days
    case allTime
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .thisWeek:
            "This Week"
        case .thisMonth:
            "This Month"
        case .last30Days:
            "30 Days"
        case .allTime:
            "All Time"
        case .custom:
            "Custom"
        }
    }
}

@Observable
final class MileageTrackingViewModel {
    var selectedClientID: UUID?
    var searchText = ""
    var periodStartDate: Date
    var periodEndDate: Date
    var selectedPreset: MileagePeriodPreset = .thisMonth

    var weeklySummary = MileagePeriodSummary(
        entryCount: 0,
        totalKilometers: 0,
        totalTravelCost: 0,
        invoiceEligibleKilometers: 0,
        invoiceEligibleCost: 0
    )
    var monthlySummary = MileagePeriodSummary(
        entryCount: 0,
        totalKilometers: 0,
        totalTravelCost: 0,
        invoiceEligibleKilometers: 0,
        invoiceEligibleCost: 0
    )
    var selectedPeriodSummary = MileagePeriodSummary(
        entryCount: 0,
        totalKilometers: 0,
        totalTravelCost: 0,
        invoiceEligibleKilometers: 0,
        invoiceEligibleCost: 0
    )
    var filteredEntries: [MileageEntry] = []

    private let repository: MileageRepository

    init(referenceDate: Date = .now, repository: MileageRepository = MileageRepository()) {
        let calendar = Calendar.current
        let monthInterval = calendar.dateInterval(of: .month, for: referenceDate)
        self.periodStartDate = monthInterval?.start ?? referenceDate
        self.periodEndDate = monthInterval?.end.addingTimeInterval(-1) ?? referenceDate
        self.repository = repository
    }

    func refresh(with entries: [MileageEntry], referenceDate: Date = .now) {
        let range = repository.normalizedRange(startDate: periodStartDate, endDate: periodEndDate)
        periodStartDate = range.lowerBound
        periodEndDate = range.upperBound
        weeklySummary = repository.makeSummary(for: repository.entriesForWeek(from: entries, referenceDate: referenceDate))
        monthlySummary = repository.makeSummary(for: repository.entriesForMonth(from: entries, referenceDate: referenceDate))
        filteredEntries = repository.filteredEntries(
            from: entries,
            clientID: selectedClientID,
            startDate: periodStartDate,
            endDate: periodEndDate,
            searchText: searchText
        )
        selectedPeriodSummary = repository.makeSummary(for: filteredEntries)
    }

    func applyPreset(_ preset: MileagePeriodPreset, using entries: [MileageEntry], referenceDate: Date = .now) {
        selectedPreset = preset

        let calendar = Calendar.current

        switch preset {
        case .thisWeek:
            guard let interval = calendar.dateInterval(of: .weekOfYear, for: referenceDate) else { return }
            periodStartDate = interval.start
            periodEndDate = interval.end.addingTimeInterval(-1)
        case .thisMonth:
            guard let interval = calendar.dateInterval(of: .month, for: referenceDate) else { return }
            periodStartDate = interval.start
            periodEndDate = interval.end.addingTimeInterval(-1)
        case .last30Days:
            periodStartDate = calendar.date(byAdding: .day, value: -29, to: calendar.startOfDay(for: referenceDate)) ?? referenceDate
            periodEndDate = referenceDate
        case .allTime:
            let sortedEntries = entries.sorted { $0.date < $1.date }
            periodStartDate = sortedEntries.first?.date ?? referenceDate
            periodEndDate = sortedEntries.last?.date ?? referenceDate
        case .custom:
            break
        }
    }

    func updateCustomStartDate(_ date: Date) {
        periodStartDate = date
        selectedPreset = .custom
    }

    func updateCustomEndDate(_ date: Date) {
        periodEndDate = date
        selectedPreset = .custom
    }
}
