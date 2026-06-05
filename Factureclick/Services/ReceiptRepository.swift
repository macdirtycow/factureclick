//
//  ReceiptRepository.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import Foundation

struct ReceiptSummary {
    let receiptCount: Int
    let totalAmount: Double
    let totalVATAmount: Double
    let linkedReceiptCount: Int
}

struct ReceiptRepository {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func makeSummary(for receipts: [Receipt]) -> ReceiptSummary {
        ReceiptSummary(
            receiptCount: receipts.count,
            totalAmount: receipts.reduce(0) { $0 + $1.amount },
            totalVATAmount: receipts.reduce(0) { $0 + ($1.vatAmount ?? 0) },
            linkedReceiptCount: receipts.filter { $0.linkedInvoice != nil || $0.linkedWorkEntry != nil }.count
        )
    }

    func filteredReceipts(
        from receipts: [Receipt],
        category: ReceiptCategory?,
        clientID: UUID?,
        startDate: Date,
        endDate: Date,
        searchText: String = ""
    ) -> [Receipt] {
        let normalizedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let range = normalizedRange(startDate: startDate, endDate: endDate)

        return receipts
            .filter { range.contains($0.date) }
            .filter { receipt in
                let matchesCategory = category == nil || receipt.category == category
                let matchesClient = clientID == nil || receipt.linkedClient?.id == clientID
                let searchBlob = [
                    receipt.supplierName,
                    receipt.notes,
                    receipt.category.title,
                    receipt.linkedClient?.name ?? "",
                    receipt.linkedInvoice?.invoiceNumber ?? ""
                ]
                .joined(separator: " ")
                .lowercased()
                let matchesSearch = normalizedSearch.isEmpty || searchBlob.contains(normalizedSearch)
                return matchesCategory && matchesClient && matchesSearch
            }
            .sorted { lhs, rhs in
                if lhs.date != rhs.date {
                    return lhs.date > rhs.date
                }
                return lhs.createdAt > rhs.createdAt
            }
    }

    func normalizedRange(startDate: Date, endDate: Date) -> ClosedRange<Date> {
        let normalizedStart = calendar.startOfDay(for: min(startDate, endDate))
        let normalizedEndDate = max(startDate, endDate)
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: normalizedEndDate) ?? normalizedEndDate
        return normalizedStart...endOfDay
    }
}
