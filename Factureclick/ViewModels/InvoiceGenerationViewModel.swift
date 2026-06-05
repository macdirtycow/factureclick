//
//  InvoiceGenerationViewModel.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation
import Observation
import SwiftData

enum InvoiceGenerationError: LocalizedError {
    case duplicateRegistrationsDetected
    case missingClient
    case emptyInvoiceLines

    var errorDescription: String? {
        switch self {
        case .duplicateRegistrationsDetected:
            "Sommige geselecteerde registraties zijn al gekoppeld aan een factuur of concept."
        case .missingClient:
            "Selecteer eerst een klant voordat je het concept opslaat."
        case .emptyInvoiceLines:
            "Voeg minstens één factuurregel toe voordat je het concept opslaat."
        }
    }
}

enum InvoiceGroupingMode: String, CaseIterable, Identifiable {
    case hours
    case hoursAndProducts
    case product
    case date
    case serviceType

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hours:
            "Op uren"
        case .hoursAndProducts:
            "Uren en producten"
        case .product:
            "Per product"
        case .date:
            "Per datum"
        case .serviceType:
            "Per soort dienst"
        }
    }
}

@Observable
final class InvoiceGenerationViewModel {
    var mode: InvoiceBuilderMode
    var selectedClientID: UUID?
    var startDate: Date
    var endDate: Date
    var invoiceDate: Date
    var dueDate: Date
    var documentType: InvoiceDocumentType
    var creditedInvoiceID: UUID?
    var invoiceNotes: String
    var groupingMode: InvoiceGroupingMode
    var selectedRegistrationIDs: Set<UUID>
    var lineDrafts: [InvoiceLineDraft]
    var sourceQuoteDraftContext: QuoteInvoiceDraftContext?
    var defaultPaymentTermDays: Int
    var defaultVATRate: Double

    private let repository: InvoiceRepository
    private let builderService: InvoiceBuilderService
    private let calculationService: InvoiceFinancialCalculationService
    private let quoteConversionUseCase: QuoteToInvoiceConversionUseCase

    init(
        referenceDate: Date = .now,
        repository: InvoiceRepository = InvoiceRepository(),
        builderService: InvoiceBuilderService = InvoiceBuilderService(),
        calculationService: InvoiceFinancialCalculationService = InvoiceFinancialCalculationService(),
        quoteConversionUseCase: QuoteToInvoiceConversionUseCase = QuoteToInvoiceConversionUseCase()
    ) {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: referenceDate)?.start ?? referenceDate
        let defaultPaymentTermDays = 30
        let defaultVATRate = 21.0
        self.mode = .automatic
        self.selectedClientID = nil
        self.startDate = startOfWeek
        self.endDate = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? referenceDate
        self.invoiceDate = referenceDate
        self.documentType = .standard
        self.creditedInvoiceID = nil
        self.defaultPaymentTermDays = defaultPaymentTermDays
        self.defaultVATRate = defaultVATRate
        self.dueDate = calendar.date(byAdding: .day, value: defaultPaymentTermDays, to: referenceDate) ?? referenceDate
        self.invoiceNotes = ""
        self.groupingMode = .hoursAndProducts
        self.selectedRegistrationIDs = []
        self.lineDrafts = []
        self.sourceQuoteDraftContext = nil
        self.repository = repository
        self.builderService = builderService
        self.calculationService = calculationService
        self.quoteConversionUseCase = quoteConversionUseCase
    }

    var canGenerateAutomaticLines: Bool {
        selectedClientID != nil && startDate <= endDate
    }

    var canSaveDraft: Bool {
        canSave
    }

    var canSave: Bool {
        selectedClientID != nil && !lineDrafts.isEmpty
    }

    func availableRegistrations(from workEntries: [WorkEntry]) -> [WorkEntry] {
        repository.registrations(
            from: workEntries,
            clientID: selectedClientID,
            startDate: startDate,
            endDate: endDate
        )
    }

    func syncSelection(with entries: [WorkEntry]) {
        let availableIDs = Set(entries.map(\.id))
        selectedRegistrationIDs = selectedRegistrationIDs.intersection(availableIDs)
    }

    func updateDueDate(for client: Client?) {
        let paymentTerm = client?.paymentTermDays ?? defaultPaymentTermDays
        dueDate = Calendar.current.date(byAdding: .day, value: paymentTerm, to: invoiceDate) ?? invoiceDate
    }

    func toggleRegistration(_ entry: WorkEntry) {
        if selectedRegistrationIDs.contains(entry.id) {
            selectedRegistrationIDs.remove(entry.id)
        } else {
            selectedRegistrationIDs.insert(entry.id)
        }
    }

    func syncSelectedClient(with entries: [WorkEntry]) {
        let selectedClientIDs = Set(
            entries
                .filter { selectedRegistrationIDs.contains($0.id) }
                .map(\.client.id)
        )

        switch selectedClientIDs.count {
        case 1:
            selectedClientID = selectedClientIDs.first
        default:
            selectedClientID = nil
        }
    }

    func generateAutomaticLines(from availableEntries: [WorkEntry]) {
        let selectedEntries = availableEntries.filter { selectedRegistrationIDs.contains($0.id) }
        let generated = builderService.automaticLines(
            from: selectedEntries,
            groupingMode: groupingMode,
            defaultVATRate: defaultVATRate
        )

        switch mode {
        case .manual:
            break
        case .automatic:
            lineDrafts = generated
        case .mixed:
            let manualLines = lineDrafts.filter { $0.linkedWorkEntryIDs.isEmpty }
            lineDrafts = manualLines + generated
        }
    }

    func addLine(kind: InvoiceLineKind = .productService) {
        if mode == .automatic {
            mode = .mixed
        }

        lineDrafts.append(
            InvoiceLineDraft(
                kind: kind,
                description: kind.defaultDescription,
                quantity: 1,
                unitPrice: kind == .discount ? -0 : 0,
                vatRate: defaultVATRate
            )
        )
    }

    func apply(settings: AppSettings?) {
        let updatedPaymentTerm = max(1, settings?.defaultPaymentTermDays ?? 30)
        let updatedVATRate = max(0, settings?.defaultVATRate ?? 21)
        let previousPaymentTerm = defaultPaymentTermDays

        defaultPaymentTermDays = updatedPaymentTerm
        defaultVATRate = updatedVATRate

        let expectedPreviousDueDate = Calendar.current.date(byAdding: .day, value: previousPaymentTerm, to: invoiceDate) ?? invoiceDate
        if dueDate == expectedPreviousDueDate || selectedClientID == nil {
            updateDueDate(for: nil)
        }
    }

    @discardableResult
    func applyWorkflowContext(
        _ context: InvoiceWorkflowLaunchContext,
        workEntries: [WorkEntry]
    ) -> [WorkEntry] {
        let eligibleEntries = workEntries
            .filter { context.selectedRegistrationIDs.contains($0.id) }
            .filter { $0.includeInInvoice && !$0.isInvoiced && $0.invoiceLine == nil }
            .sorted { $0.date > $1.date }

        guard !eligibleEntries.isEmpty else { return [] }

        mode = .automatic
        selectedClientID = context.selectedClientID

        if let suggestedStartDate = context.suggestedStartDate {
            startDate = Calendar.current.startOfDay(for: suggestedStartDate)
        }

        if let suggestedEndDate = context.suggestedEndDate {
            endDate = suggestedEndDate
        }

        selectedRegistrationIDs = Set(eligibleEntries.map(\.id))
        if selectedClientID == nil, Set(eligibleEntries.map(\.client.id)).count == 1 {
            selectedClientID = eligibleEntries.first?.client.id
        }

        let availableEntries = availableRegistrations(from: workEntries)
        syncSelection(with: availableEntries)
        generateAutomaticLines(from: availableEntries)
        return availableEntries.filter { selectedRegistrationIDs.contains($0.id) }
    }

    func removeLine(id: UUID) {
        lineDrafts.removeAll { $0.id == id }
    }

    func applyQuoteConversionDraft(_ draftContext: QuoteInvoiceDraftContext) {
        sourceQuoteDraftContext = draftContext
        mode = .manual
        selectedClientID = draftContext.clientID
        invoiceDate = draftContext.invoiceDate
        dueDate = draftContext.dueDate
        invoiceNotes = draftContext.notes
        lineDrafts = draftContext.lineDrafts
        selectedRegistrationIDs.removeAll()
    }

    func updateLine(_ line: InvoiceLineDraft, at index: Int) {
        guard lineDrafts.indices.contains(index) else { return }
        lineDrafts[index] = line
    }

    func lineDraft(id: UUID) -> InvoiceLineDraft? {
        lineDrafts.first { $0.id == id }
    }

    func updateLine(id: UUID, _ mutate: (inout InvoiceLineDraft) -> Void) {
        guard let index = lineDrafts.firstIndex(where: { $0.id == id }) else { return }
        mutate(&lineDrafts[index])
    }

    func applyProduct(_ product: Product, toLineWithID id: UUID) {
        updateLine(id: id) { draft in
            draft.linkedProductID = product.id
            draft.description = product.description.isEmpty ? product.name : product.description
            draft.quantity = max(draft.quantity, 1)
            draft.unitPrice = product.price
            draft.vatRate = product.vatRate
        }
    }

    func clearLinkedProduct(forLineWithID id: UUID) {
        updateLine(id: id) { draft in
            draft.linkedProductID = nil
        }
    }

    func totals(collaborationRule: CollaborationRule?) -> InvoiceDraftTotals {
        calculationService.makeTotals(lines: signedLineDrafts, collaborationRule: collaborationRule)
    }

    func lineCalculation(for line: InvoiceLineDraft) -> InvoiceLineCalculation {
        calculationService.calculation(for: signedLineDraft(line))
    }

    func saveInvoice(
        in context: ModelContext,
        clients: [Client],
        workEntries: [WorkEntry],
        existingInvoices: [Invoice],
        quotes: [Quote],
        companyProfiles: [CompanyProfile],
        activeCompanyProfile: CompanyProfile?,
        collaborationRule: CollaborationRule?,
        invoiceNumberPrefix: String,
        creditInvoiceNumberPrefix: String,
        invoiceNumberSequencePadding: Int
    ) throws -> Invoice {
        guard selectedClientID != nil else {
            throw InvoiceGenerationError.missingClient
        }
        guard !lineDrafts.isEmpty else {
            throw InvoiceGenerationError.emptyInvoiceLines
        }
        guard let client = clients.first(where: { $0.id == selectedClientID }) else {
            throw InvoiceGenerationError.missingClient
        }

        let includedIDs = Set(lineDrafts.flatMap(\.linkedWorkEntryIDs))
        let duplicateEntries = workEntries.filter {
            includedIDs.contains($0.id) && ($0.isInvoiced || $0.invoiceLine != nil)
        }
        guard duplicateEntries.isEmpty else {
            throw InvoiceGenerationError.duplicateRegistrationsDetected
        }

        let persistedLineDrafts = signedLineDrafts
        let persistedTotals = calculationService.makeTotals(lines: persistedLineDrafts, collaborationRule: collaborationRule)
        let creditedInvoice = documentType == .credit
            ? existingInvoices.first(where: { $0.id == creditedInvoiceID })
            : nil

        if let sourceQuoteDraftContext {
            let invoice = try quoteConversionUseCase.finalizeConversion(
                draftContext: sourceQuoteDraftContext,
                invoiceDate: invoiceDate,
                dueDate: dueDate,
                notes: invoiceNotes,
                lineDrafts: persistedLineDrafts,
                documentType: documentType,
                existingInvoices: existingInvoices,
                quotes: quotes,
                clients: clients,
                companyProfiles: companyProfiles,
                activeCompanyProfile: activeCompanyProfile,
                invoiceNumberPrefix: invoiceNumberPrefix,
                creditInvoiceNumberPrefix: creditInvoiceNumberPrefix,
                invoiceNumberSequencePadding: invoiceNumberSequencePadding,
                context: context
            )
            self.sourceQuoteDraftContext = nil
            selectedRegistrationIDs.removeAll()
            lineDrafts = []
            return invoice
        }

        let invoice = Invoice(
            invoiceNumber: nextDocumentNumber(
                existingInvoices: existingInvoices,
                invoiceNumberPrefix: invoiceNumberPrefix,
                creditInvoiceNumberPrefix: creditInvoiceNumberPrefix,
                invoiceNumberSequencePadding: invoiceNumberSequencePadding
            ),
            client: client,
            date: invoiceDate,
            dueDate: dueDate,
            documentType: documentType,
            status: .draft,
            notes: invoiceNotes.trimmingCharacters(in: .whitespacesAndNewlines),
            totalAmount: persistedTotals.total,
            vatAmount: persistedTotals.vat,
            creditedInvoiceID: creditedInvoice?.id,
            creditedInvoiceNumber: creditedInvoice?.invoiceNumber ?? "",
            createdAt: .now,
            companyProfile: CompanyProfileSelectionService().resolveInvoiceProfile(
                explicitProfile: nil,
                client: client,
                registrations: workEntries.filter { includedIDs.contains($0.id) },
                fallbackActiveProfile: activeCompanyProfile
            )
        )

        let workEntriesByID = Dictionary(uniqueKeysWithValues: workEntries.map { ($0.id, $0) })

        invoice.lines = persistedLineDrafts.flatMap { line in
            if line.linkedWorkEntryIDs.count <= 1 {
                let linkedEntry = line.linkedWorkEntryIDs.count == 1
                    ? workEntriesByID[line.linkedWorkEntryIDs[0]]
                    : nil

                return [
                    InvoiceLine(
                        description: line.description,
                        quantity: line.quantity,
                        unitPrice: line.unitPrice,
                        vatRate: line.vatRate,
                        invoice: invoice,
                        linkedWorkEntry: linkedEntry
                    )
                ]
            }

            let linkedEntries = line.linkedWorkEntryIDs.compactMap { workEntriesByID[$0] }
            guard !linkedEntries.isEmpty else {
                return [
                    InvoiceLine(
                        description: line.description,
                        quantity: line.quantity,
                        unitPrice: line.unitPrice,
                        vatRate: line.vatRate,
                        invoice: invoice
                    )
                ]
            }

            return linkedEntries.map { entry in
                let quantity = entry.product?.unitType == .hour || entry.product == nil
                    ? entry.hoursWorked
                    : entry.quantity
                let unitPrice = entry.product?.unitType == .hour || entry.product == nil
                    ? entry.effectiveHourlyRate
                    : (entry.product?.price ?? line.unitPrice)
                let description = entry.product?.name ?? line.description

                return InvoiceLine(
                    description: description,
                    quantity: quantity,
                    unitPrice: unitPrice,
                    vatRate: entry.product?.vatRate ?? line.vatRate,
                    invoice: invoice,
                    linkedWorkEntry: entry
                )
            }
        }

        try repository.save(invoice: invoice, in: context)

        for entry in workEntries where includedIDs.contains(entry.id) {
            entry.isInvoiced = true
        }

        try context.save()
        selectedRegistrationIDs.removeAll()
        if mode == .automatic {
            lineDrafts = []
        } else {
            lineDrafts.removeAll { !$0.linkedWorkEntryIDs.isEmpty }
        }
        return invoice
    }

    var sourceQuoteNumber: String? {
        sourceQuoteDraftContext?.quoteNumber
    }

    private var signedLineDrafts: [InvoiceLineDraft] {
        lineDrafts.map(signedLineDraft)
    }

    private func signedLineDraft(_ line: InvoiceLineDraft) -> InvoiceLineDraft {
        guard documentType == .credit else { return line }

        var signedLine = line
        signedLine.unitPrice = line.kind == .discount ? abs(line.unitPrice) : -abs(line.unitPrice)
        return signedLine
    }

    private func nextDocumentNumber(
        existingInvoices: [Invoice],
        invoiceNumberPrefix: String,
        creditInvoiceNumberPrefix: String,
        invoiceNumberSequencePadding: Int
    ) -> String {
        if documentType == .credit {
            return repository.nextCreditInvoiceNumber(
                existingInvoices: existingInvoices,
                invoiceDate: invoiceDate,
                prefix: creditInvoiceNumberPrefix,
                sequencePadding: invoiceNumberSequencePadding
            )
        }

        return repository.nextInvoiceNumber(
            existingInvoices: existingInvoices,
            invoiceDate: invoiceDate,
            prefix: invoiceNumberPrefix,
            sequencePadding: invoiceNumberSequencePadding
        )
    }
}
