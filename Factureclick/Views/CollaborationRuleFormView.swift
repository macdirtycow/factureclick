//
//  CollaborationRuleFormView.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import SwiftData
import SwiftUI

struct CollaborationRuleFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Client.name) private var clients: [Client]
    @Query private var appSettings: [AppSettings]

    let rule: CollaborationRule?
    @State private var viewModel: CollaborationRuleFormViewModel

    init(rule: CollaborationRule? = nil) {
        self.rule = rule
        _viewModel = State(initialValue: CollaborationRuleFormViewModel(rule: rule))
    }

    var body: some View {
        Form {
            Section(localization.phrase("Scope")) {
                Picker(localization.phrase("Client"), selection: selectedClientBinding) {
                    Text(localization.phrase("General rule")).tag(nil as UUID?)

                    ForEach(clients) { client in
                        Text(client.name).tag(Optional(client.id))
                    }
                }
            }

            Section(localization.phrase("Split")) {
                TextField(localization.phrase("Partner name"), text: partnerNameBinding)
                TextField(localization.phrase("Percentage"), value: percentageBinding, format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.decimalPad)
            }

            Section(localization.phrase("Notes")) {
                TextField(localization.phrase("Optional notes"), text: notesBinding, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.screenBackground.ignoresSafeArea())
        .navigationTitle(rule == nil ? localization.phrase("New Collaboration Rule") : localization.phrase("Edit Collaboration Rule"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(localization.phrase("Cancel")) {
                    dismiss()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(localization.phrase("Save")) {
                    try? viewModel.save(rule: rule, clients: clients, in: modelContext)
                    dismiss()
                }
                .disabled(!viewModel.canSave)
            }
        }
    }

    private var selectedClientBinding: Binding<UUID?> {
        Binding(
            get: { viewModel.selectedClientID },
            set: { viewModel.selectedClientID = $0 }
        )
    }

    private var partnerNameBinding: Binding<String> {
        Binding(
            get: { viewModel.partnerName },
            set: { viewModel.partnerName = $0 }
        )
    }

    private var percentageBinding: Binding<Double> {
        Binding(
            get: { viewModel.percentage },
            set: { viewModel.percentage = $0 }
        )
    }

    private var notesBinding: Binding<String> {
        Binding(
            get: { viewModel.notes },
            set: { viewModel.notes = $0 }
        )
    }

    private var localization: AppLocalization {
        AppLocalization(localeIdentifier: appSettings.first?.preferredLocaleIdentifier)
    }
}

#Preview {
    NavigationStack {
        CollaborationRuleFormView()
            .modelContainer(DashboardPreviewData.makeContainer())
    }
}
