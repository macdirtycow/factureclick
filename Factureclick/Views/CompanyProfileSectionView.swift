//
//  CompanyProfileSectionView.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import SwiftData
import SwiftUI

struct CompanyProfileSectionView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \CompanyProfile.createdAt, order: .reverse) private var companyProfiles: [CompanyProfile]
    @Query private var appSettings: [AppSettings]

    @State private var profileFormContext: CompanyProfileFormContext?

    private let selectionService = CompanyProfileSelectionService()

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            SectionCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text(localization.phrase("Company profiles"))
                        .font(AppTheme.titleFont)
                        .foregroundStyle(AppTheme.primaryText)

                    Text(localization.phrase("Manage multiple business identities and choose which profile is active for invoices, quotes, and exports."))
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }

            SectionCard {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(localization.phrase("Profiles"))
                            .font(AppTheme.sectionTitleFont)
                            .foregroundStyle(AppTheme.primaryText)

                        Spacer()

                        Button(localization.phrase("Add Profile")) {
                            profileFormContext = CompanyProfileFormContext(
                                profileID: nil,
                                shouldSetActiveOnSave: activeProfile == nil
                            )
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.accentColor)
                    }

                    if let activeProfile {
                        activeProfileBanner(activeProfile)
                    }

                    if companyProfiles.isEmpty {
                        Text(localization.phrase("No company profiles yet."))
                            .font(AppTheme.bodyFont)
                            .foregroundStyle(AppTheme.secondaryText)
                    } else {
                        ForEach(companyProfiles) { profile in
                            profileRow(profile)

                            if profile.id != companyProfiles.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
        .sheet(item: $profileFormContext) { context in
            NavigationStack {
                CompanyProfileFormView(
                    profileID: context.profileID,
                    shouldSetActiveOnSave: context.shouldSetActiveOnSave
                )
            }
        }
    }

    private func activeProfileBanner(_ profile: CompanyProfile) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(localization.text(.activeCompany))
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.secondaryText)
                Text(profile.name)
                    .font(AppTheme.bodyFont.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
            }

            Spacer()
        }
        .padding(14)
        .background(AppTheme.elevatedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func profileRow(_ profile: CompanyProfile) -> some View {
        Button {
            profileFormContext = CompanyProfileFormContext(
                profileID: profile.id,
                shouldSetActiveOnSave: false
            )
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(AppTheme.color(hex: profile.accentColor))
                            .frame(width: 12, height: 12)
                        Text(profile.name)
                            .font(AppTheme.bodyFont.weight(.semibold))
                            .foregroundStyle(AppTheme.primaryText)
                    }

                    Text(profile.ownerName.isEmpty ? localization.phrase("No owner name") : profile.ownerName)
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.secondaryText)

                    if !profile.email.isEmpty {
                        Text(profile.email)
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    if activeProfile?.id == profile.id {
                        Text(localization.phrase("Active"))
                            .font(AppTheme.captionFont.weight(.semibold))
                            .foregroundStyle(.green)
                    } else {
                        Button(localization.phrase("Set Active")) {
                            try? selectionService.setActiveProfile(profile, settings: appSettings.first, in: modelContext)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var activeProfile: CompanyProfile? {
        selectionService.activeProfile(from: companyProfiles, settings: appSettings.first)
    }

    private var localization: AppLocalization {
        AppLocalization(localeIdentifier: appSettings.first?.preferredLocaleIdentifier)
    }
}

private struct CompanyProfileFormContext: Identifiable {
    let id = UUID()
    let profileID: UUID?
    let shouldSetActiveOnSave: Bool
}
