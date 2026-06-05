//
//  AppSettingsSectionView.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import SwiftData
import SwiftUI
import UIKit

struct AppSettingsSectionView: View {
    @Environment(\.modelContext) private var modelContext

    @Query private var appSettings: [AppSettings]
    @Query(sort: \CompanyProfile.createdAt, order: .reverse) private var companyProfiles: [CompanyProfile]

    @State private var viewModel = AppSettingsViewModel()
    @State private var saveMessage: String?

    let onBusinessDataTap: () -> Void

    private let companyProfileSelectionService = CompanyProfileSelectionService()

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            heroCard
            groupHeader(
                title: localization.phrase("Brand & company"),
                subtitle: localization.phrase("Company profile and logo settings.")
            )
            brandProfileCard
            groupHeader(
                title: localization.phrase("Appearance"),
                subtitle: localization.phrase("Language, theme and app icon.")
            )
            localizationAndAppearanceCard
            appIconCard
            groupHeader(
                title: localization.phrase("Documents"),
                subtitle: localization.phrase("Numbering and document styles.")
            )
            invoiceNumberingCard
            documentTemplatesCard
            groupHeader(
                title: localization.phrase("Defaults"),
                subtitle: localization.phrase("Billing and email defaults.")
            )
            billingDefaultsCard
            emailDefaultsCard
            groupHeader(
                title: localization.phrase("Actions"),
                subtitle: localization.phrase("Shortcuts and save.")
            )
            shortcutsCard
            saveCard
        }
        .task {
            syncFromSettings()
        }
        .onChange(of: settingsRefreshKey) { _, _ in
            syncFromSettings()
        }
        .alert(localization.text(.settingsAlertTitle), isPresented: saveAlertBinding) {
            Button(localization.phrase("OK"), role: .cancel) { }
        } message: {
            Text(saveMessage ?? "")
        }
    }

    private var heroCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                AppLogoView(
                    logoData: activeCompanyProfile?.logoData,
                    title: activeCompanyProfile?.name.isEmpty == false ? activeCompanyProfile?.name ?? AppBrand.displayName : AppBrand.displayName,
                    subtitle: activeCompanyProfile?.ownerName.isEmpty == false ? activeCompanyProfile?.ownerName ?? localization.text(.invoicesAndFieldWork) : localization.text(.invoicesAndFieldWork),
                    size: 54,
                    accentColor: resolvedAccentColor
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text(localization.text(.settingsHeroTitle))
                        .font(AppTheme.titleFont)
                        .foregroundStyle(AppTheme.primaryText)

                    Text(localization.text(.settingsHeroSubtitle))
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
    }

    private var brandProfileCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 18) {
                Text(localization.text(.brandProfileTitle))
                    .font(AppTheme.sectionTitleFont)
                    .foregroundStyle(AppTheme.primaryText)

                HStack(alignment: .top, spacing: 16) {
                    AppLogoView(
                        logoData: activeCompanyProfile?.logoData,
                        title: activeCompanyProfile?.name.isEmpty == false ? activeCompanyProfile?.name ?? localization.text(.yourCompany) : localization.text(.yourCompany),
                        subtitle: activeCompanyProfile?.email.isEmpty == false ? activeCompanyProfile?.email ?? localization.text(.addCompanyProfileHint) : localization.text(.addCompanyProfileHint),
                        size: 64,
                        accentColor: resolvedAccentColor
                    )

                    Spacer(minLength: 0)
                }

                if let activeCompanyProfile {
                    VStack(alignment: .leading, spacing: 10) {
                        previewRow(title: localization.text(.activeCompany), value: activeCompanyProfile.name)

                        if !activeCompanyProfile.ownerName.isEmpty {
                            previewRow(title: localization.text(.owner), value: activeCompanyProfile.ownerName)
                        }

                        if !activeCompanyProfile.email.isEmpty {
                            previewRow(title: localization.text(.email), value: activeCompanyProfile.email)
                        }
                    }
                } else {
                    Text(localization.text(.noActiveCompanyProfile))
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Button(activeCompanyProfile == nil ? localization.text(.addCompanyProfile) : localization.text(.manageCompanyProfile)) {
                    onBusinessDataTap()
                }
                .buttonStyle(.borderedProminent)
                .tint(resolvedAccentColor)

                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        applyLogoTheme()
                    } label: {
                        Label(localization.phrase("Use logo color as app theme"), systemImage: "eyedropper")
                    }
                    .buttonStyle(.bordered)
                    .tint(resolvedAccentColor)
                    .disabled(activeCompanyProfile?.logoData == nil)

                    Text(logoThemeHelpText)
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
    }

    private var localizationAndAppearanceCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 18) {
                Text(localization.text(.languageAppearance))
                    .font(AppTheme.sectionTitleFont)
                    .foregroundStyle(AppTheme.primaryText)

                Picker(localization.text(.language), selection: localeBinding) {
                    ForEach(SupportedLocale.allCases) { locale in
                        Text(locale.title).tag(locale)
                    }
                }
                .pickerStyle(.menu)

                Toggle(localization.text(.followSystemAppearance), isOn: usesSystemAppearanceBinding)
                    .tint(resolvedAccentColor)

                if !viewModel.usesSystemAppearance {
                    Picker(localization.text(.colorMode), selection: selectedColorSchemeBinding) {
                        Text(AppAppearancePreference.light.title).tag(AppAppearancePreference.light)
                        Text(AppAppearancePreference.dark.title).tag(AppAppearancePreference.dark)
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(localization.text(.appTheme))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.secondaryText)

                    ForEach(AppAccentTheme.allCases) { theme in
                        Button {
                            applyAccentTheme(theme)
                        } label: {
                            HStack(spacing: 14) {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [theme.color, theme.color.opacity(0.65)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 54, height: 54)
                                    .overlay {
                                        Image(systemName: theme.systemImage)
                                            .foregroundStyle(.white)
                                    }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(localization.phrase(theme.title))
                                        .font(AppTheme.bodyFont.weight(.semibold))
                                        .foregroundStyle(AppTheme.primaryText)
                                    Text(localization.phrase(theme.previewDescription))
                                        .font(AppTheme.captionFont)
                                        .foregroundStyle(AppTheme.secondaryText)
                                }

                                Spacer()

                                Image(systemName: viewModel.preferredAccentColorHex == theme.hex ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(viewModel.preferredAccentColorHex == theme.hex ? theme.color : AppTheme.secondaryText)
                            }
                            .padding(14)
                            .background(themeRowBackground(for: theme))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }

                    if AppAccentTheme(rawValue: viewModel.preferredAccentColorHex) == nil {
                        HStack(spacing: 14) {
                            Circle()
                                .fill(resolvedAccentColor)
                                .frame(width: 24, height: 24)
                            Text(localization.phrase("Logo theme"))
                                .font(AppTheme.bodyFont.weight(.semibold))
                                .foregroundStyle(AppTheme.primaryText)
                            Spacer()
                            Text(viewModel.preferredAccentColorHex)
                                .font(AppTheme.captionFont)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        .padding(14)
                        .background(resolvedAccentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
            }
        }
    }

    private var appIconCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 18) {
                Text(localization.phrase("App icon"))
                    .font(AppTheme.sectionTitleFont)
                    .foregroundStyle(AppTheme.primaryText)

                Text(localization.phrase("Choose the icon shown on the Home Screen."))
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.secondaryText)

                ForEach(AppIconChoice.allCases) { choice in
                    Button {
                        applyAppIcon(choice)
                    } label: {
                        HStack(spacing: 14) {
                            appIconPreview(for: choice)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(localization.phrase(choice.title))
                                    .font(AppTheme.bodyFont.weight(.semibold))
                                    .foregroundStyle(AppTheme.primaryText)
                                Text(localization.phrase(choice.subtitle))
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }

                            Spacer()

                            Image(systemName: viewModel.selectedAppIcon == choice ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(viewModel.selectedAppIcon == choice ? resolvedAccentColor : AppTheme.secondaryText)
                        }
                        .padding(14)
                        .background(appIconRowBackground(for: choice))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var invoiceNumberingCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 18) {
                Text(localization.text(.invoiceNumbering))
                    .font(AppTheme.sectionTitleFont)
                    .foregroundStyle(AppTheme.primaryText)

                TextField(localization.text(.invoicePrefix), text: invoicePrefixBinding)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.characters)

                TextField(localization.phrase("Credit invoice prefix"), text: creditInvoicePrefixBinding)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.characters)

                Stepper(value: numberingPaddingBinding, in: 2...6) {
                    HStack {
                        Text(localization.text(.sequenceDigits))
                            .font(AppTheme.bodyFont)
                            .foregroundStyle(AppTheme.primaryText)
                        Spacer()
                        Text("\(viewModel.invoiceNumberSequencePadding)")
                            .font(AppTheme.bodyFont.weight(.semibold))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }

                previewRow(title: localization.text(.preview), value: viewModel.invoiceNumberPreview)
                previewRow(title: localization.phrase("Credit preview"), value: viewModel.creditInvoiceNumberPreview)
            }
        }
    }

    private var billingDefaultsCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 18) {
                Text(localization.text(.billingDefaults))
                    .font(AppTheme.sectionTitleFont)
                    .foregroundStyle(AppTheme.primaryText)

                Stepper(value: paymentTermBinding, in: 1...120) {
                    HStack {
                        Text(localization.text(.defaultPaymentTerm))
                            .font(AppTheme.bodyFont)
                            .foregroundStyle(AppTheme.primaryText)
                        Spacer()
                        Text("\(viewModel.defaultPaymentTermDays) \(localization.text(.days))")
                            .font(AppTheme.bodyFont.weight(.semibold))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }

                TextField(localization.text(.defaultVAT), value: defaultVATBinding, format: .number.precision(.fractionLength(0...2)))
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)

                previewRow(
                    title: localization.text(.appliedTo),
                    value: localization.text(.appliedToInvoiceLines)
                )
            }
        }
    }

    private var emailDefaultsCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 18) {
                Text(localization.phrase("Default invoice email"))
                    .font(AppTheme.sectionTitleFont)
                    .foregroundStyle(AppTheme.primaryText)

                TextField(localization.phrase("Default subject"), text: defaultInvoiceEmailSubjectBinding)
                    .textFieldStyle(.roundedBorder)

                TextField(localization.phrase("Default message"), text: defaultInvoiceEmailBodyBinding, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(8, reservesSpace: true)

                Text(localization.phrase("Available placeholders: {client}, {contact}, {invoiceNumber}, {invoiceDate}, {dueDate}, {amount}, {company}, {owner}"))
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }

    private var documentTemplatesCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 18) {
                Text(localization.phrase("Document versions"))
                    .font(AppTheme.sectionTitleFont)
                    .foregroundStyle(AppTheme.primaryText)

                templatePicker(
                    title: localization.phrase("Invoice version"),
                    selection: invoiceTemplateBinding
                )

                templateSample(style: viewModel.invoiceTemplateStyle, title: localization.phrase("Invoice sample"), documentNumber: viewModel.invoiceNumberPreview)

                Divider()

                templatePicker(
                    title: localization.phrase("Quote version"),
                    selection: quoteTemplateBinding
                )

                templateSample(style: viewModel.quoteTemplateStyle, title: localization.phrase("Quote sample"), documentNumber: "Q-\(Calendar.current.component(.year, from: .now))-001")
            }
        }
    }

    private func templatePicker(title: String, selection: Binding<DocumentTemplateStyle>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.secondaryText)

            Picker(title, selection: selection) {
                ForEach(DocumentTemplateStyle.allCases) { style in
                    Text(localization.phrase(style.title)).tag(style)
                }
            }
            .pickerStyle(.segmented)

            Text(localization.phrase(selection.wrappedValue.subtitle))
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.secondaryText)
        }
    }

    private func templateSample(style: DocumentTemplateStyle, title: String, documentNumber: String) -> some View {
        let accent = AppTheme.color(hex: style.accentHex(defaultAccent: viewModel.preferredAccentColorHex))
        let softAccent = AppTheme.color(hex: style.softAccentHex)
        let ink = AppTheme.color(hex: style.inkHex)

        return VStack(alignment: .leading, spacing: style == .compact ? 8 : 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(style == .bold ? AppTheme.titleFont : AppTheme.bodyFont.weight(.semibold))
                        .foregroundStyle(style == .bold ? .white : ink)
                    Text(documentNumber)
                        .font(AppTheme.captionFont.weight(.semibold))
                        .foregroundStyle(style == .bold ? .white.opacity(0.85) : AppTheme.secondaryText)
                }

                Spacer()

                Text("€ 1.250,00")
                    .font(AppTheme.bodyFont.weight(.bold))
                    .foregroundStyle(style == .bold ? .white : accent)
            }
            .padding(14)
            .background(style == .bold ? accent : softAccent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            HStack(spacing: 8) {
                sampleLine(width: 0.48, color: ink.opacity(0.78))
                sampleLine(width: 0.18, color: accent)
                sampleLine(width: 0.24, color: AppTheme.secondaryText.opacity(0.55))
            }

            HStack(spacing: 8) {
                sampleLine(width: 0.34, color: AppTheme.secondaryText.opacity(0.45))
                sampleLine(width: 0.22, color: AppTheme.secondaryText.opacity(0.35))
                sampleLine(width: 0.34, color: accent.opacity(0.65))
            }
        }
        .padding(14)
        .background(AppTheme.elevatedBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func sampleLine(width: CGFloat, color: Color) -> some View {
        GeometryReader { proxy in
            Capsule()
                .fill(color)
                .frame(width: proxy.size.width * width, height: 8)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 8)
    }

    private var shortcutsCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(localization.text(.shortcuts))
                    .font(AppTheme.sectionTitleFont)
                    .foregroundStyle(AppTheme.primaryText)

                Text(localization.text(.shortcutsDescription))
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.secondaryText)

                Button(localization.text(.addOrManageCompanyProfile)) {
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
                    Text(localization.text(.saveChanges))
                        .font(AppTheme.sectionTitleFont)
                        .foregroundStyle(AppTheme.primaryText)

                    Text(localization.text(.saveChangesDescription))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Spacer()

                Button(localization.text(.saveSettings)) {
                    saveSettings()
                }
                .buttonStyle(.borderedProminent)
                .tint(resolvedAccentColor)
            }
        }
    }

    private func groupHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTheme.titleFont)
                .foregroundStyle(AppTheme.primaryText)
            Text(subtitle)
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .padding(.horizontal, 4)
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

    private var settingsRefreshKey: String {
        guard let settings = appSettings.first else {
            return "empty"
        }

        return [
            settings.createdAt.timeIntervalSince1970.formatted(),
            settings.preferredLocaleIdentifier,
            settings.appearancePreferenceRawValue,
            settings.invoiceNumberPrefix,
            settings.creditInvoiceNumberPrefix,
            String(settings.invoiceNumberSequencePadding),
            settings.invoiceTemplateStyleRawValue,
            settings.quoteTemplateStyleRawValue,
            settings.defaultInvoiceEmailSubject,
            settings.defaultInvoiceEmailBody,
            String(settings.defaultPaymentTermDays),
            String(settings.defaultVATRate),
            settings.preferredAccentColorHex,
            settings.appIconChoiceRawValue
        ].joined(separator: "|")
    }

    private func saveSettings() {
        do {
            try viewModel.save(existingSettings: appSettings.first, in: modelContext)
            saveMessage = localization.text(.settingsSaved)
        } catch {
            saveMessage = error.localizedDescription
        }
    }

    private var localeBinding: Binding<SupportedLocale> {
        Binding(get: { viewModel.selectedLocale }, set: { viewModel.selectedLocale = $0 })
    }

    private var activeCompanyProfile: CompanyProfile? {
        companyProfileSelectionService.activeProfile(from: companyProfiles, settings: appSettings.first)
    }

    private var logoThemeHelpText: String {
        guard let activeCompanyProfile else {
            return localization.phrase("Choose an active company profile with a logo to use this.")
        }

        if activeCompanyProfile.logoData == nil {
            return localization.phrase("Add a logo to the active company profile to use this.")
        }

        return localization.phrase("Uses the dominant logo color as the app accent theme.")
    }

    private var localization: AppLocalization {
        AppLocalization(localeIdentifier: viewModel.selectedLocale.rawValue)
    }

    private var resolvedAccentColor: Color {
        AppTheme.color(hex: viewModel.preferredAccentColorHex)
    }

    private func applyLogoTheme() {
        guard viewModel.useLogoAccent(from: activeCompanyProfile) else {
            saveMessage = localization.phrase("Could not find a usable color in this logo.")
            return
        }

        do {
            try viewModel.save(existingSettings: appSettings.first, in: modelContext)
            saveMessage = localization.phrase("Logo color applied.")
        } catch {
            saveMessage = error.localizedDescription
        }
    }

    private func applyAccentTheme(_ theme: AppAccentTheme) {
        viewModel.selectAccentTheme(theme)

        do {
            try viewModel.save(existingSettings: appSettings.first, in: modelContext)
            saveMessage = localization.phrase("Theme applied.")
        } catch {
            saveMessage = error.localizedDescription
        }
    }

    private func applyAppIcon(_ choice: AppIconChoice) {
        guard UIApplication.shared.supportsAlternateIcons else {
            saveMessage = localization.phrase("This device does not support alternate app icons.")
            return
        }

        UIApplication.shared.setAlternateIconName(choice.alternateIconName) { error in
            Task { @MainActor in
                if let error {
                    saveMessage = [
                        localization.phrase("Unable to change app icon."),
                        error.localizedDescription
                    ].joined(separator: "\n")
                    return
                }

                viewModel.selectedAppIcon = choice

                do {
                    try viewModel.save(existingSettings: appSettings.first, in: modelContext)
                    saveMessage = localization.phrase("App icon updated.")
                } catch {
                    saveMessage = error.localizedDescription
                }
            }
        }
    }

    private func themeRowBackground(for theme: AppAccentTheme) -> some ShapeStyle {
        if viewModel.preferredAccentColorHex == theme.hex {
            return AnyShapeStyle(theme.color.opacity(0.12))
        }

        return AnyShapeStyle(AppTheme.elevatedBackground)
    }

    private func appIconRowBackground(for choice: AppIconChoice) -> some ShapeStyle {
        if viewModel.selectedAppIcon == choice {
            return AnyShapeStyle(resolvedAccentColor.opacity(0.12))
        }

        return AnyShapeStyle(AppTheme.elevatedBackground)
    }

    private func appIconPreview(for choice: AppIconChoice) -> some View {
        let background: Color
        let foreground: Color

        switch choice {
        case .primary:
            background = Color(red: 0.10, green: 0.44, blue: 0.90)
            foreground = .white
        case .dark:
            background = Color(red: 0.14, green: 0.16, blue: 0.20)
            foreground = .white
        case .tinted:
            background = resolvedAccentColor.opacity(0.18)
            foreground = resolvedAccentColor
        }

        return RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(background)
            .frame(width: 58, height: 58)
            .overlay {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(foreground)
            }
    }

    private var usesSystemAppearanceBinding: Binding<Bool> {
        Binding(get: { viewModel.usesSystemAppearance }, set: { viewModel.usesSystemAppearance = $0 })
    }

    private var selectedColorSchemeBinding: Binding<AppAppearancePreference> {
        Binding(get: { viewModel.selectedColorScheme }, set: { viewModel.selectedColorScheme = $0 })
    }

    private var accentThemeBinding: Binding<AppAccentTheme> {
        Binding(get: { viewModel.selectedAccentTheme }, set: { viewModel.selectAccentTheme($0) })
    }

    private var invoicePrefixBinding: Binding<String> {
        Binding(get: { viewModel.invoiceNumberPrefix }, set: { viewModel.invoiceNumberPrefix = $0 })
    }

    private var creditInvoicePrefixBinding: Binding<String> {
        Binding(get: { viewModel.creditInvoiceNumberPrefix }, set: { viewModel.creditInvoiceNumberPrefix = $0 })
    }

    private var numberingPaddingBinding: Binding<Int> {
        Binding(get: { viewModel.invoiceNumberSequencePadding }, set: { viewModel.invoiceNumberSequencePadding = $0 })
    }

    private var invoiceTemplateBinding: Binding<DocumentTemplateStyle> {
        Binding(get: { viewModel.invoiceTemplateStyle }, set: { viewModel.invoiceTemplateStyle = $0 })
    }

    private var quoteTemplateBinding: Binding<DocumentTemplateStyle> {
        Binding(get: { viewModel.quoteTemplateStyle }, set: { viewModel.quoteTemplateStyle = $0 })
    }

    private var defaultInvoiceEmailSubjectBinding: Binding<String> {
        Binding(get: { viewModel.defaultInvoiceEmailSubject }, set: { viewModel.defaultInvoiceEmailSubject = $0 })
    }

    private var defaultInvoiceEmailBodyBinding: Binding<String> {
        Binding(get: { viewModel.defaultInvoiceEmailBody }, set: { viewModel.defaultInvoiceEmailBody = $0 })
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

    var systemImage: String {
        switch self {
        case .ocean:
            "water.waves"
        case .forest:
            "leaf.fill"
        case .amber:
            "sun.max.fill"
        case .rose:
            "sparkles"
        case .slate:
            "moon.stars.fill"
        }
    }

    var previewDescription: String {
        switch self {
        case .ocean:
            "Clean and professional blue for general business use."
        case .forest:
            "Calm green for a grounded and trustworthy look."
        case .amber:
            "Warm gold for a bold and energetic identity."
        case .rose:
            "Expressive red for a more premium branded feel."
        case .slate:
            "Neutral graphite for a restrained, minimal theme."
        }
    }
}
