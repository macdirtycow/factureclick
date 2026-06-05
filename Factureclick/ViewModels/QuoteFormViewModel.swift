//
//  QuoteFormViewModel.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation
import Observation
import SwiftData

@Observable
final class QuoteFormViewModel {
    var selectedClientID: UUID?
    var quoteDate: Date
    var expiryDate: Date
    var status: QuoteStatus
    var notes: String
    var lineDrafts: [QuoteLineDraft]

    private let pricingService: QuotePricingService

    init(
        quote: Quote? = nil,
        pricingService: QuotePricingService = QuotePricingService()
    ) {
        let referenceDate = quote?.date ?? .now
        self.selectedClientID = quote?.client.id
        self.quoteDate = referenceDate
        self.expiryDate = quote?.expiryDate ?? Calendar.current.date(byAdding: .day, value: 14, to: referenceDate) ?? referenceDate
        self.status = quote?.status ?? .draft
        self.notes = quote?.notes ?? ""
        self.lineDrafts = quote?.lines.map {
            QuoteLineDraft(
                id: $0.id,
                linkedProductID: $0.linkedProduct?.id,
                description: $0.description,
                quantity: $0.quantity,
                unitPrice: $0.unitPrice,
                vatRate: $0.vatRate
            )
        } ?? [QuoteLineDraft()]
        self.pricingService = pricingService
    }

    var isValid: Bool {
        selectedClientID != nil && !lineDrafts.isEmpty && lineDrafts.contains { !$0.description.trimmed.isEmpty }
    }

    var totals: QuoteTotals {
        pricingService.makeTotals(lines: validLineDrafts)
    }

    func addLine(defaultVATRate: Double) {
        lineDrafts.append(QuoteLineDraft(vatRate: defaultVATRate))
    }

    func removeLine(id: UUID) {
        lineDrafts.removeAll { $0.id == id }
        if lineDrafts.isEmpty {
            lineDrafts = [QuoteLineDraft()]
        }
    }

    func updateLine(_ line: QuoteLineDraft, at index: Int) {
        guard lineDrafts.indices.contains(index) else { return }
        lineDrafts[index] = line
    }

    func applyProduct(_ product: Product, at index: Int) {
        guard lineDrafts.indices.contains(index) else { return }
        lineDrafts[index].linkedProductID = product.id
        lineDrafts[index].description = product.name
        lineDrafts[index].unitPrice = product.price
        lineDrafts[index].vatRate = product.vatRate
    }

    func save(
        quote: Quote?,
        clients: [Client],
        products: [Product],
        existingQuotes: [Quote],
        invoicePrefix: String,
        sequencePadding: Int,
        activeCompanyProfile: CompanyProfile?,
        in context: ModelContext
    ) throws {
        guard let selectedClientID,
              let client = clients.first(where: { $0.id == selectedClientID }) else {
            return
        }

        let repository = QuoteRepository()
        let companyProfile = CompanyProfileSelectionService().resolveQuoteProfile(
            explicitProfile: quote?.companyProfile,
            client: client,
            fallbackActiveProfile: activeCompanyProfile
        )
        let target = quote ?? Quote(
            quoteNumber: repository.nextQuoteNumber(
                existingQuotes: existingQuotes,
                quoteDate: quoteDate,
                prefix: invoicePrefix.isEmpty ? "Q" : "\(invoicePrefix)-Q",
                sequencePadding: sequencePadding
            ),
            client: client,
            companyProfile: companyProfile
        )

        target.client = client
        target.companyProfile = companyProfile
        target.date = quoteDate
        target.expiryDate = expiryDate
        target.status = status
        target.notes = notes.trimmed
        target.subtotalAmount = totals.subtotal
        target.vatAmount = totals.vat
        target.totalAmount = totals.total
        target.updatedAt = .now

        let productsByID = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
        for existingLine in target.lines {
            context.delete(existingLine)
        }
        target.lines.removeAll()
        target.lines = validLineDrafts.map { line in
            QuoteLine(
                id: line.id,
                description: line.description.trimmed,
                quantity: line.quantity,
                unitPrice: line.unitPrice,
                vatRate: line.vatRate,
                quote: target,
                linkedProduct: line.linkedProductID.flatMap { productsByID[$0] }
            )
        }

        if quote == nil {
            context.insert(target)
        }

        try context.save()
    }

    private var validLineDrafts: [QuoteLineDraft] {
        lineDrafts.filter { !$0.description.trimmed.isEmpty }
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
