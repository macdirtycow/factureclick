//
//  WorkModeOnboardingView.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import SwiftData
import SwiftUI

struct WorkModeOnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var appSettings: [AppSettings]

    let existingSettings: AppSettings?
    let moduleConfiguration: ModuleVisibilityConfiguration?
    let onComplete: () -> Void

    @State private var selectedMode: WorkMode = .hybrid
    @State private var customEnabledModules = Set(AppModule.allCases)
    @State private var errorMessage: String?

    private let configurationService = WorkModeConfigurationService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    SectionCard {
                        VStack(alignment: .leading, spacing: 12) {
                            AppLogoView()

                            Text(localization.phrase("Choose your work mode"))
                                .font(AppTheme.titleFont)
                                .foregroundStyle(AppTheme.primaryText)

                            Text(localization.phrase("Factureclick can prioritize the workflows you actually use. You can change this later in Settings."))
                                .font(AppTheme.bodyFont)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }

                    ForEach(WorkMode.allCases) { mode in
                        Button {
                            selectedMode = mode
                        } label: {
                            SectionCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text(localization.phrase(mode.title))
                                            .font(AppTheme.sectionTitleFont)
                                            .foregroundStyle(AppTheme.primaryText)
                                        Spacer()
                                        Image(systemName: selectedMode == mode ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(selectedMode == mode ? AppTheme.accentColor : AppTheme.secondaryText)
                                    }

                                    Text(localization.phrase(mode.summary))
                                        .font(AppTheme.bodyFont)
                                        .foregroundStyle(AppTheme.secondaryText)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    if selectedMode == .custom {
                        SectionCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text(localization.phrase("Custom modules"))
                                    .font(AppTheme.sectionTitleFont)
                                    .foregroundStyle(AppTheme.primaryText)

                                Text(localization.phrase("Choose which features should be visible in the app. You can change this later in Settings."))
                                    .font(AppTheme.bodyFont)
                                    .foregroundStyle(AppTheme.secondaryText)

                                ForEach(AppModule.allCases) { module in
                                    Toggle(
                                        localization.phrase(module.title),
                                        isOn: customModuleBinding(for: module)
                                    )
                                    .tint(AppTheme.accentColor)
                                }
                            }
                        }
                    }

                    Button(localization.phrase("Continue")) {
                        completeOnboarding()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accentColor)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(AppTheme.screenBackground.ignoresSafeArea())
            .navigationBarBackButtonHidden(true)
            .alert(localization.phrase("Work Mode"), isPresented: errorBinding) {
                Button(localization.phrase("OK"), role: .cancel) { }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func completeOnboarding() {
        do {
            let resolved = try configurationService.ensurePersistedConfiguration(
                settings: existingSettings,
                moduleConfiguration: moduleConfiguration,
                in: modelContext
            )
            configurationService.apply(
                mode: selectedMode,
                settings: resolved.0,
                moduleConfiguration: resolved.1
            )
            if selectedMode == .custom {
                for module in AppModule.allCases {
                    resolved.1.setEnabled(customEnabledModules.contains(module), for: module)
                }
            }
            try modelContext.save()
            onComplete()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private var localization: AppLocalization {
        AppLocalization(localeIdentifier: existingSettings?.preferredLocaleIdentifier ?? appSettings.first?.preferredLocaleIdentifier)
    }

    private func customModuleBinding(for module: AppModule) -> Binding<Bool> {
        Binding(
            get: { customEnabledModules.contains(module) },
            set: { isEnabled in
                if isEnabled {
                    customEnabledModules.insert(module)
                } else {
                    customEnabledModules.remove(module)
                }
            }
        )
    }
}
