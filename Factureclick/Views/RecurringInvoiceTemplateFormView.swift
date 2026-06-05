//
//  RecurringInvoiceTemplateFormView.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import SwiftData
import SwiftUI

struct RecurringInvoiceTemplateFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Client.name) private var clients: [Client]
    @Query private var appSettings: [AppSettings]
    @Query(sort: \CompanyProfile.createdAt, order: .reverse) private var companyProfiles: [CompanyProfile]

    private let template: RecurringInvoiceTemplate?

    @State private var viewModel: RecurringInvoiceTemplateFormViewModel

    init(template: RecurringInvoiceTemplate? = nil) {
        self.template = template
        _viewModel = State(initialValue: RecurringInvoiceTemplateFormViewModel(template: template))
    }

    var body: some View {
        Form {
            if let activeProfile {
                Section(localization.phrase("Company")) {
                    Text(activeProfile.name)
                        .foregroundStyle(AppTheme.primaryText)
                }
            }

            Section(localization.phrase("Template")) {
                TextField(localization.phrase("Template name"), text: titleBinding)

                Picker(localization.phrase("Client"), selection: clientBinding) {
                    Text(localization.phrase("Select a client")).tag(nil as UUID?)
                    ForEach(clients) { client in
                        Text(client.name).tag(Optional(client.id))
                    }
                }

                Picker(localization.phrase("Frequency"), selection: frequencyBinding) {
                    ForEach(RecurringInvoiceFrequency.allCases) { frequency in
                        Text(localization.phrase(frequency.displayName)).tag(frequency)
                    }
                }

                Toggle(localization.phrase("Template is active"), isOn: isActiveBinding)
            }

            Section(localization.phrase("Schedule")) {
                DatePicker(localization.phrase("Start date"), selection: startDateBinding, displayedComponents: .date)
                Toggle(localization.phrase("Use end date"), isOn: hasEndDateBinding)
                if viewModel.hasEndDate {
                    DatePicker(localization.phrase("End date"), selection: endDateBinding, displayedComponents: .date)
                }
                TextField(localization.phrase("Payment term (days)"), value: paymentTermBinding, format: .number)
                    .keyboardType(.numberPad)
            }

            Section(localization.phrase("Lines")) {
                Button(localization.phrase("Add Line")) {
                    viewModel.addLine()
                }

                if viewModel.lineDrafts.isEmpty {
                    Text(localization.phrase("Add at least one recurring line."))
                        .foregroundStyle(AppTheme.secondaryText)
                } else {
                    ForEach(Array(viewModel.lineDrafts.enumerated()), id: \.element.id) { index, line in
                        recurringLineEditor(index: index, line: line)
                    }
                }
            }

            Section(localization.phrase("Notes")) {
                TextField(localization.phrase("Invoice notes"), text: notesBinding, axis: .vertical)
                    .lineLimit(4, reservesSpace: true)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.screenBackground.ignoresSafeArea())
        .navigationTitle(template == nil ? localization.phrase("New Template") : localization.phrase("Edit Template"))
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
        .onAppear {
            applyDefaultsIfNeeded()
        }
    }

    private func recurringLineEditor(index: Int, line: InvoiceLineDraft) -> some View {
        VStack(alignment: .leading, spacing: 12) {
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

            Button(localization.phrase("Remove Line"), role: .destructive) {
                viewModel.removeLine(id: line.id)
            }
        }
        .padding(.vertical, 4)
    }

    private func numericField(title: String, value: Double, onChange: @escaping (Double) -> Void) -> some View {
        TextField(
            title,
            value: Binding(get: { value }, set: onChange),
            format: .number.precision(.fractionLength(0...2))
        )
        .keyboardType(.decimalPad)
    }

    private func save() {
        guard let selectedClientID = viewModel.selectedClientID,
              let client = clients.first(where: { $0.id == selectedClientID }) else {
            return
        }

        let target = template ?? RecurringInvoiceTemplate(client: client)
        if template != nil {
            let existingLines = target.lines
            target.lines.removeAll()
            for line in existingLines {
                modelContext.delete(line)
            }
        }
        viewModel.apply(to: target, client: client, companyProfile: activeProfile)

        if template == nil {
            modelContext.insert(target)
        }

        try? modelContext.save()
        dismiss()
    }

    private func applyDefaultsIfNeeded() {
        guard template == nil else { return }
        if viewModel.paymentTermDays == 30 {
            viewModel.paymentTermDays = appSettings.first?.defaultPaymentTermDays ?? 30
        }
        if viewModel.lineDrafts.isEmpty {
            viewModel.addLine()
            if let defaultVATRate = appSettings.first?.defaultVATRate {
                viewModel.lineDrafts[0].vatRate = defaultVATRate
            }
        }
    }

    private var titleBinding: Binding<String> { Binding(get: { viewModel.title }, set: { viewModel.title = $0 }) }
    private var clientBinding: Binding<UUID?> { Binding(get: { viewModel.selectedClientID }, set: { viewModel.selectedClientID = $0 }) }
    private var frequencyBinding: Binding<RecurringInvoiceFrequency> { Binding(get: { viewModel.frequency }, set: { viewModel.frequency = $0 }) }
    private var startDateBinding: Binding<Date> { Binding(get: { viewModel.startDate }, set: { viewModel.startDate = $0 }) }
    private var endDateBinding: Binding<Date> { Binding(get: { viewModel.endDate ?? viewModel.startDate }, set: { viewModel.endDate = $0 }) }
    private var hasEndDateBinding: Binding<Bool> { Binding(get: { viewModel.hasEndDate }, set: { viewModel.hasEndDate = $0 }) }
    private var paymentTermBinding: Binding<Int> { Binding(get: { viewModel.paymentTermDays }, set: { viewModel.paymentTermDays = $0 }) }
    private var notesBinding: Binding<String> { Binding(get: { viewModel.notes }, set: { viewModel.notes = $0 }) }
    private var isActiveBinding: Binding<Bool> { Binding(get: { viewModel.isActive }, set: { viewModel.isActive = $0 }) }

    private var activeProfile: CompanyProfile? {
        CompanyProfileSelectionService().activeProfile(from: companyProfiles, settings: appSettings.first)
    }

    private var localization: AppLocalization {
        AppLocalization(localeIdentifier: appSettings.first?.preferredLocaleIdentifier)
    }
}
