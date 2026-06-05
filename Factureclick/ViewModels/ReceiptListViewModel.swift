//
//  ReceiptListViewModel.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import Foundation
import Observation

@Observable
final class ReceiptListViewModel {
    var selectedCategory: ReceiptCategory?
    var selectedClientID: UUID?
    var searchText = ""
    var startDate: Date
    var endDate: Date
    var filteredReceipts: [Receipt] = []
    var filteredSummary = ReceiptSummary(receiptCount: 0, totalAmount: 0, totalVATAmount: 0, linkedReceiptCount: 0)

    private let repository: ReceiptRepository

    init(referenceDate: Date = .now, repository: ReceiptRepository = ReceiptRepository()) {
        let calendar = Calendar.current
        let monthInterval = calendar.dateInterval(of: .month, for: referenceDate)
        self.startDate = monthInterval?.start ?? referenceDate
        self.endDate = monthInterval?.end.addingTimeInterval(-1) ?? referenceDate
        self.repository = repository
    }

    func refresh(with receipts: [Receipt]) {
        let range = repository.normalizedRange(startDate: startDate, endDate: endDate)
        startDate = range.lowerBound
        endDate = range.upperBound
        filteredReceipts = repository.filteredReceipts(
            from: receipts,
            category: selectedCategory,
            clientID: selectedClientID,
            startDate: startDate,
            endDate: endDate,
            searchText: searchText
        )
        filteredSummary = repository.makeSummary(for: filteredReceipts)
    }
}
