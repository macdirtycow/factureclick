//
//  TimeTrackingViewModel.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation
import Observation

@Observable
final class TimeTrackingViewModel {
    var invoicePeriodStartDate: Date
    var invoicePeriodEndDate: Date

    var weeklySummary = TimeTrackingPeriodSummary(totalHours: 0, billableHours: 0, totalAmount: 0, pendingInvoiceHours: 0, partnerShare: 0, userNetAmount: 0)
    var invoicePeriodSummary = TimeTrackingPeriodSummary(totalHours: 0, billableHours: 0, totalAmount: 0, pendingInvoiceHours: 0, partnerShare: 0, userNetAmount: 0)
    var dailySummaries: [TimeTrackingDaySummary] = []
    var clientSummaries: [TimeTrackingClientSummary] = []
    var timeLogs: [TimeTrackingLogItem] = []
    var weeklyCollaborationSummary = CollaborationRevenueSummary(grossAmount: 0, partnerShare: 0, userNetAmount: 0, partnerSummaries: [])
    var invoicePeriodCollaborationSummary = CollaborationRevenueSummary(grossAmount: 0, partnerShare: 0, userNetAmount: 0, partnerSummaries: [])

    private let repository: TimeTrackingRepository

    init(referenceDate: Date = .now, repository: TimeTrackingRepository = TimeTrackingRepository()) {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: referenceDate)?.start ?? referenceDate
        self.invoicePeriodStartDate = weekStart
        self.invoicePeriodEndDate = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? referenceDate
        self.repository = repository
    }

    func refresh(with entries: [WorkEntry], referenceDate: Date = .now) {
        let weeklyEntries = repository.entriesForWeek(from: entries, referenceDate: referenceDate)
        let periodEntries = repository.entriesForInvoicePeriod(
            from: entries,
            startDate: invoicePeriodStartDate,
            endDate: invoicePeriodEndDate
        )

        weeklySummary = repository.makeSummary(for: weeklyEntries)
        invoicePeriodSummary = repository.makeSummary(for: periodEntries)
        dailySummaries = repository.makeDailySummaries(for: periodEntries)
        clientSummaries = repository.makeClientSummaries(for: periodEntries)
        timeLogs = repository.makeTimeLogs(for: periodEntries)
        weeklyCollaborationSummary = repository.makeCollaborationSummary(for: weeklyEntries)
        invoicePeriodCollaborationSummary = repository.makeCollaborationSummary(for: periodEntries)
    }
}
