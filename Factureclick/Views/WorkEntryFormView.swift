//
//  WorkEntryFormView.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct WorkEntryFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Client.name) private var clients: [Client]
    @Query(sort: \Product.name) private var products: [Product]
    @Query(sort: \CollaborationRule.partnerName) private var collaborationRules: [CollaborationRule]
    @Query(sort: \CompanyProfile.createdAt, order: .reverse) private var companyProfiles: [CompanyProfile]
    @Query private var appSettings: [AppSettings]

    @State private var viewModel: WorkEntryFormViewModel
    @State private var isImportingAttachment = false
    @State private var isPresentingClientForm = false
    @State private var attachmentImportError: String?
    @State private var saveErrorMessage: String?

    init(selectedDate: Date) {
        _viewModel = State(initialValue: WorkEntryFormViewModel(selectedDate: selectedDate))
    }

    var body: some View {
        Form {
            if let activeProfile {
                Section(localization.phrase("Bedrijf")) {
                    Text(activeProfile.name)
                        .foregroundStyle(AppTheme.primaryText)
                }
            }

            Section(localization.phrase("Planning")) {
                DatePicker(localization.phrase("Datum"), selection: selectedDateBinding, displayedComponents: [.date, .hourAndMinute])
            }

            Section(localization.phrase("Klant")) {
                Picker(localization.phrase("Klant"), selection: selectedClientBinding) {
                    Text(localization.phrase("Kies een klant")).tag(nil as UUID?)

                    ForEach(clients) { client in
                        Text(client.name).tag(Optional(client.id))
                    }
                }

                Button(localization.phrase("Nieuwe klant")) {
                    isPresentingClientForm = true
                }
            }

            Section(localization.phrase("Werkdetails")) {
                Toggle(localization.phrase("Factureren op basis van uren"), isOn: billingByHoursBinding)

                if viewModel.billsByHours {
                    TextField(
                        localization.phrase("Gewerkte uren"),
                        value: hoursWorkedBinding,
                        format: .number.precision(.fractionLength(0...2))
                    )
                    .keyboardType(.decimalPad)

                    Text(localization.phrase("Deze registratie gebruikt het uurtarief van de klant en laat het product leeg."))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.secondaryText)
                } else {
                    Picker(localization.phrase("Product"), selection: selectedProductBinding) {
                        Text(localization.phrase("Geen product")).tag(nil as UUID?)

                        ForEach(products) { product in
                            Text(product.name).tag(Optional(product.id))
                        }
                    }

                    if selectedProduct?.unitType != .hour {
                        TextField(
                            localization.phrase("Aantal"),
                            value: quantityBinding,
                            format: .number.precision(.fractionLength(0...2))
                        )
                        .keyboardType(.decimalPad)

                        Text(localization.phrase("Dit product wordt op aantal gefactureerd. Uren zijn hier niet nodig."))
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.secondaryText)
                    } else if selectedProduct != nil {
                        TextField(
                            localization.phrase("Gewerkte uren"),
                            value: hoursWorkedBinding,
                            format: .number.precision(.fractionLength(0...2))
                        )
                        .keyboardType(.decimalPad)
                    }
                }
            }

            Section(localization.phrase("Notities")) {
                TextField(localization.phrase("Voeg context toe aan deze registratie"), text: notesBinding, axis: .vertical)
                    .lineLimit(4, reservesSpace: true)
            }

            Section(localization.phrase("Bijlagen")) {
                Button(localization.phrase("Bijlage toevoegen")) {
                    isImportingAttachment = true
                }

                if !viewModel.pendingAttachmentURLs.isEmpty {
                    ForEach(viewModel.pendingAttachmentURLs, id: \.path) { url in
                        HStack {
                            Image(systemName: "paperclip")
                                .foregroundStyle(AppTheme.accentColor)
                            Text(url.lastPathComponent)
                                .font(AppTheme.bodyFont)
                            Spacer()
                            Button(role: .destructive) {
                                viewModel.pendingAttachmentURLs.removeAll { $0 == url }
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                    }
                }
            }

            Section(localization.phrase("Facturatie")) {
                Text(localization.phrase("Je kunt uren nu registreren zonder meteen een factuur te maken. Zet dit alleen aan als je deze uren later wilt kunnen factureren."))
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.secondaryText)

                Toggle(localization.phrase("Later kunnen factureren"), isOn: includeInInvoiceBinding)

                Picker(localization.phrase("Samenwerking"), selection: selectedCollaborationRuleBinding) {
                    Text(localization.phrase("Gebruik standaard van klant")).tag(nil as UUID?)

                    ForEach(availableCollaborationRules) { rule in
                        let label = rule.client == nil ? rule.partnerName : "\(rule.partnerName) · \(rule.client?.name ?? "")"
                        Text(label).tag(Optional(rule.id))
                    }
                }

                Toggle(localization.phrase("Gebruik aangepast uurtarief"), isOn: useCustomRateBinding)

                if viewModel.useCustomHourlyRate {
                    TextField(
                        localization.phrase("Uurtarief"),
                        value: customHourlyRateBinding,
                        format: .number.precision(.fractionLength(0...2))
                    )
                    .keyboardType(.decimalPad)
                }

                if !viewModel.includeInInvoice {
                    Text(localization.phrase("Deze uren worden alleen opgeslagen als registratie. Je kunt ze later alsnog opnemen in een factuur vanuit Registraties of Facturen."))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.secondaryText)
                } else {
                    Text(localization.phrase("Deze uren blijven eerst als registratie staan en worden later beschikbaar voor facturatie."))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.screenBackground.ignoresSafeArea())
        .navigationTitle(localization.phrase("Nieuwe registratie"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isPresentingClientForm) {
            NavigationStack {
                ClientFormView { client in
                    viewModel.selectedClientID = client.id
                }
            }
        }
        .fileImporter(isPresented: $isImportingAttachment, allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
            switch result {
            case .success(let urls):
                viewModel.pendingAttachmentURLs.append(contentsOf: urls)
            case .failure(let error):
                attachmentImportError = error.localizedDescription
            }
        }
        .alert(localization.phrase("Importeren mislukt"), isPresented: attachmentErrorBinding) {
            Button(localization.phrase("OK"), role: .cancel) { }
        } message: {
            Text(attachmentImportError ?? "")
        }
        .alert(localization.phrase("Opslaan mislukt"), isPresented: saveErrorBinding) {
            Button(localization.phrase("OK"), role: .cancel) { }
        } message: {
            Text(saveErrorMessage ?? "")
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(localization.phrase("Annuleer")) {
                    dismiss()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(localization.phrase("Bewaar")) {
                    do {
                        try viewModel.save(
                            in: modelContext,
                            clients: clients,
                            products: products,
                            collaborationRules: collaborationRules,
                            activeCompanyProfile: activeProfile
                        )
                        dismiss()
                    } catch {
                        saveErrorMessage = error.localizedDescription
                    }
                }
                .disabled(!viewModel.canSave(with: products))
            }
        }
    }

    private var selectedDateBinding: Binding<Date> {
        Binding(
            get: { viewModel.selectedDate },
            set: { viewModel.selectedDate = $0 }
        )
    }

    private var selectedClientBinding: Binding<UUID?> {
        Binding(
            get: { viewModel.selectedClientID },
            set: { viewModel.selectedClientID = $0 }
        )
    }

    private var selectedProductBinding: Binding<UUID?> {
        Binding(
            get: { viewModel.selectedProductID },
            set: { viewModel.setSelectedProductID($0, products: products) }
        )
    }

    private var billingByHoursBinding: Binding<Bool> {
        Binding(
            get: { viewModel.billsByHours },
            set: { viewModel.setBillingByHours($0) }
        )
    }

    private var hoursWorkedBinding: Binding<Double> {
        Binding(
            get: { viewModel.hoursWorked },
            set: { viewModel.hoursWorked = $0 }
        )
    }

    private var quantityBinding: Binding<Double> {
        Binding(
            get: { viewModel.quantity },
            set: { viewModel.quantity = $0 }
        )
    }

    private var notesBinding: Binding<String> {
        Binding(
            get: { viewModel.notes },
            set: { viewModel.notes = $0 }
        )
    }

    private var includeInInvoiceBinding: Binding<Bool> {
        Binding(
            get: { viewModel.includeInInvoice },
            set: { viewModel.includeInInvoice = $0 }
        )
    }

    private var selectedCollaborationRuleBinding: Binding<UUID?> {
        Binding(
            get: { viewModel.selectedCollaborationRuleID },
            set: { viewModel.selectedCollaborationRuleID = $0 }
        )
    }

    private var useCustomRateBinding: Binding<Bool> {
        Binding(
            get: { viewModel.useCustomHourlyRate },
            set: { viewModel.useCustomHourlyRate = $0 }
        )
    }

    private var customHourlyRateBinding: Binding<Double> {
        Binding(
            get: { viewModel.customHourlyRate },
            set: { viewModel.customHourlyRate = $0 }
        )
    }

    private var availableCollaborationRules: [CollaborationRule] {
        collaborationRules.filter { rule in
            rule.client == nil || rule.client?.id == viewModel.selectedClientID
        }
    }

    private var attachmentErrorBinding: Binding<Bool> {
        Binding(
            get: { attachmentImportError != nil },
            set: { if !$0 { attachmentImportError = nil } }
        )
    }

    private var saveErrorBinding: Binding<Bool> {
        Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )
    }

    private var activeProfile: CompanyProfile? {
        CompanyProfileSelectionService().activeProfile(from: companyProfiles, settings: appSettings.first)
    }

    private var selectedProduct: Product? {
        viewModel.selectedProduct(from: products)
    }

    private var localization: AppLocalization {
        AppLocalization(localeIdentifier: appSettings.first?.preferredLocaleIdentifier)
    }
}

#Preview {
    NavigationStack {
        WorkEntryFormView(selectedDate: .now)
            .modelContainer(DashboardPreviewData.makeContainer())
    }
}
