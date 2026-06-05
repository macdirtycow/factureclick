//
//  QuarterlyVATOverviewViewModel.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import Foundation
import Observation

@Observable
final class QuarterlyVATOverviewViewModel {
    var selectedYear: Int
    var selectedQuarter: Int
    var availableYears: [Int] = []
    var overview: QuarterlyVATOverview

    private let service: QuarterlyVATOverviewService

    init(
        referenceDate: Date = .now,
        service: QuarterlyVATOverviewService = QuarterlyVATOverviewService()
    ) {
        let currentQuarter = service.currentQuarter(for: referenceDate)
        self.selectedYear = currentQuarter.year
        self.selectedQuarter = currentQuarter.quarter
        self.service = service
        self.overview = service.overview(for: currentQuarter, from: [], referenceDate: referenceDate)
        self.availableYears = [currentQuarter.year]
    }

    func refresh(with invoices: [Invoice], referenceDate: Date = .now) {
        availableYears = service.availableYears(from: invoices, fallbackYear: Calendar.current.component(.year, from: referenceDate))

        if !availableYears.contains(selectedYear), let fallbackYear = availableYears.first {
            selectedYear = fallbackYear
        }

        let quarter = VATQuarter(year: selectedYear, quarter: selectedQuarter)
        overview = service.overview(for: quarter, from: invoices, referenceDate: referenceDate)
    }
}
