//
//  WorkModeConfigurationService.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import Foundation
import SwiftData

struct WorkModeConfigurationService {
    func isOnboardingRequired(settings: AppSettings?) -> Bool {
        !(settings?.hasCompletedWorkModeOnboarding ?? false)
    }

    func visibleTabs(
        settings: AppSettings?,
        moduleConfiguration: ModuleVisibilityConfiguration?
    ) -> [AppTab] {
        let mode = settings?.workMode ?? .hybrid
        let baseTabs: [AppTab]

        switch mode {
        case .freelancer:
            baseTabs = [.dashboard, .agenda, .registrations, .invoices, .clients, .products, .settings]
        case .quoteBusiness:
            baseTabs = [.dashboard, .invoices, .clients, .products, .settings]
        case .hybrid:
            baseTabs = [.dashboard, .agenda, .registrations, .invoices, .clients, .products, .settings]
        case .custom:
            baseTabs = [.dashboard, .agenda, .registrations, .invoices, .clients, .products, .settings]
        }

        return baseTabs.filter { tab in
            switch tab {
            case .dashboard, .settings:
                true
            case .agenda:
                isModuleEnabled(.agenda, settings: settings, moduleConfiguration: moduleConfiguration)
            case .registrations:
                isModuleEnabled(.workRegistrations, settings: settings, moduleConfiguration: moduleConfiguration)
                    || isModuleEnabled(.timeTracking, settings: settings, moduleConfiguration: moduleConfiguration)
                    || isModuleEnabled(.mileageTracking, settings: settings, moduleConfiguration: moduleConfiguration)
                    || isModuleEnabled(.receipts, settings: settings, moduleConfiguration: moduleConfiguration)
            case .clients:
                true
            case .products:
                true
            case .invoices:
                isModuleEnabled(.invoices, settings: settings, moduleConfiguration: moduleConfiguration)
                    || isModuleEnabled(.quotes, settings: settings, moduleConfiguration: moduleConfiguration)
                    || isModuleEnabled(.paymentReminders, settings: settings, moduleConfiguration: moduleConfiguration)
                    || isModuleEnabled(.recurringInvoices, settings: settings, moduleConfiguration: moduleConfiguration)
                    || isModuleEnabled(.vatOverview, settings: settings, moduleConfiguration: moduleConfiguration)
            }
        }
    }

    func isModuleEnabled(
        _ module: AppModule,
        settings: AppSettings?,
        moduleConfiguration: ModuleVisibilityConfiguration?
    ) -> Bool {
        let mode = settings?.workMode ?? .hybrid
        let defaults = defaultEnabledModules(for: mode)
        let defaultValue = defaults[module] ?? true
        guard let moduleConfiguration else { return defaultValue }
        return moduleConfiguration.isEnabled(module)
    }

    func apply(
        mode: WorkMode,
        settings: AppSettings,
        moduleConfiguration: ModuleVisibilityConfiguration
    ) {
        settings.workMode = mode
        settings.hasCompletedWorkModeOnboarding = true
        guard mode != .custom else { return }

        let defaults = defaultEnabledModules(for: mode)
        for module in AppModule.allCases {
            moduleConfiguration.setEnabled(defaults[module] ?? true, for: module)
        }
    }

    func ensurePersistedConfiguration(
        settings: AppSettings?,
        moduleConfiguration: ModuleVisibilityConfiguration?,
        in context: ModelContext
    ) throws -> (AppSettings, ModuleVisibilityConfiguration) {
        let resolvedSettings = settings ?? AppSettings()
        if settings == nil {
            context.insert(resolvedSettings)
        }

        let resolvedModules = moduleConfiguration ?? makeConfiguration(for: resolvedSettings.workMode)
        if moduleConfiguration == nil {
            context.insert(resolvedModules)
        }

        try context.save()
        return (resolvedSettings, resolvedModules)
    }

    func makeConfiguration(for mode: WorkMode) -> ModuleVisibilityConfiguration {
        let defaults = defaultEnabledModules(for: mode)
        return ModuleVisibilityConfiguration(
            agendaEnabled: defaults[.agenda] ?? true,
            workRegistrationsEnabled: defaults[.workRegistrations] ?? true,
            timeTrackingEnabled: defaults[.timeTracking] ?? true,
            quotesEnabled: defaults[.quotes] ?? true,
            invoicesEnabled: defaults[.invoices] ?? true,
            mileageTrackingEnabled: defaults[.mileageTracking] ?? true,
            receiptsEnabled: defaults[.receipts] ?? true,
            paymentRemindersEnabled: defaults[.paymentReminders] ?? true,
            recurringInvoicesEnabled: defaults[.recurringInvoices] ?? true,
            customerSignaturesEnabled: defaults[.customerSignatures] ?? true,
            vatOverviewEnabled: defaults[.vatOverview] ?? true,
            annualRevenueSummaryEnabled: defaults[.annualRevenueSummary] ?? true,
            multipleCompanyProfilesEnabled: defaults[.multipleCompanyProfiles] ?? true
        )
    }

    private func defaultEnabledModules(for mode: WorkMode) -> [AppModule: Bool] {
        switch mode {
        case .freelancer:
            [
                .agenda: true,
                .workRegistrations: true,
                .timeTracking: true,
                .quotes: false,
                .invoices: true,
                .mileageTracking: true,
                .receipts: true,
                .paymentReminders: false,
                .recurringInvoices: false,
                .customerSignatures: false,
                .vatOverview: false,
                .annualRevenueSummary: true,
                .multipleCompanyProfiles: true
            ]
        case .quoteBusiness:
            [
                .agenda: false,
                .workRegistrations: false,
                .timeTracking: false,
                .quotes: true,
                .invoices: true,
                .mileageTracking: false,
                .receipts: true,
                .paymentReminders: true,
                .recurringInvoices: true,
                .customerSignatures: true,
                .vatOverview: true,
                .annualRevenueSummary: true,
                .multipleCompanyProfiles: true
            ]
        case .hybrid:
            Dictionary(uniqueKeysWithValues: AppModule.allCases.map { ($0, true) })
        case .custom:
            Dictionary(uniqueKeysWithValues: AppModule.allCases.map { ($0, true) })
        }
    }
}
