//
//  MileageRepository.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import Foundation

struct MileagePeriodSummary {
    let entryCount: Int
    let totalKilometers: Double
    let totalTravelCost: Double
    let invoiceEligibleKilometers: Double
    let invoiceEligibleCost: Double
}

struct MileageLogItem: Identifiable {
    let entry: MileageEntry

    var id: UUID { entry.id }
}

struct MileageRepository {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func totalTravelCost(kilometers: Double, ratePerKilometer: Double) -> Double {
        max(kilometers, 0) * max(ratePerKilometer, 0)
    }

    func entriesForWeek(from entries: [MileageEntry], referenceDate: Date = .now) -> [MileageEntry] {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: referenceDate) else { return [] }
        return filteredEntries(in: normalizedRange(startDate: interval.start, endDate: interval.end), from: entries)
    }

    func entriesForMonth(from entries: [MileageEntry], referenceDate: Date = .now) -> [MileageEntry] {
        guard let interval = calendar.dateInterval(of: .month, for: referenceDate) else { return [] }
        return filteredEntries(in: normalizedRange(startDate: interval.start, endDate: interval.end), from: entries)
    }

    func entriesForPeriod(from entries: [MileageEntry], startDate: Date, endDate: Date) -> [MileageEntry] {
        filteredEntries(in: normalizedRange(startDate: startDate, endDate: endDate), from: entries)
    }

    func filteredEntries(
        from entries: [MileageEntry],
        clientID: UUID?,
        startDate: Date,
        endDate: Date,
        searchText: String = ""
    ) -> [MileageEntry] {
        let normalizedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return entriesForPeriod(from: entries, startDate: startDate, endDate: endDate)
            .filter { entry in
                let matchesClient = clientID == nil || entry.client?.id == clientID
                let matchesSearch = normalizedSearch.isEmpty || [
                    entry.startLocation,
                    entry.endLocation,
                    entry.purpose,
                    entry.client?.name ?? ""
                ]
                .joined(separator: " ")
                .lowercased()
                .contains(normalizedSearch)
                return matchesClient && matchesSearch
            }
            .sorted { $0.date > $1.date }
    }

    func makeSummary(for entries: [MileageEntry]) -> MileagePeriodSummary {
        let invoiceEligibleEntries = entries.filter(\.includeOnInvoice)

        return MileagePeriodSummary(
            entryCount: entries.count,
            totalKilometers: entries.reduce(0) { $0 + $1.numberOfKilometers },
            totalTravelCost: entries.reduce(0) { $0 + $1.totalTravelCost },
            invoiceEligibleKilometers: invoiceEligibleEntries.reduce(0) { $0 + $1.numberOfKilometers },
            invoiceEligibleCost: invoiceEligibleEntries.reduce(0) { $0 + $1.totalTravelCost }
        )
    }

    func makeLogItems(for entries: [MileageEntry]) -> [MileageLogItem] {
        entries
            .sorted { $0.date > $1.date }
            .map(MileageLogItem.init(entry:))
    }

    func normalizedRange(startDate: Date, endDate: Date) -> ClosedRange<Date> {
        let normalizedStart = calendar.startOfDay(for: min(startDate, endDate))
        let normalizedEndDate = max(startDate, endDate)
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: normalizedEndDate) ?? normalizedEndDate
        return normalizedStart...endOfDay
    }

    private func filteredEntries(in range: ClosedRange<Date>, from entries: [MileageEntry]) -> [MileageEntry] {
        entries.filter { range.contains($0.date) }
    }
}
