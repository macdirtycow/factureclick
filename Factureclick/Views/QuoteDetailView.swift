//
//  QuoteDetailView.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import SwiftData
import SwiftUI

struct QuoteDetailView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Quote.date, order: .reverse) private var quotes: [Quote]
    @Query private var appSettings: [AppSettings]
    @Query private var moduleConfigurations: [ModuleVisibilityConfiguration]

    let quote: Quote

    @State private var editQuote: Quote?
    @State private var isPresentingConvertConfirmation = false
    @State private var isPresentingSignatureCapture = false
    @State private var conversionMessage: String?
    @State private var exportMessage: String?
    @State private var exportErrorMessage: String?
    @State private var sharedFile: ExportedInvoiceFile?
    @State private var selectedQuoteTemplateStyle: DocumentTemplateStyle?
    @State private var isPresentingDeleteConfirmation = false
    @State private var deleteErrorMessage: String?

    private let repository = QuoteRepository()
    private let conversionUseCase = QuoteToInvoiceConversionUseCase()
    private let signatureService = SignaturePersistenceService()
    private let workModeService = WorkModeConfigurationService()

    private var resolvedQuote: Quote {
        quotes.first(where: { $0.id == quote.id }) ?? quote
    }

    var body: some View {
        List {
            Section(localization.phrase("Overview")) {
                detailRow(localization.phrase("Quote number"), quote.quoteNumber)
                detailRow(localization.phrase("Client"), quote.client.name)
                detailRow(localization.phrase("Quote date"), quote.date.formatted(date: .abbreviated, time: .omitted))
                detailRow(localization.phrase("Expiry date"), quote.expiryDate.formatted(date: .abbreviated, time: .omitted))
                HStack {
                    Text(localization.phrase("Status"))
                        .foregroundStyle(AppTheme.secondaryText)
                    Spacer()
                    QuoteStatusChip(status: repository.normalizedStatus(for: quote))
                }
                detailRow(localization.phrase("Converted invoice"), quote.convertedInvoice?.invoiceNumber ?? localization.phrase("Not converted"))
            }
            .listRowBackground(AppTheme.cardBackground)

            Section(localization.phrase("Lines")) {
                ForEach(quote.lines) { line in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(line.description)
                            .font(AppTheme.bodyFont.weight(.semibold))
                            .foregroundStyle(AppTheme.primaryText)

                        Text("\(line.quantity.formatted(.number.precision(.fractionLength(0...2)))) × \(line.unitPrice.formatted(.currency(code: Locale.current.currency?.identifier ?? "EUR")))")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.secondaryText)

                        Text("\(localization.text(.vat)) \(line.vatRate.formatted(.number.precision(.fractionLength(0...2))))%")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
            }
            .listRowBackground(AppTheme.cardBackground)

            Section(localization.text(.totals)) {
                detailRow(localization.text(.subtotal), currency(quote.subtotalAmount))
                detailRow(localization.text(.vat), currency(quote.vatAmount))
                detailRow(localization.text(.total), currency(quote.totalAmount))
            }
            .listRowBackground(AppTheme.cardBackground)

            if isSignaturesEnabled {
                Section {
                    SignaturePreviewCard(
                        signature: quote.customerSignature,
                        addActionTitle: localization.phrase("Capture Signature"),
                        onAddOrEdit: {
                            isPresentingSignatureCapture = true
                        },
                        onDelete: quote.customerSignature == nil ? nil : {
                            try? signatureService.deleteSignature(for: quote, in: modelContext)
                        }
                    )
                }
                .listRowBackground(AppTheme.cardBackground)
            }

            if !quote.notes.isEmpty {
                Section(localization.phrase("Notes")) {
                    Text(quote.notes)
                        .foregroundStyle(AppTheme.primaryText)
                }
                .listRowBackground(AppTheme.cardBackground)
            }

            Section(localization.phrase("Status")) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(QuoteStatus.allCases) { status in
                            FilterChip(title: localization.phrase(status.displayName), isSelected: repository.normalizedStatus(for: quote) == status) {
                                quote.status = status
                                try? modelContext.save()
                            }
                        }
                    }
                }
            }
            .listRowBackground(AppTheme.cardBackground)

            Section(localization.phrase("Actions")) {
                Button(localization.phrase("Convert to Invoice")) {
                    isPresentingConvertConfirmation = true
                }
                .disabled(!repository.canConvertToInvoice(quote))

                if !repository.canConvertToInvoice(quote) {
                    Text(quote.convertedInvoice == nil ? localization.phrase("Only accepted quotes can be converted.") : localization.phrase("This quote has already been converted."))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .listRowBackground(AppTheme.cardBackground)

            Section(localization.phrase("Export")) {
                Picker(localization.phrase("Document version"), selection: quoteTemplateSelectionBinding) {
                    ForEach(DocumentTemplateStyle.allCases) { style in
                        Text(localization.phrase(style.title)).tag(style)
                    }
                }
                .pickerStyle(.menu)

                Text(localization.phrase(quoteExportTemplateStyle.subtitle))
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.secondaryText)

                Button(localization.text(.exportPDF)) {
                    exportPDF(shouldShare: false)
                }

                Button(localization.phrase("Share PDF")) {
                    exportPDF(shouldShare: true)
                }

                Button(localization.text(.exportDOCX)) {
                    exportDOCX(shouldShare: false)
                }

                Button(localization.phrase("Share DOCX")) {
                    exportDOCX(shouldShare: true)
                }
            }
            .listRowBackground(AppTheme.cardBackground)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.screenBackground.ignoresSafeArea())
        .navigationTitle(quote.quoteNumber)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(localization.phrase("Edit")) {
                    editQuote = quote
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    isPresentingDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .sheet(item: $editQuote) { quote in
            NavigationStack {
                QuoteFormView(quote: quote)
            }
        }
        .sheet(isPresented: $isPresentingSignatureCapture) {
            NavigationStack {
                SignatureCaptureView(title: localization.phrase("Quote Signature"), existingSignature: quote.customerSignature) { draft in
                    try signatureService.upsertSignature(draft, for: quote, in: modelContext)
                }
            }
        }
        .confirmationDialog(localization.phrase("Convert Quote to Invoice"), isPresented: $isPresentingConvertConfirmation, titleVisibility: .visible) {
            Button(localization.phrase("Convert")) {
                convertToInvoice()
            }
            Button(localization.phrase("Cancel"), role: .cancel) { }
        } message: {
            Text(localization.phrase("Create an editable invoice draft from this accepted quote?"))
        }
        .alert(localization.phrase("Quote Conversion"), isPresented: conversionAlertBinding) {
            Button(localization.phrase("OK"), role: .cancel) { }
        } message: {
            Text(conversionMessage ?? "")
        }
        .alert(localization.phrase("Export Complete"), isPresented: exportAlertBinding) {
            Button(localization.phrase("OK"), role: .cancel) { }
        } message: {
            Text(exportMessage ?? "")
        }
        .alert(localization.text(.exportFailed), isPresented: exportErrorAlertBinding) {
            Button(localization.phrase("OK"), role: .cancel) { }
        } message: {
            Text(exportErrorMessage ?? "")
        }
        .alert(localization.phrase("Delete Quote"), isPresented: $isPresentingDeleteConfirmation) {
            Button(localization.phrase("Delete"), role: .destructive) {
                deleteQuote()
            }
            Button(localization.phrase("Cancel"), role: .cancel) { }
        } message: {
            Text(localization.phrase("This quote will be removed permanently."))
        }
        .alert(localization.phrase("Unable to Delete Quote"), isPresented: deleteErrorBinding) {
            Button(localization.phrase("OK"), role: .cancel) { }
        } message: {
            Text(deleteErrorMessage ?? "")
        }
        .sheet(isPresented: shareSheetBinding) {
            if let sharedFile {
                ActivityShareSheet(items: [sharedFile.url])
            }
        }
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(AppTheme.secondaryText)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(AppTheme.primaryText)
        }
    }

    private func currency(_ value: Double) -> String {
        value.formatted(.currency(code: Locale.current.currency?.identifier ?? "EUR"))
    }

    private func convertToInvoice() {
        do {
            let defaultPaymentTermDays = resolvedQuote.client.paymentTermDays > 0 ? resolvedQuote.client.paymentTermDays : 30
            let draft = try conversionUseCase.prepareDraft(from: resolvedQuote, defaultPaymentTermDays: defaultPaymentTermDays)
            appViewModel.openQuoteConversionWorkflow(draft)
        } catch {
            conversionMessage = error.localizedDescription
        }
    }

    private func exportPDF(shouldShare: Bool) {
        do {
            let exportedFile = try QuotePDFExportService(localeIdentifier: exportLocaleIdentifier, templateStyle: quoteExportTemplateStyle).export(
                quote: resolvedQuote,
                companyProfile: resolvedQuote.companyProfile
            )

            if shouldShare {
                sharedFile = exportedFile
            } else {
                exportMessage = localization.savedFile(exportedFile.fileName)
            }
        } catch {
            exportErrorMessage = error.localizedDescription
        }
    }

    private func exportDOCX(shouldShare: Bool) {
        do {
            let exportedFile = try QuoteDOCXExportService(localeIdentifier: exportLocaleIdentifier, templateStyle: quoteExportTemplateStyle).export(
                quote: resolvedQuote,
                companyProfile: resolvedQuote.companyProfile
            )

            if shouldShare {
                sharedFile = exportedFile
            } else {
                exportMessage = localization.savedFile(exportedFile.fileName)
            }
        } catch {
            exportErrorMessage = error.localizedDescription
        }
    }

    private var conversionAlertBinding: Binding<Bool> {
        Binding(
            get: { conversionMessage != nil },
            set: { if !$0 { conversionMessage = nil } }
        )
    }

    private var exportAlertBinding: Binding<Bool> {
        Binding(
            get: { exportMessage != nil },
            set: { if !$0 { exportMessage = nil } }
        )
    }

    private var exportErrorAlertBinding: Binding<Bool> {
        Binding(
            get: { exportErrorMessage != nil },
            set: { if !$0 { exportErrorMessage = nil } }
        )
    }

    private var shareSheetBinding: Binding<Bool> {
        Binding(
            get: { sharedFile != nil },
            set: { if !$0 { sharedFile = nil } }
        )
    }

    private var deleteErrorBinding: Binding<Bool> {
        Binding(
            get: { deleteErrorMessage != nil },
            set: { if !$0 { deleteErrorMessage = nil } }
        )
    }

    private func deleteQuote() {
        do {
            try repository.delete(quote, in: modelContext)
            dismiss()
        } catch {
            deleteErrorMessage = error.localizedDescription
        }
    }

    private var isSignaturesEnabled: Bool {
        workModeService.isModuleEnabled(
            .customerSignatures,
            settings: appSettings.first,
            moduleConfiguration: moduleConfigurations.first
        )
    }

    private var localization: AppLocalization {
        AppLocalization(localeIdentifier: appSettings.first?.preferredLocaleIdentifier)
    }

    private var exportLocaleIdentifier: String {
        appSettings.first?.preferredLocaleIdentifier ?? Locale.current.identifier
    }

    private var quoteExportTemplateStyle: DocumentTemplateStyle {
        selectedQuoteTemplateStyle ?? quoteTemplateStyle
    }

    private var quoteTemplateStyle: DocumentTemplateStyle {
        appSettings.first?.quoteTemplateStyle ?? .premium
    }

    private var quoteTemplateSelectionBinding: Binding<DocumentTemplateStyle> {
        Binding(
            get: { quoteExportTemplateStyle },
            set: { selectedQuoteTemplateStyle = $0 }
        )
    }
}

#Preview {
    NavigationStack {
        let container = DashboardPreviewData.makeContainer()
        let descriptor = FetchDescriptor<Quote>()
        let quote = (try? container.mainContext.fetch(descriptor).first) ?? Quote(quoteNumber: "Q-2026-001", client: Client(name: "Preview"))
        QuoteDetailView(quote: quote)
            .environment(AppViewModel())
            .modelContainer(container)
    }
}
