//
//  QuoteDetailView.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import SwiftData
import SwiftUI

struct QuoteDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let quote: Quote

    @State private var editQuote: Quote?

    private let repository = QuoteRepository()

    var body: some View {
        List {
            Section("Overview") {
                detailRow("Quote number", quote.quoteNumber)
                detailRow("Client", quote.client.name)
                detailRow("Quote date", quote.date.formatted(date: .abbreviated, time: .omitted))
                detailRow("Expiry date", quote.expiryDate.formatted(date: .abbreviated, time: .omitted))
                HStack {
                    Text("Status")
                        .foregroundStyle(AppTheme.secondaryText)
                    Spacer()
                    QuoteStatusChip(status: repository.normalizedStatus(for: quote))
                }
            }
            .listRowBackground(AppTheme.cardBackground)

            Section("Lines") {
                ForEach(quote.lines) { line in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(line.description)
                            .font(AppTheme.bodyFont.weight(.semibold))
                            .foregroundStyle(AppTheme.primaryText)

                        Text("\(line.quantity.formatted(.number.precision(.fractionLength(0...2)))) × \(line.unitPrice.formatted(.currency(code: Locale.current.currency?.identifier ?? "EUR")))")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.secondaryText)

                        Text("VAT \(line.vatRate.formatted(.number.precision(.fractionLength(0...2))))%")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
            }
            .listRowBackground(AppTheme.cardBackground)

            Section("Totals") {
                detailRow("Subtotal", currency(quote.subtotalAmount))
                detailRow("VAT", currency(quote.vatAmount))
                detailRow("Total", currency(quote.totalAmount))
            }
            .listRowBackground(AppTheme.cardBackground)

            if !quote.notes.isEmpty {
                Section("Notes") {
                    Text(quote.notes)
                        .foregroundStyle(AppTheme.primaryText)
                }
                .listRowBackground(AppTheme.cardBackground)
            }

            Section("Status") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(QuoteStatus.allCases) { status in
                            FilterChip(title: status.displayName, isSelected: repository.normalizedStatus(for: quote) == status) {
                                quote.status = status
                                try? modelContext.save()
                            }
                        }
                    }
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
                Button("Edit") {
                    editQuote = quote
                }
            }
        }
        .sheet(item: $editQuote) { quote in
            NavigationStack {
                QuoteFormView(quote: quote)
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
}

#Preview {
    NavigationStack {
        let container = DashboardPreviewData.makeContainer()
        let descriptor = FetchDescriptor<Quote>()
        let quote = (try? container.mainContext.fetch(descriptor).first) ?? Quote(quoteNumber: "Q-2026-001", client: Client(name: "Preview"))
        QuoteDetailView(quote: quote)
            .modelContainer(container)
    }
}
