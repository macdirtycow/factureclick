//
//  CollaborationSettingsView.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import SwiftData
import SwiftUI

struct CollaborationSettingsView: View {
    @Query private var appSettings: [AppSettings]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                CollaborationSettingsContent {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo("company-profile", anchor: .top)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
        }
        .background(AppTheme.screenBackground.ignoresSafeArea())
        .navigationTitle(localization.text(.settingsAlertTitle))
        .navigationBarTitleDisplayMode(.large)
    }

    private var localization: AppLocalization {
        AppLocalization(localeIdentifier: appSettings.first?.preferredLocaleIdentifier)
    }
}

struct CollaborationSettingsContent: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \CollaborationRule.partnerName) private var rules: [CollaborationRule]
    @Query private var appSettings: [AppSettings]

    @State private var selectedRule: CollaborationRule?
    @State private var isPresentingForm = false

    let onBusinessDataTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            AppSettingsSectionView(onBusinessDataTap: onBusinessDataTap)

            WorkModeConfigurationSectionView()

            CompanyProfileSectionView()
                .id("company-profile")

            DataToolsSectionView()

            collaborationRulesCard
        }
        .sheet(isPresented: $isPresentingForm) {
            NavigationStack {
                CollaborationRuleFormView(rule: selectedRule)
            }
        }
    }

    private var collaborationRulesCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(localization.phrase("Rules"))
                        .font(AppTheme.sectionTitleFont)
                        .foregroundStyle(AppTheme.primaryText)

                    Spacer()

                    Button(localization.phrase("Add Rule")) {
                        selectedRule = nil
                        isPresentingForm = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accentColor)
                }

                if rules.isEmpty {
                    Text(localization.phrase("No collaboration rules yet."))
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                } else {
                    ForEach(rules) { rule in
                        Button {
                            selectedRule = rule
                            isPresentingForm = true
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(rule.partnerName)
                                        .font(AppTheme.bodyFont.weight(.semibold))
                                        .foregroundStyle(AppTheme.primaryText)

                                    Text(rule.client?.name ?? localization.phrase("General rule"))
                                        .font(AppTheme.captionFont)
                                        .foregroundStyle(AppTheme.secondaryText)

                                    if !rule.notes.isEmpty {
                                        Text(rule.notes)
                                            .font(AppTheme.captionFont)
                                            .foregroundStyle(AppTheme.secondaryText)
                                    }
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 8) {
                                    Text("\(rule.percentage.formatted(.number.precision(.fractionLength(0...2))))%")
                                        .font(AppTheme.bodyFont.weight(.semibold))
                                        .foregroundStyle(AppTheme.primaryText)

                                    Button(role: .destructive) {
                                        modelContext.delete(rule)
                                        try? modelContext.save()
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if rule.id != rules.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private var localization: AppLocalization {
        AppLocalization(localeIdentifier: appSettings.first?.preferredLocaleIdentifier)
    }
}

#Preview {
    NavigationStack {
        CollaborationSettingsView()
            .modelContainer(DashboardPreviewData.makeContainer())
    }
}
