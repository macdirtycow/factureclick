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
    @Query private var appSettings: [AppSettings]

    @State private var searchText = ""
    @State private var selectedStatus: QuoteStatus?
    @State private var isPresentingCreateForm = false
    @State private var editQuote: Quote?
    @State private var quotePendingDeletion: Quote?
    @State private var deleteErrorMessage: String?

    private let repository = QuoteRepository()

    var body: some View {
        List {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        FilterChip(title: localization.phrase("All"), isSelected: selectedStatus == nil) {
                            selectedStatus = nil
                        }

                        ForEach(QuoteStatus.allCases) { status in
                            FilterChip(title: localization.phrase(status.displayName), isSelected: selectedStatus == status) {
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
                    Text(localization.phrase("No quotes match the current filters."))
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
                                    Text("\(localization.phrase("Expires")) \(quote.expiryDate.formatted(date: .abbreviated, time: .omitted))")
                                    Text(quote.totalAmount.formatted(.currency(code: Locale.current.currency?.identifier ?? "EUR")))
                                }
                                .font(AppTheme.captionFont)
                                .foregroundStyle(AppTheme.secondaryText)
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(AppTheme.cardBackground)
                        .swipeActions {
                            Button(localization.phrase("Edit")) {
                                editQuote = quote
                            }
                            .tint(AppTheme.accentColor)

                            Button(localization.phrase("Delete"), role: .destructive) {
                                quotePendingDeletion = quote
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.screenBackground.ignoresSafeArea())
        .navigationTitle(localization.phrase("Quotes"))
        .searchable(text: $searchText, prompt: localization.phrase("Search quotes"))
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
        .alert(localization.phrase("Delete Quote"), isPresented: quoteDeleteBinding) {
            Button(localization.phrase("Delete"), role: .destructive) {
                confirmDeleteQuote()
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

    private var localization: AppLocalization {
        AppLocalization(localeIdentifier: appSettings.first?.preferredLocaleIdentifier)
    }

    private var quoteDeleteBinding: Binding<Bool> {
        Binding(
            get: { quotePendingDeletion != nil },
            set: { if !$0 { quotePendingDeletion = nil } }
        )
    }

    private var deleteErrorBinding: Binding<Bool> {
        Binding(
            get: { deleteErrorMessage != nil },
            set: { if !$0 { deleteErrorMessage = nil } }
        )
    }

    private func confirmDeleteQuote() {
        guard let quotePendingDeletion else { return }

        do {
            try repository.delete(quotePendingDeletion, in: modelContext)
            self.quotePendingDeletion = nil
        } catch {
            deleteErrorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        QuoteListView()
            .modelContainer(DashboardPreviewData.makeContainer())
    }
}
