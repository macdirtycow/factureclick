//
//  QuoteFormView.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import SwiftData
import SwiftUI

struct QuoteFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Client.name) private var clients: [Client]
    @Query(sort: \Product.name) private var products: [Product]
    @Query(sort: \Quote.date, order: .reverse) private var quotes: [Quote]
    @Query private var appSettings: [AppSettings]
    @Query(sort: \CompanyProfile.createdAt, order: .reverse) private var companyProfiles: [CompanyProfile]

    private let quote: Quote?

    @State private var viewModel: QuoteFormViewModel
    @State private var saveErrorMessage: String?

    init(quote: Quote? = nil) {
        self.quote = quote
        _viewModel = State(initialValue: QuoteFormViewModel(quote: quote))
    }

    var body: some View {
        Form {
            if let activeProfile {
                Section(localization.phrase("Company")) {
                    Text(activeProfile.name)
                        .foregroundStyle(AppTheme.primaryText)
                }
            }

            Section(localization.phrase("Quote")) {
                Picker(localization.phrase("Client"), selection: selectedClientBinding) {
                    Text(localization.phrase("Select client")).tag(nil as UUID?)
                    ForEach(clients) { client in
                        Text(client.name).tag(Optional(client.id))
                    }
                }

                DatePicker(localization.phrase("Quote date"), selection: quoteDateBinding, displayedComponents: .date)
                DatePicker(localization.phrase("Expiry date"), selection: expiryDateBinding, displayedComponents: .date)

                Picker(localization.phrase("Status"), selection: statusBinding) {
                    ForEach(QuoteStatus.allCases) { status in
                        Text(localization.phrase(status.displayName)).tag(status)
                    }
                }
            }

            Section(localization.phrase("Lines")) {
                ForEach(Array(viewModel.lineDrafts.enumerated()), id: \.element.id) { index, line in
                    VStack(alignment: .leading, spacing: 12) {
                        Menu(line.linkedProductID.flatMap(productName(for:)) ?? localization.phrase("Use product or service")) {
                            ForEach(products) { product in
                                Button(product.name) {
                                    viewModel.applyProduct(product, at: index)
                                }
                            }
                        }

                        TextField(
                            localization.phrase("Description"),
                            text: Binding(
                                get: { viewModel.lineDrafts[index].description },
                                set: {
                                    var updated = line
                                    updated.description = $0
                                    viewModel.updateLine(updated, at: index)
                                }
                            )
                        )

                        HStack(spacing: 12) {
                            numericField(title: localization.phrase("Qty"), value: line.quantity) { value in
                                var updated = line
                                updated.quantity = value
                                viewModel.updateLine(updated, at: index)
                            }

                            numericField(title: localization.phrase("Unit price"), value: line.unitPrice) { value in
                                var updated = line
                                updated.unitPrice = value
                                viewModel.updateLine(updated, at: index)
                            }

                            numericField(title: localization.phrase("VAT %"), value: line.vatRate) { value in
                                var updated = line
                                updated.vatRate = value
                                viewModel.updateLine(updated, at: index)
                            }
                        }

                        Button(localization.phrase("Remove line"), role: .destructive) {
                            viewModel.removeLine(id: line.id)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Button(localization.phrase("Add line")) {
                    viewModel.addLine(defaultVATRate: appSettings.first?.defaultVATRate ?? 21)
                }
            }

            Section(localization.phrase("Notes")) {
                TextField(localization.phrase("Notes"), text: notesBinding, axis: .vertical)
                    .lineLimit(4, reservesSpace: true)
            }

            Section(localization.text(.totals)) {
                totalRow(localization.text(.subtotal), value: viewModel.totals.subtotal)
                totalRow(localization.text(.vat), value: viewModel.totals.vat)
                totalRow(localization.text(.total), value: viewModel.totals.total)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.screenBackground.ignoresSafeArea())
        .navigationTitle(quote == nil ? localization.phrase("New Quote") : localization.phrase("Edit Quote"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(localization.phrase("Cancel")) { dismiss() }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(localization.phrase("Save")) {
                    save()
                }
                .disabled(!viewModel.isValid)
            }
        }
        .alert(localization.phrase("Unable to Save Quote"), isPresented: saveErrorBinding) {
            Button(localization.phrase("OK"), role: .cancel) { }
        } message: {
            Text(saveErrorMessage ?? "")
        }
    }

    private func save() {
        do {
            try viewModel.save(
                quote: quote,
                clients: clients,
                products: products,
                existingQuotes: quotes,
                invoicePrefix: appSettings.first?.invoiceNumberPrefix ?? "",
                sequencePadding: appSettings.first?.invoiceNumberSequencePadding ?? 3,
                activeCompanyProfile: activeProfile,
                in: modelContext
            )
            dismiss()
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    private func numericField(title: String, value: Double, onChange: @escaping (Double) -> Void) -> some View {
        TextField(
            title,
            value: Binding(get: { value }, set: onChange),
            format: .number.precision(.fractionLength(0...2))
        )
        .keyboardType(.decimalPad)
    }

    private func totalRow(_ title: String, value: Double) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(AppTheme.secondaryText)
            Spacer()
            Text(value.formatted(.currency(code: Locale.current.currency?.identifier ?? "EUR")))
                .foregroundStyle(AppTheme.primaryText)
        }
    }

    private func productName(for id: UUID) -> String? {
        products.first(where: { $0.id == id })?.name
    }

    private var selectedClientBinding: Binding<UUID?> {
        Binding(get: { viewModel.selectedClientID }, set: { viewModel.selectedClientID = $0 })
    }

    private var quoteDateBinding: Binding<Date> {
        Binding(get: { viewModel.quoteDate }, set: { viewModel.quoteDate = $0 })
    }

    private var expiryDateBinding: Binding<Date> {
        Binding(get: { viewModel.expiryDate }, set: { viewModel.expiryDate = $0 })
    }

    private var statusBinding: Binding<QuoteStatus> {
        Binding(get: { viewModel.status }, set: { viewModel.status = $0 })
    }

    private var notesBinding: Binding<String> {
        Binding(get: { viewModel.notes }, set: { viewModel.notes = $0 })
    }

    private var activeProfile: CompanyProfile? {
        CompanyProfileSelectionService().activeProfile(from: companyProfiles, settings: appSettings.first)
    }

    private var saveErrorBinding: Binding<Bool> {
        Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )
    }

    private var localization: AppLocalization {
        AppLocalization(localeIdentifier: appSettings.first?.preferredLocaleIdentifier)
    }
}

#Preview {
    NavigationStack {
        QuoteFormView()
            .modelContainer(DashboardPreviewData.makeContainer())
    }
}
