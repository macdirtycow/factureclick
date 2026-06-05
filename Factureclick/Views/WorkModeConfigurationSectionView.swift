//
//  WorkModeConfigurationSectionView.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import SwiftData
import SwiftUI

struct WorkModeConfigurationSectionView: View {
    @Environment(\.modelContext) private var modelContext

    @Query private var appSettings: [AppSettings]
    @Query private var moduleConfigurations: [ModuleVisibilityConfiguration]

    @State private var saveMessage: String?

    private let service = WorkModeConfigurationService()

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            workModeCard
        }
        .alert(localization.phrase("Work Mode"), isPresented: saveAlertBinding) {
            Button(localization.phrase("OK"), role: .cancel) { }
        } message: {
            Text(saveMessage ?? "")
        }
    }

    private var workModeCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(localization.phrase("Work Mode"))
                    .font(AppTheme.sectionTitleFont)
                    .foregroundStyle(AppTheme.primaryText)

                Text(localization.phrase("Choose which workflow Factureclick should prioritize across navigation, dashboard, and business tools."))
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.secondaryText)

                ForEach(WorkMode.allCases) { mode in
                    Button {
                        applyMode(mode)
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(localization.phrase(mode.title))
                                    .font(AppTheme.bodyFont.weight(.semibold))
                                    .foregroundStyle(AppTheme.primaryText)
                                Text(localization.phrase(mode.summary))
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }

                            Spacer()

                            Image(systemName: currentSettings?.workMode == mode ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(currentSettings?.workMode == mode ? AppTheme.accentColor : AppTheme.secondaryText)
                        }
                    }
                    .buttonStyle(.plain)

                    if mode == .custom, currentSettings?.workMode == .custom {
                        customModulesPanel
                            .padding(.top, 4)
                    }

                    if mode != WorkMode.allCases.last {
                        Divider()
                    }
                }
            }
        }
    }

    private var customModulesPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(localization.phrase("Enabled Modules"))
                .font(AppTheme.bodyFont.weight(.semibold))
                .foregroundStyle(AppTheme.primaryText)

            Text(localization.phrase("Choose exactly which modules are available in Custom mode. No data is deleted when you turn a module off."))
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.secondaryText)

            ForEach(AppModule.allCases) { module in
                Toggle(isOn: moduleBinding(for: module)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(localization.phrase(module.title))
                            .font(AppTheme.bodyFont)
                            .foregroundStyle(AppTheme.primaryText)
                        Text(moduleVisibilityDescription(for: module))
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
                .tint(AppTheme.accentColor)
            }
        }
        .padding(14)
        .background(AppTheme.elevatedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func applyMode(_ mode: WorkMode) {
        do {
            let resolved = try service.ensurePersistedConfiguration(
                settings: currentSettings,
                moduleConfiguration: currentModuleConfiguration,
                in: modelContext
            )
            service.apply(mode: mode, settings: resolved.0, moduleConfiguration: resolved.1)
            try modelContext.save()
        } catch {
            saveMessage = error.localizedDescription
        }
    }

    private func setModule(_ module: AppModule, enabled: Bool) {
        do {
            let resolved = try service.ensurePersistedConfiguration(
                settings: currentSettings,
                moduleConfiguration: currentModuleConfiguration,
                in: modelContext
            )
            resolved.1.setEnabled(enabled, for: module)
            resolved.0.workMode = .custom
            resolved.0.hasCompletedWorkModeOnboarding = true
            try modelContext.save()
        } catch {
            saveMessage = error.localizedDescription
        }
    }

    private func moduleBinding(for module: AppModule) -> Binding<Bool> {
        Binding(
            get: { service.isModuleEnabled(module, settings: currentSettings, moduleConfiguration: currentModuleConfiguration) },
            set: { setModule(module, enabled: $0) }
        )
    }

    private func moduleVisibilityDescription(for module: AppModule) -> String {
        switch module {
        case .agenda:
            localization.phrase("Shows the Agenda tab and planning tools.")
        case .workRegistrations:
            localization.phrase("Shows the Registrations tab and work-entry workflow.")
        case .timeTracking:
            localization.phrase("Enables time tracking inside registration workflows.")
        case .quotes:
            localization.phrase("Enables quotes and proposal workflows.")
        case .invoices:
            localization.phrase("Enables invoice creation, history, and exports.")
        case .mileageTracking:
            localization.phrase("Enables mileage tracking and invoice-linked trips.")
        case .receipts:
            localization.phrase("Enables receipt storage and expense evidence.")
        case .paymentReminders:
            localization.phrase("Enables overdue invoice reminders.")
        case .recurringInvoices:
            localization.phrase("Enables recurring invoice templates.")
        case .customerSignatures:
            localization.phrase("Enables customer signatures on invoices and quotes.")
        case .vatOverview:
            localization.phrase("Enables quarterly VAT reporting.")
        case .annualRevenueSummary:
            localization.phrase("Enables annual revenue summaries.")
        case .multipleCompanyProfiles:
            localization.phrase("Enables multiple company profiles and export branding.")
        }
    }

    private var currentSettings: AppSettings? {
        appSettings.first
    }

    private var currentModuleConfiguration: ModuleVisibilityConfiguration? {
        moduleConfigurations.first
    }

    private var saveAlertBinding: Binding<Bool> {
        Binding(
            get: { saveMessage != nil },
            set: { if !$0 { saveMessage = nil } }
        )
    }

    private var localization: AppLocalization {
        AppLocalization(localeIdentifier: currentSettings?.preferredLocaleIdentifier)
    }
}
