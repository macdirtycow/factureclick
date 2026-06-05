//
//  AppSettingsSectionView.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import SwiftData
import SwiftUI

struct AppSettingsSectionView: View {
    @Environment(\.modelContext) private var modelContext

    @Query private var appSettings: [AppSettings]

    @State private var viewModel = AppSettingsViewModel()
    @State private var saveMessage: String?

    let onBusinessDataTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            heroCard
            localizationAndAppearanceCard
            invoiceNumberingCard
            billingDefaultsCard
            shortcutsCard
            saveCard
        }
        .task {
            syncFromSettings()
        }
        .alert("Settings", isPresented: saveAlertBinding) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveMessage ?? "")
        }
    }

    private var heroCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("App settings")
                    .font(AppTheme.titleFont)
                    .foregroundStyle(AppTheme.primaryText)

                Text("Personalize language, appearance, invoicing defaults, and shortcuts from one place.")
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }

    private var localizationAndAppearanceCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 18) {
                Text("Language and appearance")
                    .font(AppTheme.sectionTitleFont)
                    .foregroundStyle(AppTheme.primaryText)

                Picker("Language", selection: localeBinding) {
                    ForEach(SupportedLocale.allCases) { locale in
                        Text(locale.title).tag(locale)
                    }
                }
                .pickerStyle(.menu)

                Toggle("Follow system appearance", isOn: usesSystemAppearanceBinding)
                    .tint(viewModel.selectedAccentTheme.color)

                if !viewModel.usesSystemAppearance {
                    Picker("Color mode", selection: selectedColorSchemeBinding) {
                        Text(AppAppearancePreference.light.title).tag(AppAppearancePreference.light)
                        Text(AppAppearancePreference.dark.title).tag(AppAppearancePreference.dark)
                    }
                    .pickerStyle(.segmented)
                }

                Picker("Accent theme", selection: accentThemeBinding) {
                    ForEach(AppAccentTheme.allCases) { theme in
                        Label {
                            Text(theme.title)
                        } icon: {
                            Circle()
                                .fill(theme.color)
                                .frame(width: 10, height: 10)
                        }
                        .tag(theme)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }

    private var invoiceNumberingCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 18) {
                Text("Invoice numbering")
                    .font(AppTheme.sectionTitleFont)
                    .foregroundStyle(AppTheme.primaryText)

                TextField("Invoice prefix", text: invoicePrefixBinding)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.characters)

                Stepper(value: numberingPaddingBinding, in: 2...6) {
                    HStack {
                        Text("Sequence digits")
                            .font(AppTheme.bodyFont)
                            .foregroundStyle(AppTheme.primaryText)
                        Spacer()
                        Text("\(viewModel.invoiceNumberSequencePadding)")
                            .font(AppTheme.bodyFont.weight(.semibold))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }

                previewRow(title: "Preview", value: viewModel.invoiceNumberPreview)
            }
        }
    }

    private var billingDefaultsCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 18) {
                Text("Billing defaults")
                    .font(AppTheme.sectionTitleFont)
                    .foregroundStyle(AppTheme.primaryText)

                Stepper(value: paymentTermBinding, in: 1...120) {
                    HStack {
                        Text("Default payment term")
                            .font(AppTheme.bodyFont)
                            .foregroundStyle(AppTheme.primaryText)
                        Spacer()
                        Text("\(viewModel.defaultPaymentTermDays) days")
                            .font(AppTheme.bodyFont.weight(.semibold))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }

                TextField("Default VAT (%)", value: defaultVATBinding, format: .number.precision(.fractionLength(0...2)))
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)

                previewRow(
                    title: "Applied to",
                    value: "New manual invoice lines and general work invoice lines"
                )
            }
        }
    }

    private var shortcutsCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Shortcuts")
                    .font(AppTheme.sectionTitleFont)
                    .foregroundStyle(AppTheme.primaryText)

                Text("Business profile data stays separate from app settings, but you can jump there directly.")
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.secondaryText)

                Button("Open Business Data") {
                    onBusinessDataTap()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var saveCard: some View {
        SectionCard {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Save changes")
                        .font(AppTheme.sectionTitleFont)
                        .foregroundStyle(AppTheme.primaryText)

                    Text("Changes are stored in SwiftData and update the app immediately after saving.")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Spacer()

                Button("Save Settings") {
                    saveSettings()
                }
                .buttonStyle(.borderedProminent)
                .tint(viewModel.selectedAccentTheme.color)
            }
        }
    }

    private func previewRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.secondaryText)

            Text(value)
                .font(AppTheme.bodyFont.weight(.semibold))
                .foregroundStyle(AppTheme.primaryText)
        }
    }

    private func syncFromSettings() {
        viewModel = AppSettingsViewModel(settings: appSettings.first)
    }

    private func saveSettings() {
        do {
            try viewModel.save(existingSettings: appSettings.first, in: modelContext)
            saveMessage = "Settings saved."
        } catch {
            saveMessage = error.localizedDescription
        }
    }

    private var localeBinding: Binding<SupportedLocale> {
        Binding(get: { viewModel.selectedLocale }, set: { viewModel.selectedLocale = $0 })
    }

    private var usesSystemAppearanceBinding: Binding<Bool> {
        Binding(get: { viewModel.usesSystemAppearance }, set: { viewModel.usesSystemAppearance = $0 })
    }

    private var selectedColorSchemeBinding: Binding<AppAppearancePreference> {
        Binding(get: { viewModel.selectedColorScheme }, set: { viewModel.selectedColorScheme = $0 })
    }

    private var accentThemeBinding: Binding<AppAccentTheme> {
        Binding(get: { viewModel.selectedAccentTheme }, set: { viewModel.selectedAccentTheme = $0 })
    }

    private var invoicePrefixBinding: Binding<String> {
        Binding(get: { viewModel.invoiceNumberPrefix }, set: { viewModel.invoiceNumberPrefix = $0 })
    }

    private var numberingPaddingBinding: Binding<Int> {
        Binding(get: { viewModel.invoiceNumberSequencePadding }, set: { viewModel.invoiceNumberSequencePadding = $0 })
    }

    private var paymentTermBinding: Binding<Int> {
        Binding(get: { viewModel.defaultPaymentTermDays }, set: { viewModel.defaultPaymentTermDays = $0 })
    }

    private var defaultVATBinding: Binding<Double> {
        Binding(get: { viewModel.defaultVATRate }, set: { viewModel.defaultVATRate = $0 })
    }

    private var saveAlertBinding: Binding<Bool> {
        Binding(
            get: { saveMessage != nil },
            set: { if !$0 { saveMessage = nil } }
        )
    }
}

#Preview {
    ScrollView {
        AppSettingsSectionView(onBusinessDataTap: {})
            .modelContainer(DashboardPreviewData.makeContainer())
            .padding()
    }
}

private extension AppAccentTheme {
    var color: Color {
        AppTheme.color(hex: hex)
    }
}
