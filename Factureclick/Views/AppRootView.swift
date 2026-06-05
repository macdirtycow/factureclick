//
//  AppRootView.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import SwiftData
import SwiftUI

struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppViewModel.self) private var appViewModel
    @Query private var appSettings: [AppSettings]
    @Query private var moduleConfigurations: [ModuleVisibilityConfiguration]
    @Query(sort: \CompanyProfile.createdAt, order: .reverse) private var companyProfiles: [CompanyProfile]
    @Query(sort: \Invoice.date, order: .reverse) private var invoices: [Invoice]
    @State private var isPresentingWorkModeOnboarding = false
    @State private var showsLaunchOverlay = true
    @State private var hasPerformedInitialLoad = false

    private let workModeService = WorkModeConfigurationService()
    private let companyProfileSelectionService = CompanyProfileSelectionService()
    private let paymentReminderService = PaymentReminderService()

    var body: some View {
        ZStack {
            AppTheme.screenBackground
                .ignoresSafeArea()

            TabView(selection: tabSelection) {
                ForEach(safeVisibleTabs) { tab in
                    NavigationStack {
                        destinationView(for: tab)
                    }
                    .toolbarBackground(AppTheme.screenBackground, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            HStack(spacing: 8) {
                                AppLogoView(
                                    showsWordmark: false,
                                    size: 28,
                                    accentColor: toolbarAccentColor
                                )

                                VStack(spacing: 0) {
                                    Text(toolbarTitle)
                                        .font(.system(.headline, design: .rounded).weight(.semibold))
                                        .foregroundStyle(AppTheme.primaryText)

                                    if let toolbarSubtitle {
                                        Text(toolbarSubtitle)
                                            .font(.system(.caption2, design: .rounded).weight(.medium))
                                            .foregroundStyle(AppTheme.secondaryText)
                                    }
                                }
                            }
                        }
                    }
                    .tabItem {
                        Label(localization.text(tab.localizationKey), systemImage: tab.systemImage)
                    }
                    .tag(tab)
                }
            }

            if showsLaunchOverlay {
                launchOverlay
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .toolbarBackground(AppTheme.screenBackground, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .tint(currentAccentColor)
        .id("\(currentAccentHex)|\(currentLocaleIdentifier)")
        .environment(\.locale, Locale(identifier: currentLocaleIdentifier))
        .preferredColorScheme(preferredColorScheme)
        .task {
            await performInitialLoadIfNeeded()
        }
        .onAppear {
            hideLaunchOverlayIfNeeded()
            synchronizeVisibleState()
        }
        .onChange(of: currentAccentHex) { _, _ in
            syncAccentColorDefaults()
        }
        .onChange(of: safeVisibleTabs.map(\.rawValue).joined(separator: "|")) { _, _ in
            synchronizeVisibleState()
        }
        .onChange(of: currentSettings?.hasCompletedWorkModeOnboarding ?? false) { _, _ in
            synchronizeVisibleState()
        }
        .fullScreenCover(isPresented: $isPresentingWorkModeOnboarding) {
            WorkModeOnboardingView(
                existingSettings: currentSettings,
                moduleConfiguration: currentModuleConfiguration
            ) {
                isPresentingWorkModeOnboarding = false
                synchronizeVisibleState()
            }
        }
    }

    @ViewBuilder
    private func destinationView(for tab: AppTab) -> some View {
        switch tab {
        case .dashboard:
            DashboardView()
        case .agenda:
            AgendaView()
        case .registrations:
            TimeTrackingView()
        case .clients:
            ClientListView()
        case .products:
            ProductListView()
        case .invoices:
            InvoiceGeneratorView()
        case .settings:
            CollaborationSettingsView()
        }
    }

    private var tabSelection: Binding<AppTab> {
        Binding(
            get: { appViewModel.selectedTab },
            set: { appViewModel.selectedTab = $0 }
        )
    }

    private var currentSettings: AppSettings? {
        appSettings.first
    }

    private var currentModuleConfiguration: ModuleVisibilityConfiguration? {
        moduleConfigurations.first
    }

    private var activeCompanyProfile: CompanyProfile? {
        companyProfileSelectionService.activeProfile(from: companyProfiles, settings: currentSettings)
    }

    private var visibleTabs: [AppTab] {
        workModeService.visibleTabs(
            settings: currentSettings,
            moduleConfiguration: currentModuleConfiguration
        )
    }

    private var safeVisibleTabs: [AppTab] {
        let tabs = visibleTabs
        return tabs.isEmpty ? [.dashboard] : tabs
    }

    private var currentAccentHex: String {
        currentSettings?.preferredAccentColorHex ?? AppAccentTheme.ocean.hex
    }

    private var currentLocaleIdentifier: String {
        SupportedLocale.resolving(currentSettings?.preferredLocaleIdentifier ?? Locale.current.identifier).rawValue
    }

    private var currentAccentColor: Color {
        AppTheme.color(hex: currentAccentHex)
    }

    private var toolbarAccentColor: Color {
        currentAccentColor
    }

    private var toolbarTitle: String {
        let companyName = activeCompanyProfile?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return companyName.isEmpty ? AppBrand.displayName : companyName
    }

    private var toolbarSubtitle: String? {
        let ownerName = activeCompanyProfile?.ownerName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return ownerName.isEmpty ? nil : ownerName
    }

    private var localization: AppLocalization {
        AppLocalization(localeIdentifier: currentSettings?.preferredLocaleIdentifier)
    }

    private var preferredColorScheme: ColorScheme? {
        switch currentSettings?.appearancePreference ?? .system {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }

    private var launchOverlay: some View {
        VStack(spacing: 14) {
            AppLogoView(
                logoData: nil,
                title: toolbarTitle,
                subtitle: toolbarSubtitle ?? "",
                showsWordmark: false,
                size: 72,
                accentColor: toolbarAccentColor
            )

            Text(toolbarTitle)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(AppTheme.primaryText)

            if let toolbarSubtitle {
                Text(toolbarSubtitle)
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.screenBackground.ignoresSafeArea())
    }

    private var persistenceRefreshKey: String {
        "\(appSettings.count)|\(moduleConfigurations.count)"
    }

    private func ensureConfigurationIfNeeded() {
        guard currentSettings == nil || currentModuleConfiguration == nil else {
            return
        }

        do {
            _ = try workModeService.ensurePersistedConfiguration(
                settings: currentSettings,
                moduleConfiguration: currentModuleConfiguration,
                in: modelContext
            )
        } catch {
            return
        }
    }

    private func ensureAutomaticReminderDraftsIfNeeded() {
        do {
            try paymentReminderService.generateAutomaticDrafts(
                for: invoices,
                localeIdentifier: currentSettings?.preferredLocaleIdentifier,
                in: modelContext
            )
        } catch {
            assertionFailure("Unable to generate automatic reminder drafts: \(error.localizedDescription)")
        }
    }

    private func synchronizeVisibleState() {
        isPresentingWorkModeOnboarding = workModeService.isOnboardingRequired(settings: currentSettings)

        guard safeVisibleTabs.contains(appViewModel.selectedTab) else {
            appViewModel.selectedTab = safeVisibleTabs.first ?? .dashboard
            return
        }
    }

    private func hideLaunchOverlayIfNeeded() {
        guard showsLaunchOverlay else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeOut(duration: 0.25)) {
                showsLaunchOverlay = false
            }
        }
    }

    @MainActor
    private func performInitialLoadIfNeeded() async {
        guard !hasPerformedInitialLoad else { return }
        hasPerformedInitialLoad = true

        hideLaunchOverlayIfNeeded()
        syncAccentColorDefaults()
        ensureConfigurationIfNeeded()
        synchronizeVisibleState()

        await Task.yield()
        try? await Task.sleep(for: .milliseconds(250))
        ensureAutomaticReminderDraftsIfNeeded()
    }

    private func syncAccentColorDefaults() {
        UserDefaults.standard.set(currentAccentHex, forKey: AppTheme.accentColorDefaultsKey)
    }
}

#Preview {
    AppRootView()
        .environment(AppViewModel())
}
