//
//  AppSettingsViewModel.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation
import Observation
import SwiftData

@Observable
final class AppSettingsViewModel {
    var selectedLocale: SupportedLocale
    var usesSystemAppearance: Bool
    var selectedColorScheme: AppAppearancePreference
    var selectedAccentTheme: AppAccentTheme
    var preferredAccentColorHex: String
    var selectedAppIcon: AppIconChoice
    var invoiceNumberPrefix: String
    var creditInvoiceNumberPrefix: String
    var invoiceNumberSequencePadding: Int
    var invoiceTemplateStyle: DocumentTemplateStyle
    var quoteTemplateStyle: DocumentTemplateStyle
    var defaultInvoiceEmailSubject: String
    var defaultInvoiceEmailBody: String
    var defaultPaymentTermDays: Int
    var defaultVATRate: Double

    init(settings: AppSettings? = nil) {
        selectedLocale = SupportedLocale.resolving(settings?.preferredLocaleIdentifier ?? Locale.current.identifier)
        let appearancePreference = settings?.appearancePreference ?? .system
        usesSystemAppearance = appearancePreference == .system
        selectedColorScheme = appearancePreference == .system ? .light : appearancePreference
        let accentColorHex = settings?.preferredAccentColorHex ?? AppAccentTheme.ocean.hex
        preferredAccentColorHex = accentColorHex
        selectedAccentTheme = AppAccentTheme(rawValue: accentColorHex) ?? .ocean
        selectedAppIcon = settings?.appIconChoice ?? .primary
        invoiceNumberPrefix = settings?.invoiceNumberPrefix ?? ""
        creditInvoiceNumberPrefix = settings?.creditInvoiceNumberPrefix ?? "CR"
        invoiceNumberSequencePadding = settings?.invoiceNumberSequencePadding ?? 3
        invoiceTemplateStyle = settings?.invoiceTemplateStyle ?? .premium
        quoteTemplateStyle = settings?.quoteTemplateStyle ?? .premium
        defaultInvoiceEmailSubject = settings?.defaultInvoiceEmailSubject ?? ""
        defaultInvoiceEmailBody = settings?.defaultInvoiceEmailBody ?? ""
        defaultPaymentTermDays = settings?.defaultPaymentTermDays ?? 30
        defaultVATRate = settings?.defaultVATRate ?? 21
    }

    func apply(to settings: AppSettings) {
        settings.preferredLocaleIdentifier = selectedLocale.rawValue
        settings.appearancePreference = usesSystemAppearance ? .system : selectedColorScheme
        settings.invoiceNumberPrefix = invoiceNumberPrefix.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.creditInvoiceNumberPrefix = normalizedCreditInvoiceNumberPrefix
        settings.invoiceNumberSequencePadding = min(max(invoiceNumberSequencePadding, 2), 6)
        settings.invoiceTemplateStyle = invoiceTemplateStyle
        settings.quoteTemplateStyle = quoteTemplateStyle
        settings.defaultInvoiceEmailSubject = defaultInvoiceEmailSubject.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.defaultInvoiceEmailBody = defaultInvoiceEmailBody.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.defaultPaymentTermDays = max(1, defaultPaymentTermDays)
        settings.defaultVATRate = max(0, defaultVATRate)
        settings.preferredAccentColorHex = normalizedPreferredAccentColorHex
        settings.appIconChoice = selectedAppIcon
        UserDefaults.standard.set(normalizedPreferredAccentColorHex, forKey: AppTheme.accentColorDefaultsKey)
    }

    func save(existingSettings: AppSettings?, in context: ModelContext) throws {
        let target = existingSettings ?? AppSettings()
        apply(to: target)

        if existingSettings == nil {
            context.insert(target)
        }

        try context.save()
    }

    var resolvedAppearancePreference: AppAppearancePreference {
        usesSystemAppearance ? .system : selectedColorScheme
    }

    var invoiceNumberPreview: String {
        let year = Calendar.current.component(.year, from: .now)
        let sequence = String(format: "%0\(min(max(invoiceNumberSequencePadding, 2), 6))d", 1)
        let normalizedPrefix = invoiceNumberPrefix.trimmingCharacters(in: .whitespacesAndNewlines)
        let value = "\(year)-\(sequence)"
        return normalizedPrefix.isEmpty ? value : "\(normalizedPrefix)-\(value)"
    }

    var creditInvoiceNumberPreview: String {
        let year = Calendar.current.component(.year, from: .now)
        let sequence = String(format: "%0\(min(max(invoiceNumberSequencePadding, 2), 6))d", 1)
        return "\(normalizedCreditInvoiceNumberPrefix)-\(year)-\(sequence)"
    }

    func selectAccentTheme(_ theme: AppAccentTheme) {
        selectedAccentTheme = theme
        preferredAccentColorHex = theme.hex
        UserDefaults.standard.set(theme.hex, forKey: AppTheme.accentColorDefaultsKey)
    }

    func useLogoAccent(from companyProfile: CompanyProfile?) -> Bool {
        guard let logoData = companyProfile?.logoData,
              let logoAccentHex = LogoThemeColorExtractor.accentHex(from: logoData) else {
            return false
        }

        preferredAccentColorHex = logoAccentHex
        selectedAccentTheme = AppAccentTheme(rawValue: logoAccentHex) ?? selectedAccentTheme
        UserDefaults.standard.set(logoAccentHex, forKey: AppTheme.accentColorDefaultsKey)
        return true
    }

    private var normalizedCreditInvoiceNumberPrefix: String {
        let trimmed = creditInvoiceNumberPrefix.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "CR" : trimmed
    }

    private var normalizedPreferredAccentColorHex: String {
        let trimmed = preferredAccentColorHex.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? AppAccentTheme.ocean.hex : trimmed
    }
}
