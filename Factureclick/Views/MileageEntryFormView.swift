//
//  MileageEntryFormView.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import SwiftData
import SwiftUI

struct MileageEntryFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Client.name) private var clients: [Client]
    @Query(sort: \Invoice.date, order: .reverse) private var invoices: [Invoice]
    @Query private var appSettings: [AppSettings]

    private let entry: MileageEntry?

    @State private var viewModel: MileageFormViewModel

    private let invoiceRepository = InvoiceRepository()

    init(entry: MileageEntry? = nil) {
        self.entry = entry
        _viewModel = State(initialValue: MileageFormViewModel(entry: entry))
    }

    var body: some View {
        Form {
            Section(localization.phrase("Trip")) {
                DatePicker(localization.phrase("Date"), selection: dateBinding, displayedComponents: [.date, .hourAndMinute])
                Picker(localization.phrase("Client"), selection: clientBinding) {
                    Text(localization.phrase("No client")).tag(nil as UUID?)
                    ForEach(clients) { client in
                        Text(client.name).tag(Optional(client.id))
                    }
                }
                TextField(localization.phrase("Start location"), text: startLocationBinding)
                TextField(localization.phrase("End location"), text: endLocationBinding)
                TextField(localization.phrase("Purpose"), text: purposeBinding, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
            }

            Section(localization.phrase("Distance")) {
                TextField(localization.phrase("Kilometers"), value: kilometersBinding, format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.decimalPad)
                TextField(localization.phrase("Rate per kilometer"), value: rateBinding, format: .number.precision(.fractionLength(0...3)))
                    .keyboardType(.decimalPad)
                HStack {
                    Text(localization.phrase("Total travel cost"))
                        .foregroundStyle(AppTheme.secondaryText)
                    Spacer()
                    Text(viewModel.totalTravelCost.formatted(.currency(code: Locale.current.currency?.identifier ?? "EUR")))
                        .foregroundStyle(AppTheme.primaryText)
                }
            }

            Section(localization.phrase("Billing")) {
                Toggle(localization.phrase("Include on invoice"), isOn: includeOnInvoiceBinding)
                Picker(localization.phrase("Linked invoice"), selection: invoiceBinding) {
                    Text(localization.phrase("No linked invoice")).tag(nil as UUID?)
                    ForEach(availableInvoices) { invoice in
                        let status = localization.phrase(invoiceRepository.normalizedStatus(for: invoice).displayName)
                        Text("\(invoice.invoiceNumber) · \(invoice.client.name) · \(status)").tag(Optional(invoice.id))
                    }
                }
                .disabled(!viewModel.includeOnInvoice || availableInvoices.isEmpty)

                if !viewModel.includeOnInvoice {
                    Text(localization.phrase("Travel costs can be linked to an invoice later."))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.screenBackground.ignoresSafeArea())
        .navigationTitle(entry == nil ? localization.phrase("New Mileage") : localization.phrase("Edit Mileage"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(localization.phrase("Cancel")) { dismiss() }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(localization.phrase("Save")) {
                    save()
                }
                .disabled(!viewModel.canSave)
            }
        }
        .onAppear {
            applyDefaultRateIfNeeded()
        }
        .onChange(of: viewModel.includeOnInvoice) { _, isIncluded in
            if !isIncluded {
                viewModel.selectedInvoiceID = nil
            }
        }
        .onChange(of: viewModel.selectedClientID) { _, selectedClientID in
            guard let selectedInvoiceID = viewModel.selectedInvoiceID else { return }
            guard let invoice = invoices.first(where: { $0.id == selectedInvoiceID }) else {
                viewModel.selectedInvoiceID = nil
                return
            }

            if let selectedClientID, invoice.client.id != selectedClientID {
                viewModel.selectedInvoiceID = nil
            }
        }
    }

    private func save() {
        let target = entry ?? MileageEntry()
        viewModel.apply(to: target, clients: clients, invoices: invoices)

        if entry == nil {
            modelContext.insert(target)
        }

        try? modelContext.save()
        dismiss()
    }

    private func applyDefaultRateIfNeeded() {
        guard entry == nil, viewModel.reimbursementRatePerKilometer == 0 else { return }
        _ = appSettings.first
        viewModel.reimbursementRatePerKilometer = 0.23
    }

    private var availableInvoices: [Invoice] {
        guard viewModel.includeOnInvoice else { return [] }

        let currentlyLinkedInvoiceID = entry?.invoice?.id ?? viewModel.selectedInvoiceID

        return invoices
            .filter { invoice in
                if invoice.isCreditInvoice {
                    return false
                }

                let normalizedStatus = invoiceRepository.normalizedStatus(for: invoice)
                if normalizedStatus == .paid, invoice.id != currentlyLinkedInvoiceID {
                    return false
                }

                if let selectedClientID = viewModel.selectedClientID {
                    return invoice.client.id == selectedClientID
                }

                return true
            }
            .sorted { lhs, rhs in
                let lhsStatus = invoiceRepository.normalizedStatus(for: lhs)
                let rhsStatus = invoiceRepository.normalizedStatus(for: rhs)

                if lhsStatus == .draft, rhsStatus != .draft {
                    return true
                }

                if rhsStatus == .draft, lhsStatus != .draft {
                    return false
                }

                if lhs.date != rhs.date {
                    return lhs.date > rhs.date
                }

                return lhs.createdAt > rhs.createdAt
            }
    }

    private var dateBinding: Binding<Date> { Binding(get: { viewModel.date }, set: { viewModel.date = $0 }) }
    private var clientBinding: Binding<UUID?> { Binding(get: { viewModel.selectedClientID }, set: { viewModel.selectedClientID = $0 }) }
    private var startLocationBinding: Binding<String> { Binding(get: { viewModel.startLocation }, set: { viewModel.startLocation = $0 }) }
    private var endLocationBinding: Binding<String> { Binding(get: { viewModel.endLocation }, set: { viewModel.endLocation = $0 }) }
    private var purposeBinding: Binding<String> { Binding(get: { viewModel.purpose }, set: { viewModel.purpose = $0 }) }
    private var kilometersBinding: Binding<Double> { Binding(get: { viewModel.numberOfKilometers }, set: { viewModel.numberOfKilometers = $0 }) }
    private var rateBinding: Binding<Double> { Binding(get: { viewModel.reimbursementRatePerKilometer }, set: { viewModel.reimbursementRatePerKilometer = $0 }) }
    private var includeOnInvoiceBinding: Binding<Bool> { Binding(get: { viewModel.includeOnInvoice }, set: { viewModel.includeOnInvoice = $0 }) }
    private var invoiceBinding: Binding<UUID?> { Binding(get: { viewModel.selectedInvoiceID }, set: { viewModel.selectedInvoiceID = $0 }) }

    private var localization: AppLocalization {
        AppLocalization(localeIdentifier: appSettings.first?.preferredLocaleIdentifier)
    }
}
