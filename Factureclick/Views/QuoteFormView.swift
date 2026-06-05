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

    private let quote: Quote?

    @State private var viewModel: QuoteFormViewModel

    init(quote: Quote? = nil) {
        self.quote = quote
        _viewModel = State(initialValue: QuoteFormViewModel(quote: quote))
    }

    var body: some View {
        Form {
            Section("Quote") {
                Picker("Client", selection: selectedClientBinding) {
                    Text("Select client").tag(nil as UUID?)
                    ForEach(clients) { client in
                        Text(client.name).tag(Optional(client.id))
                    }
                }

                DatePicker("Quote date", selection: quoteDateBinding, displayedComponents: .date)
                DatePicker("Expiry date", selection: expiryDateBinding, displayedComponents: .date)

                Picker("Status", selection: statusBinding) {
                    ForEach(QuoteStatus.allCases) { status in
                        Text(status.displayName).tag(status)
                    }
                }
            }

            Section("Lines") {
                ForEach(Array(viewModel.lineDrafts.enumerated()), id: \.element.id) { index, line in
                    VStack(alignment: .leading, spacing: 12) {
                        Menu(line.linkedProductID.flatMap(productName(for:)) ?? "Use product or service") {
                            ForEach(products) { product in
                                Button(product.name) {
                                    viewModel.applyProduct(product, at: index)
                                }
                            }
                        }

                        TextField(
                            "Description",
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
                            numericField(title: "Qty", value: line.quantity) { value in
                                var updated = line
                                updated.quantity = value
                                viewModel.updateLine(updated, at: index)
                            }

                            numericField(title: "Unit price", value: line.unitPrice) { value in
                                var updated = line
                                updated.unitPrice = value
                                viewModel.updateLine(updated, at: index)
                            }

                            numericField(title: "VAT %", value: line.vatRate) { value in
                                var updated = line
                                updated.vatRate = value
                                viewModel.updateLine(updated, at: index)
                            }
                        }

                        Button("Remove line", role: .destructive) {
                            viewModel.removeLine(id: line.id)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Button("Add line") {
                    viewModel.addLine(defaultVATRate: appSettings.first?.defaultVATRate ?? 21)
                }
            }

            Section("Notes") {
                TextField("Notes", text: notesBinding, axis: .vertical)
                    .lineLimit(4, reservesSpace: true)
            }

            Section("Totals") {
                totalRow("Subtotal", value: viewModel.totals.subtotal)
                totalRow("VAT", value: viewModel.totals.vat)
                totalRow("Total", value: viewModel.totals.total)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.screenBackground.ignoresSafeArea())
        .navigationTitle(quote == nil ? "New Quote" : "Edit Quote")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    save()
                }
                .disabled(!viewModel.isValid)
            }
        }
    }

    private func save() {
        try? viewModel.save(
            quote: quote,
            clients: clients,
            products: products,
            existingQuotes: quotes,
            invoicePrefix: appSettings.first?.invoiceNumberPrefix ?? "",
            sequencePadding: appSettings.first?.invoiceNumberSequencePadding ?? 3,
            in: modelContext
        )
        dismiss()
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
}

#Preview {
    NavigationStack {
        QuoteFormView()
            .modelContainer(DashboardPreviewData.makeContainer())
    }
}
