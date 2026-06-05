//
//  ClientFormView.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import SwiftData
import SwiftUI

struct ClientFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var appSettings: [AppSettings]
    @Query(sort: \CompanyProfile.createdAt, order: .reverse) private var companyProfiles: [CompanyProfile]

    private let client: Client?
    private let onSave: ((Client) -> Void)?

    @State private var viewModel: ClientFormViewModel
    @State private var hourlyRateText: String
    @State private var hourlyRatePercentageText = ""
    @State private var saveMessage: String?

    init(client: Client? = nil, onSave: ((Client) -> Void)? = nil) {
        self.client = client
        self.onSave = onSave
        let viewModel = ClientFormViewModel(client: client)
        _viewModel = State(initialValue: viewModel)
        _hourlyRateText = State(initialValue: Self.formatDecimal(viewModel.defaultHourlyRate))
    }

    var body: some View {
        Form {
            if let activeProfile {
                Section(localization.phrase("Company")) {
                    Text(activeProfile.name)
                        .foregroundStyle(AppTheme.primaryText)
                }
            }

            Section(localization.phrase("Details")) {
                TextField(localization.phrase("Client name"), text: nameBinding)
                TextField(localization.phrase("Contact person"), text: contactPersonBinding)
            }

            Section(localization.phrase("Contact")) {
                TextField(localization.phrase("Email"), text: emailBinding)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                TextField(localization.phrase("Phone"), text: phoneBinding)
                    .keyboardType(.phonePad)
                TextField(localization.phrase("Address"), text: addressBinding, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
            }

            Section(localization.phrase("Business")) {
                TextField(localization.phrase("Chamber of Commerce number"), text: kvkBinding)
                TextField(localization.phrase("VAT"), text: vatBinding)
                TextField("\(localization.phrase("Payment term")) (\(localization.text(.days)))", value: paymentTermBinding, format: .number)
                    .keyboardType(.numberPad)
                TextField(localization.phrase("Default hourly rate"), text: $hourlyRateText)
                    .keyboardType(.decimalPad)
                hourlyRateAdjustmentControls
            }

            Section(localization.phrase("Notes")) {
                TextField(localization.phrase("Notes about client"), text: notesBinding, axis: .vertical)
                    .lineLimit(4, reservesSpace: true)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.screenBackground.ignoresSafeArea())
        .navigationTitle(client == nil ? localization.phrase("New client") : localization.phrase("Edit client"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(localization.phrase("Cancel")) { dismiss() }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(localization.phrase("Save")) {
                    save()
                }
                .disabled(!canSave)
            }
        }
        .onAppear {
            applyDefaultPaymentTermIfNeeded()
            if hourlyRateText.isEmpty {
                hourlyRateText = Self.formatDecimal(viewModel.defaultHourlyRate)
            }
        }
        .alert(localization.phrase("Client"), isPresented: saveAlertBinding) {
            Button(localization.phrase("OK"), role: .cancel) { }
        } message: {
            Text(saveMessage ?? "")
        }
    }

    private func save() {
        guard let parsedHourlyRate = Self.parseDecimal(hourlyRateText) else {
            saveMessage = localization.phrase("Enter a valid hourly rate.")
            return
        }

        viewModel.defaultHourlyRate = max(0, parsedHourlyRate)
        let target = client ?? Client()
        viewModel.apply(to: target, companyProfile: activeProfile)

        if client == nil {
            modelContext.insert(target)
        }

        do {
            try modelContext.save()
            onSave?(target)
            dismiss()
        } catch {
            saveMessage = error.localizedDescription
        }
    }

    private var hourlyRateAdjustmentControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField(localization.phrase("Percentage increase/decrease"), text: $hourlyRatePercentageText)
                .keyboardType(.decimalPad)

            HStack {
                Button(localization.phrase("Increase")) {
                    applyHourlyRatePercentageAdjustment(multiplierDirection: 1)
                }
                .disabled(!canApplyHourlyRatePercentageAdjustment)

                Button(localization.phrase("Decrease")) {
                    applyHourlyRatePercentageAdjustment(multiplierDirection: -1)
                }
                .disabled(!canApplyHourlyRatePercentageAdjustment)
            }
            .buttonStyle(.bordered)

            if let adjustedHourlyRatePreview {
                Text("\(localization.phrase("Preview")): \(Self.formatDecimal(adjustedHourlyRatePreview))")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }

    private func applyDefaultPaymentTermIfNeeded() {
        guard client == nil,
              viewModel.paymentTermDays == Client().paymentTermDays,
              let defaultPaymentTermDays = appSettings.first?.defaultPaymentTermDays else {
            return
        }

        viewModel.paymentTermDays = defaultPaymentTermDays
    }

    private func applyHourlyRatePercentageAdjustment(multiplierDirection: Double) {
        guard let currentHourlyRate = Self.parseDecimal(hourlyRateText),
              let percentage = Self.parseDecimal(hourlyRatePercentageText) else {
            return
        }

        let multiplier = 1 + ((percentage / 100) * multiplierDirection)
        hourlyRateText = Self.formatDecimal(max(0, currentHourlyRate * multiplier))
    }

    private var canSave: Bool {
        viewModel.isValid && Self.parseDecimal(hourlyRateText) != nil
    }

    private var canApplyHourlyRatePercentageAdjustment: Bool {
        Self.parseDecimal(hourlyRateText) != nil && Self.parseDecimal(hourlyRatePercentageText) != nil
    }

    private var adjustedHourlyRatePreview: Double? {
        guard let currentHourlyRate = Self.parseDecimal(hourlyRateText),
              let percentage = Self.parseDecimal(hourlyRatePercentageText) else {
            return nil
        }

        return max(0, currentHourlyRate * (1 + (percentage / 100)))
    }

    private var activeProfile: CompanyProfile? {
        CompanyProfileSelectionService().activeProfile(from: companyProfiles, settings: appSettings.first)
    }

    private var localization: AppLocalization {
        AppLocalization(localeIdentifier: appSettings.first?.preferredLocaleIdentifier)
    }

    private var nameBinding: Binding<String> { Binding(get: { viewModel.name }, set: { viewModel.name = $0 }) }
    private var contactPersonBinding: Binding<String> { Binding(get: { viewModel.contactPerson }, set: { viewModel.contactPerson = $0 }) }
    private var emailBinding: Binding<String> { Binding(get: { viewModel.email }, set: { viewModel.email = $0 }) }
    private var phoneBinding: Binding<String> { Binding(get: { viewModel.phone }, set: { viewModel.phone = $0 }) }
    private var addressBinding: Binding<String> { Binding(get: { viewModel.address }, set: { viewModel.address = $0 }) }
    private var kvkBinding: Binding<String> { Binding(get: { viewModel.kvkNumber }, set: { viewModel.kvkNumber = $0 }) }
    private var vatBinding: Binding<String> { Binding(get: { viewModel.vatNumber }, set: { viewModel.vatNumber = $0 }) }
    private var paymentTermBinding: Binding<Int> { Binding(get: { viewModel.paymentTermDays }, set: { viewModel.paymentTermDays = $0 }) }
    private var notesBinding: Binding<String> { Binding(get: { viewModel.notes }, set: { viewModel.notes = $0 }) }
    private var saveAlertBinding: Binding<Bool> {
        Binding(
            get: { saveMessage != nil },
            set: { if !$0 { saveMessage = nil } }
        )
    }

    private static func formatDecimal(_ value: Double) -> String {
        AppFormatters.decimalFormatter(maximumFractionDigits: 2).string(from: NSNumber(value: value)) ?? ""
    }

    private static func parseDecimal(_ value: String) -> Double? {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedValue.isEmpty {
            return 0
        }

        let formatter = AppFormatters.decimalFormatter(maximumFractionDigits: 2)
        if let number = formatter.number(from: trimmedValue) {
            return number.doubleValue
        }

        let alternateSeparator = formatter.decimalSeparator == "," ? "." : ","
        let normalizedValue = trimmedValue.replacingOccurrences(of: alternateSeparator, with: formatter.decimalSeparator)
        return formatter.number(from: normalizedValue)?.doubleValue
    }
}

#Preview {
    NavigationStack {
        ClientFormView()
            .modelContainer(DashboardPreviewData.makeContainer())
    }
}
