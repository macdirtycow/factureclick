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

        return profiles.sorted { $0.createdAt < $1.createdAt }.first
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
        explicitProfile
            ?? client?.companyProfile
            ?? registrations.compactMap(\.companyProfile).first
            ?? fallbackActiveProfile
    }

    func resolveQuoteProfile(
        explicitProfile: CompanyProfile?,
        client: Client?,
        fallbackActiveProfile: CompanyProfile?
    ) -> CompanyProfile? {
        explicitProfile ?? client?.companyProfile ?? fallbackActiveProfile
    }

    func resolveWorkEntryProfile(
        explicitProfile: CompanyProfile?,
        client: Client?,
        fallbackActiveProfile: CompanyProfile?
    ) -> CompanyProfile? {
        explicitProfile ?? client?.companyProfile ?? fallbackActiveProfile
    }
}
