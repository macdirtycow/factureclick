//
//  QuoteRepository.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation
import SwiftData

struct QuoteRepository {
    private let calendar: Calendar
    private let signatureStorageService: SignatureStorageService

    init(
        calendar: Calendar = .current,
        signatureStorageService: SignatureStorageService = SignatureStorageService()
    ) {
        self.calendar = calendar
        self.signatureStorageService = signatureStorageService
    }

    func nextQuoteNumber(existingQuotes: [Quote], quoteDate: Date, prefix: String = "Q", sequencePadding: Int = 3) -> String {
        let year = calendar.component(.year, from: quoteDate)
        let count = existingQuotes.filter { calendar.component(.year, from: $0.date) == year }.count + 1
        let normalizedPadding = min(max(sequencePadding, 2), 6)
        let normalizedPrefix = prefix.trimmingCharacters(in: .whitespacesAndNewlines)
        let baseNumber = String(format: "%d-%0\(normalizedPadding)d", year, count)
        return normalizedPrefix.isEmpty ? baseNumber : "\(normalizedPrefix)-\(baseNumber)"
    }

    func normalizedStatus(for quote: Quote, referenceDate: Date = .now) -> QuoteStatus {
        if quote.status == .accepted || quote.status == .rejected {
            return quote.status
        }

        if quote.expiryDate < calendar.startOfDay(for: referenceDate) {
            return .expired
        }

        return quote.status
    }

    func canConvertToInvoice(_ quote: Quote, referenceDate: Date = .now) -> Bool {
        normalizedStatus(for: quote, referenceDate: referenceDate) == .accepted && quote.convertedInvoice == nil
    }

    func save(quote: Quote, in context: ModelContext) throws {
        context.insert(quote)
        try context.save()
    }

    func delete(_ quote: Quote, in context: ModelContext) throws {
        if let signature = quote.customerSignature {
            signatureStorageService.deleteStoredSignature(
                imageLocalPath: signature.imageLocalPath,
                strokeLocalPath: signature.strokeLocalPath
            )
        }

        if let convertedInvoice = quote.convertedInvoice {
            convertedInvoice.sourceQuote = nil
        }

        context.delete(quote)
        try context.save()
    }
}
