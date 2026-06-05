//
//  QuoteListView.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import SwiftData
import SwiftUI

struct QuoteListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Quote.date, order: .reverse) private var quotes: [Quote]

    @State private var searchText = ""
    @State private var selectedStatus: QuoteStatus?
    @State private var isPresentingCreateForm = false
    @State private var editQuote: Quote?

    private let repository = QuoteRepository()

    var body: some View {
        List {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        FilterChip(title: "All", isSelected: selectedStatus == nil) {
                            selectedStatus = nil
                        }

                        ForEach(QuoteStatus.allCases) { status in
                            FilterChip(title: status.displayName, isSelected: selectedStatus == status) {
                                selectedStatus = status
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listRowBackground(AppTheme.cardBackground)

            Section {
                if filteredQuotes.isEmpty {
                    Text("No quotes match the current filters.")
                        .foregroundStyle(AppTheme.secondaryText)
                } else {
                    ForEach(filteredQuotes) { quote in
                        NavigationLink {
                            QuoteDetailView(quote: quote)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(quote.quoteNumber)
                                        .font(AppTheme.sectionTitleFont)
                                        .foregroundStyle(AppTheme.primaryText)

                                    Spacer()

                                    QuoteStatusChip(status: repository.normalizedStatus(for: quote))
                                }

                                Text(quote.client.name)
                                    .font(AppTheme.bodyFont)
                                    .foregroundStyle(AppTheme.primaryText)

                                HStack(spacing: 12) {
                                    Text(quote.date.formatted(date: .abbreviated, time: .omitted))
                                    Text("Expires \(quote.expiryDate.formatted(date: .abbreviated, time: .omitted))")
                                    Text(quote.totalAmount.formatted(.currency(code: Locale.current.currency?.identifier ?? "EUR")))
                                }
                                .font(AppTheme.captionFont)
                                .foregroundStyle(AppTheme.secondaryText)
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(AppTheme.cardBackground)
                        .swipeActions {
                            Button("Edit") {
                                editQuote = quote
                            }
                            .tint(AppTheme.accentColor)

                            Button("Delete", role: .destructive) {
                                modelContext.delete(quote)
                                try? modelContext.save()
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.screenBackground.ignoresSafeArea())
        .navigationTitle("Quotes")
        .searchable(text: $searchText, prompt: "Search quotes")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPresentingCreateForm = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingCreateForm) {
            NavigationStack {
                QuoteFormView()
            }
        }
        .sheet(item: $editQuote) { quote in
            NavigationStack {
                QuoteFormView(quote: quote)
            }
        }
    }

    private var filteredQuotes: [Quote] {
        quotes.filter { quote in
            let matchesSearch = searchText.isEmpty || [
                quote.quoteNumber,
                quote.client.name,
                quote.notes
            ]
            .joined(separator: " ")
            .localizedCaseInsensitiveContains(searchText)

            let matchesStatus = selectedStatus == nil || repository.normalizedStatus(for: quote) == selectedStatus
            return matchesSearch && matchesStatus
        }
    }
}

#Preview {
    NavigationStack {
        QuoteListView()
            .modelContainer(DashboardPreviewData.makeContainer())
    }
}
