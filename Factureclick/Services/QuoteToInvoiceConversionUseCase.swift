//
//  QuoteToInvoiceConversionUseCase.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation
import SwiftData

struct QuoteInvoiceDraftContext: Equatable {
    let quoteID: UUID
    let quoteNumber: String
    let clientID: UUID
    let companyProfileID: UUID?
    let invoiceDate: Date
    let dueDate: Date
    let notes: String
    let lineDrafts: [InvoiceLineDraft]

    var fingerprint: String {
        [
            quoteID.uuidString,
            quoteNumber,
            clientID.uuidString,
            companyProfileID?.uuidString ?? "nil",
            String(invoiceDate.timeIntervalSince1970),
            String(dueDate.timeIntervalSince1970),
            lineDrafts.map(\.id.uuidString).joined(separator: ",")
        ].joined(separator: "|")
    }
}

enum QuoteToInvoiceConversionError: LocalizedError {
    case quoteNotAccepted
    case quoteAlreadyConverted
    case missingQuote
    case missingClient

    var errorDescription: String? {
        switch self {
        case .quoteNotAccepted:
            "Only accepted quotes can be converted to invoices."
        case .quoteAlreadyConverted:
            "This quote has already been converted to an invoice."
        case .missingQuote:
            "The selected quote could not be found."
        case .missingClient:
            "The quote client could not be found."
        }
    }
}

struct QuoteToInvoiceConversionUseCase {
    private let quoteRepository: QuoteRepository
    private let invoiceRepository: InvoiceRepository
    private let calculationService: InvoiceFinancialCalculationService

    init(
        quoteRepository: QuoteRepository = QuoteRepository(),
        invoiceRepository: InvoiceRepository = InvoiceRepository(),
        calculationService: InvoiceFinancialCalculationService = InvoiceFinancialCalculationService()
    ) {
        self.quoteRepository = quoteRepository
        self.invoiceRepository = invoiceRepository
        self.calculationService = calculationService
    }

    func prepareDraft(
        from quote: Quote,
        defaultPaymentTermDays: Int
    ) throws -> QuoteInvoiceDraftContext {
        guard quoteRepository.normalizedStatus(for: quote) == .accepted else {
            throw QuoteToInvoiceConversionError.quoteNotAccepted
        }

        guard quote.convertedInvoice == nil else {
            throw QuoteToInvoiceConversionError.quoteAlreadyConverted
        }

        let invoiceDate = Date.now
        let dueDate = Calendar.current.date(byAdding: .day, value: quote.client.paymentTermDays > 0 ? quote.client.paymentTermDays : defaultPaymentTermDays, to: invoiceDate) ?? invoiceDate
        let notes = ([ "Converted from quote \(quote.quoteNumber)", quote.notes.trimmingCharacters(in: .whitespacesAndNewlines) ]
            .filter { !$0.isEmpty })
            .joined(separator: "\n\n")

        return QuoteInvoiceDraftContext(
            quoteID: quote.id,
            quoteNumber: quote.quoteNumber,
            clientID: quote.client.id,
            companyProfileID: quote.companyProfile?.id,
            invoiceDate: invoiceDate,
            dueDate: dueDate,
            notes: notes,
            lineDrafts: quote.lines.map {
                InvoiceLineDraft(
                    id: $0.id,
                    kind: .productService,
                    description: $0.description,
                    quantity: $0.quantity,
                    unitPrice: $0.unitPrice,
                    vatRate: $0.vatRate
                )
            }
        )
    }

    func finalizeConversion(
        draftContext: QuoteInvoiceDraftContext,
        invoiceDate: Date,
        dueDate: Date,
        notes: String,
        lineDrafts: [InvoiceLineDraft],
        documentType: InvoiceDocumentType = .standard,
        existingInvoices: [Invoice],
        quotes: [Quote],
        clients: [Client],
        companyProfiles: [CompanyProfile],
        activeCompanyProfile: CompanyProfile?,
        invoiceNumberPrefix: String,
        creditInvoiceNumberPrefix: String = "CR",
        invoiceNumberSequencePadding: Int,
        context: ModelContext
    ) throws -> Invoice {
        guard let quote = quotes.first(where: { $0.id == draftContext.quoteID }) else {
            throw QuoteToInvoiceConversionError.missingQuote
        }

        guard quoteRepository.normalizedStatus(for: quote) == .accepted else {
            throw QuoteToInvoiceConversionError.quoteNotAccepted
        }

        guard quote.convertedInvoice == nil else {
            throw QuoteToInvoiceConversionError.quoteAlreadyConverted
        }

        guard let client = clients.first(where: { $0.id == draftContext.clientID }) else {
            throw QuoteToInvoiceConversionError.missingClient
        }

        let totals = calculationService.makeTotals(lines: lineDrafts, collaborationRule: nil)
        let companyProfile = companyProfiles.first(where: { $0.id == draftContext.companyProfileID })
            ?? client.companyProfile
            ?? activeCompanyProfile
        let invoiceNumber = documentType == .credit
            ? invoiceRepository.nextCreditInvoiceNumber(
                existingInvoices: existingInvoices,
                invoiceDate: invoiceDate,
                prefix: creditInvoiceNumberPrefix,
                sequencePadding: invoiceNumberSequencePadding
            )
            : invoiceRepository.nextInvoiceNumber(
                existingInvoices: existingInvoices,
                invoiceDate: invoiceDate,
                prefix: invoiceNumberPrefix,
                sequencePadding: invoiceNumberSequencePadding
            )
        let invoice = Invoice(
            invoiceNumber: invoiceNumber,
            client: client,
            date: invoiceDate,
            dueDate: dueDate,
            documentType: documentType,
            status: .draft,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            totalAmount: totals.total,
            vatAmount: totals.vat,
            createdAt: .now,
            sourceQuote: quote,
            companyProfile: companyProfile
        )

        invoice.lines = lineDrafts.map {
            InvoiceLine(
                description: $0.description,
                quantity: $0.quantity,
                unitPrice: $0.unitPrice,
                vatRate: $0.vatRate,
                invoice: invoice
            )
        }

        context.insert(invoice)
        quote.convertedInvoice = invoice
        quote.convertedAt = .now
        quote.updatedAt = .now
        try context.save()
        return invoice
    }
}
