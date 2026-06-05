//
//  AppSettings.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation
import SwiftData

enum AppAppearancePreference: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            "System"
        case .light:
            "Light"
        case .dark:
            "Dark"
        }
    }
}

enum AppAccentTheme: String, CaseIterable, Identifiable {
    case ocean = "#1F6FE5"
    case forest = "#0F766E"
    case amber = "#B45309"
    case rose = "#BE123C"
    case slate = "#374151"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ocean:
            "Ocean"
        case .forest:
            "Forest"
        case .amber:
            "Amber"
        case .rose:
            "Rose"
        case .slate:
            "Slate"
        }
    }

    var hex: String { rawValue }
}

enum AppIconChoice: String, CaseIterable, Identifiable {
    case primary
    case dark
    case tinted

    var id: String { rawValue }

    var title: String {
        switch self {
        case .primary:
            "Default icon"
        case .dark:
            "Dark icon"
        case .tinted:
            "Tinted icon"
        }
    }

    var subtitle: String {
        switch self {
        case .primary:
            "Uses the regular app icon."
        case .dark:
            "Uses the dark app icon."
        case .tinted:
            "Uses the tinted app icon."
        }
    }

    var alternateIconName: String? {
        switch self {
        case .primary:
            nil
        case .dark:
            "AppIconDark"
        case .tinted:
            "AppIconTinted"
        }
    }
}

enum DocumentTemplateStyle: String, CaseIterable, Codable, Identifiable {
    case classic
    case premium
    case compact
    case bold

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classic:
            "Classic"
        case .premium:
            "Premium"
        case .compact:
            "Compact"
        case .bold:
            "Bold"
        }
    }

    var fileNameComponent: String {
        rawValue
    }

    var subtitle: String {
        switch self {
        case .classic:
            "Rustig, herkenbaar en zakelijk."
        case .premium:
            "Meer contrast, zachte panelen en moderne accenten."
        case .compact:
            "Strakker en compacter voor veel regels."
        case .bold:
            "Sterke kop, donkere balken en opvallende totalen."
        }
    }

    func accentHex(defaultAccent: String?) -> String {
        switch self {
        case .classic:
            defaultAccent ?? "#1F6FE5"
        case .premium:
            "#0F766E"
        case .compact:
            "#374151"
        case .bold:
            "#7C2D12"
        }
    }

    var inkHex: String {
        switch self {
        case .classic, .compact:
            "#111827"
        case .premium:
            "#0F172A"
        case .bold:
            "#1C1917"
        }
    }

    var softAccentHex: String {
        switch self {
        case .classic:
            "#EEF4FF"
        case .premium:
            "#ECFDF5"
        case .compact:
            "#F3F4F6"
        case .bold:
            "#FFF7ED"
        }
    }
}

@Model
final class AppSettings {
    var preferredLocaleIdentifier: String
    var appearancePreferenceRawValue: String
    var workModeRawValue: String
    var invoiceNumberPrefix: String
    var creditInvoiceNumberPrefix: String = "CR"
    var invoiceNumberSequencePadding: Int
    var invoiceTemplateStyleRawValue: String = DocumentTemplateStyle.premium.rawValue
    var quoteTemplateStyleRawValue: String = DocumentTemplateStyle.premium.rawValue
    var defaultInvoiceEmailSubject: String = ""
    var defaultInvoiceEmailBody: String = ""
    var defaultPaymentTermDays: Int
    var defaultVATRate: Double
    var preferredAccentColorHex: String
    var appIconChoiceRawValue: String
    var activeCompanyProfileID: UUID?
    var hasCompletedWorkModeOnboarding: Bool
    var launchesCount: Int
    var createdAt: Date

    init(
        preferredLocaleIdentifier: String = Locale.current.identifier,
        appearancePreference: AppAppearancePreference = .system,
        workMode: WorkMode = .hybrid,
        invoiceNumberPrefix: String = "",
        creditInvoiceNumberPrefix: String = "CR",
        invoiceNumberSequencePadding: Int = 3,
        invoiceTemplateStyle: DocumentTemplateStyle = .premium,
        quoteTemplateStyle: DocumentTemplateStyle = .premium,
        defaultInvoiceEmailSubject: String = "",
        defaultInvoiceEmailBody: String = "",
        defaultPaymentTermDays: Int = 30,
        defaultVATRate: Double = 21,
        preferredAccentColorHex: String = AppAccentTheme.ocean.hex,
        appIconChoice: AppIconChoice = .primary,
        activeCompanyProfileID: UUID? = nil,
        hasCompletedWorkModeOnboarding: Bool = false,
        launchesCount: Int = 0,
        createdAt: Date = .now
    ) {
        self.preferredLocaleIdentifier = preferredLocaleIdentifier
        self.appearancePreferenceRawValue = appearancePreference.rawValue
        self.workModeRawValue = workMode.rawValue
        self.invoiceNumberPrefix = invoiceNumberPrefix
        self.creditInvoiceNumberPrefix = creditInvoiceNumberPrefix
        self.invoiceNumberSequencePadding = invoiceNumberSequencePadding
        self.invoiceTemplateStyleRawValue = invoiceTemplateStyle.rawValue
        self.quoteTemplateStyleRawValue = quoteTemplateStyle.rawValue
        self.defaultInvoiceEmailSubject = defaultInvoiceEmailSubject
        self.defaultInvoiceEmailBody = defaultInvoiceEmailBody
        self.defaultPaymentTermDays = defaultPaymentTermDays
        self.defaultVATRate = defaultVATRate
        self.preferredAccentColorHex = preferredAccentColorHex
        self.appIconChoiceRawValue = appIconChoice.rawValue
        self.activeCompanyProfileID = activeCompanyProfileID
        self.hasCompletedWorkModeOnboarding = hasCompletedWorkModeOnboarding
        self.launchesCount = launchesCount
        self.createdAt = createdAt
    }

    var appearancePreference: AppAppearancePreference {
        get { AppAppearancePreference(rawValue: appearancePreferenceRawValue) ?? .system }
        set { appearancePreferenceRawValue = newValue.rawValue }
    }

    var accentTheme: AppAccentTheme {
        get { AppAccentTheme(rawValue: preferredAccentColorHex) ?? .ocean }
        set { preferredAccentColorHex = newValue.hex }
    }

    var workMode: WorkMode {
        get { WorkMode(rawValue: workModeRawValue) ?? .hybrid }
        set { workModeRawValue = newValue.rawValue }
    }

    var appIconChoice: AppIconChoice {
        get { AppIconChoice(rawValue: appIconChoiceRawValue) ?? .primary }
        set { appIconChoiceRawValue = newValue.rawValue }
    }

    var invoiceTemplateStyle: DocumentTemplateStyle {
        get { DocumentTemplateStyle(rawValue: invoiceTemplateStyleRawValue) ?? .premium }
        set { invoiceTemplateStyleRawValue = newValue.rawValue }
    }

    var quoteTemplateStyle: DocumentTemplateStyle {
        get { DocumentTemplateStyle(rawValue: quoteTemplateStyleRawValue) ?? .premium }
        set { quoteTemplateStyleRawValue = newValue.rawValue }
    }
}
