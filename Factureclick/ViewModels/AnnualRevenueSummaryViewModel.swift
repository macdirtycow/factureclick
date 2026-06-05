//
//  AnnualRevenueSummaryViewModel.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import Foundation
import Observation

@Observable
final class AnnualRevenueSummaryViewModel {
    var selectedYear: Int
    var availableYears: [Int]
    var snapshot: AnnualRevenueSummarySnapshot

    private let service: AnnualRevenueSummaryService

    init(
        referenceDate: Date = .now,
        service: AnnualRevenueSummaryService = AnnualRevenueSummaryService()
    ) {
        let currentYear = Calendar.current.component(.year, from: referenceDate)
        self.selectedYear = currentYear
        self.availableYears = [currentYear]
        self.service = service
        self.snapshot = service.makeSnapshot(year: currentYear, invoices: [], workEntries: [], referenceDate: referenceDate)
    }

    func refresh(
        invoices: [Invoice],
        workEntries: [WorkEntry],
        referenceDate: Date = .now
    ) {
        availableYears = service.availableYears(
            invoices: invoices,
            workEntries: workEntries,
            fallbackYear: Calendar.current.component(.year, from: referenceDate)
        )

        if !availableYears.contains(selectedYear), let fallbackYear = availableYears.first {
            selectedYear = fallbackYear
        }

        snapshot = service.makeSnapshot(
            year: selectedYear,
            invoices: invoices,
            workEntries: workEntries,
            referenceDate: referenceDate
        )
    }
}
