//
//  ClientDetailView.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import SwiftData
import SwiftUI

struct ClientDetailView: View {
    let client: Client

    @Query private var appSettings: [AppSettings]
    @State private var editClient: Client?

    var body: some View {
        List {
            Section(localization.phrase("Contact")) {
                detailRow(title: localization.phrase("Company"), value: client.name)
                detailRow(title: localization.phrase("Contact person"), value: client.contactPerson)
                detailRow(title: localization.phrase("Email"), value: client.email)
                detailRow(title: localization.phrase("Phone"), value: client.phone)
                detailRow(title: localization.phrase("Address"), value: client.address)
            }
            .listRowBackground(AppTheme.cardBackground)

            Section(localization.phrase("Business")) {
                detailRow(title: "KVK", value: client.kvkNumber)
                detailRow(title: localization.phrase("VAT"), value: client.vatNumber)
                detailRow(title: localization.phrase("Payment term"), value: "\(client.paymentTermDays) \(localization.text(.days))")
                detailRow(title: localization.phrase("Hourly rate"), value: client.defaultHourlyRate.formatted(.currency(code: Locale.current.currency?.identifier ?? "EUR")))
            }
            .listRowBackground(AppTheme.cardBackground)

            if !client.notes.isEmpty {
                Section(localization.phrase("Notes")) {
                    Text(client.notes)
                        .foregroundStyle(AppTheme.primaryText)
                }
                .listRowBackground(AppTheme.cardBackground)
            }

            Section(localization.phrase("Related")) {
                detailRow(title: localization.phrase("Work entries"), value: "\(client.workEntries.count)")
                detailRow(title: localization.phrase("Invoices"), value: "\(client.invoices.count)")
                detailRow(title: localization.phrase("Quotes"), value: "\(client.quotes.count)")
            }
            .listRowBackground(AppTheme.cardBackground)

            Section(localization.phrase("Client history")) {
                detailRow(
                    title: localization.phrase("Total registered hours"),
                    value: client.workEntries.reduce(0) { $0 + $1.hoursWorked }.formatted(.number.precision(.fractionLength(0...2)))
                )
                detailRow(
                    title: localization.phrase("Total invoice revenue"),
                    value: client.invoices.reduce(0) { $0 + $1.totalAmount }.formatted(.currency(code: Locale.current.currency?.identifier ?? "EUR"))
                )
                detailRow(
                    title: localization.phrase("Last registration"),
                    value: client.workEntries.sorted { $0.date > $1.date }.first?.date.formatted(date: .abbreviated, time: .omitted) ?? localization.phrase("None")
                )
                detailRow(
                    title: localization.phrase("Last invoice"),
                    value: client.invoices.sorted { $0.date > $1.date }.first?.invoiceNumber ?? localization.phrase("None")
                )
            }
            .listRowBackground(AppTheme.cardBackground)

            if !client.workEntries.isEmpty {
                Section(localization.phrase("Recent registrations")) {
                    ForEach(client.workEntries.sorted { $0.date > $1.date }.prefix(5), id: \.id) { entry in
                        detailRow(
                            title: entry.date.formatted(date: .abbreviated, time: .omitted),
                            value: "\(entry.hoursWorked.formatted(.number.precision(.fractionLength(0...2)))) h"
                        )
                    }
                }
                .listRowBackground(AppTheme.cardBackground)
            }

            if !client.invoices.isEmpty {
                Section(localization.phrase("Recent invoices")) {
                    ForEach(client.invoices.sorted { $0.date > $1.date }.prefix(5), id: \.id) { invoice in
                        detailRow(
                            title: invoice.invoiceNumber,
                            value: invoice.totalAmount.formatted(.currency(code: Locale.current.currency?.identifier ?? "EUR"))
                        )
                    }
                }
                .listRowBackground(AppTheme.cardBackground)
            }

            if !client.quotes.isEmpty {
                Section(localization.phrase("Recent quotes")) {
                    ForEach(client.quotes.sorted { $0.date > $1.date }.prefix(5), id: \.id) { quote in
                        NavigationLink {
                            QuoteDetailView(quote: quote)
                        } label: {
                            HStack {
                                Text(quote.quoteNumber)
                                Spacer()
                                QuoteStatusChip(status: QuoteRepository().normalizedStatus(for: quote))
                            }
                        }
                    }
                }
                .listRowBackground(AppTheme.cardBackground)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.screenBackground.ignoresSafeArea())
        .navigationTitle(client.name)
        .toolbarBackground(AppTheme.screenBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(localization.phrase("Edit")) {
                    editClient = client
                }
            }
        }
        .sheet(item: $editClient) { client in
            NavigationStack {
                ClientFormView(client: client)
            }
        }
    }

    @ViewBuilder
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(AppTheme.secondaryText)

            Spacer()

            Text(value.isEmpty ? localization.phrase("Not set") : value)
                .multilineTextAlignment(.trailing)
        }
    }

    private var localization: AppLocalization {
        AppLocalization(localeIdentifier: appSettings.first?.preferredLocaleIdentifier)
    }
}
