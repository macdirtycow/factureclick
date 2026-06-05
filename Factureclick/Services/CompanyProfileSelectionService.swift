//
//  CompanyProfileSelectionService.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import Foundation
import SwiftData

struct CompanyProfileSelectionService {
    func activeProfile(from profiles: [CompanyProfile], settings: AppSettings?) -> CompanyProfile? {
        if let activeCompanyProfileID = settings?.activeCompanyProfileID,
           let activeProfile = profiles.first(where: { $0.id == activeCompanyProfileID }) {
            return activeProfile
        }

        return profiles
            .sorted { $0.createdAt > $1.createdAt }
            .sorted { lhs, rhs in
                if isConfigured(lhs) == isConfigured(rhs) {
                    return lhs.createdAt > rhs.createdAt
                }
                return isConfigured(lhs) && !isConfigured(rhs)
            }
            .first
    }

    func setActiveProfile(
        _ profile: CompanyProfile,
        settings: AppSettings?,
        in context: ModelContext
    ) throws {
        let targetSettings = settings ?? AppSettings()
        targetSettings.activeCompanyProfileID = profile.id

        if settings == nil {
            context.insert(targetSettings)
        }

        try context.save()
    }

    func resolveInvoiceProfile(
        explicitProfile: CompanyProfile?,
        client: Client?,
        registrations: [WorkEntry],
        fallbackActiveProfile: CompanyProfile?
    ) -> CompanyProfile? {
        preferredProfile(
            candidates: [
                explicitProfile,
                client?.companyProfile,
                registrations.compactMap(\.companyProfile).first,
                fallbackActiveProfile
            ]
        )
    }

    func resolveQuoteProfile(
        explicitProfile: CompanyProfile?,
        client: Client?,
        fallbackActiveProfile: CompanyProfile?
    ) -> CompanyProfile? {
        preferredProfile(candidates: [explicitProfile, client?.companyProfile, fallbackActiveProfile])
    }

    func resolveWorkEntryProfile(
        explicitProfile: CompanyProfile?,
        client: Client?,
        fallbackActiveProfile: CompanyProfile?
    ) -> CompanyProfile? {
        preferredProfile(candidates: [explicitProfile, client?.companyProfile, fallbackActiveProfile])
    }

    private func preferredProfile(candidates: [CompanyProfile?]) -> CompanyProfile? {
        let profiles = candidates.compactMap { $0 }
        return profiles.first(where: isConfigured(_:)) ?? profiles.first
    }

    private func isConfigured(_ profile: CompanyProfile) -> Bool {
        !profile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        || !profile.ownerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        || !profile.address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        || !profile.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        || !profile.phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        || !profile.iban.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
