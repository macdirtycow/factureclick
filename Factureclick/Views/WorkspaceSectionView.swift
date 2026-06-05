//
//  WorkspaceSectionView.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import SwiftData
import SwiftUI

struct WorkspaceSectionView: View {
    let tab: AppTab

    @Query private var appSettings: [AppSettings]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                heroCard
                quickActionsCard
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(AppTheme.screenBackground.ignoresSafeArea())
        .navigationTitle(tab.title)
        .navigationBarTitleDisplayMode(.large)
    }

    private var heroCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(tab.headline)
                    .font(AppTheme.titleFont)
                    .foregroundStyle(AppTheme.primaryText)

                Text(tab.summary)
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.secondaryText)

                Divider()
                    .padding(.vertical, 4)

                Text("section.shared.locale")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.secondaryText)

                Text(currentLocaleDisplayName)
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)
            }
        }
    }

    private var quickActionsCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("section.shared.quickActions")
                    .font(AppTheme.sectionTitleFont)
                    .foregroundStyle(AppTheme.primaryText)

                ForEach(sampleHighlights, id: \.self) { highlight in
                    HStack(spacing: 12) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(AppTheme.accentColor)

                        Text(LocalizedStringKey(highlight))
                            .font(AppTheme.bodyFont)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
            }
        }
    }

    private var currentLocaleDisplayName: String {
        let identifier = appSettings.first?.preferredLocaleIdentifier ?? Locale.current.identifier
        let locale = Locale(identifier: identifier)
        return locale.localizedString(forIdentifier: identifier) ?? identifier
    }

    private var sampleHighlights: [String] {
        switch tab {
        case .dashboard:
            ["highlight.dashboard.1", "highlight.dashboard.2", "highlight.dashboard.3"]
        case .agenda:
            ["highlight.agenda.1", "highlight.agenda.2", "highlight.agenda.3"]
        case .registrations:
            ["highlight.registrations.1", "highlight.registrations.2", "highlight.registrations.3"]
        case .clients:
            ["highlight.clients.1", "highlight.clients.2", "highlight.clients.3"]
        case .products:
            ["highlight.products.1", "highlight.products.2", "highlight.products.3"]
        case .invoices:
            ["highlight.invoices.1", "highlight.invoices.2", "highlight.invoices.3"]
        case .settings:
            ["highlight.settings.1", "highlight.settings.2", "highlight.settings.3"]
        }
    }
}

#Preview {
    NavigationStack {
        WorkspaceSectionView(tab: .dashboard)
            .modelContainer(ModelContainerFactory.makeShared(isStoredInMemoryOnly: true))
    }
}
