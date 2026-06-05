//
//  FactureclickPersistentSchema.swift
//  Factureclick
//
//  Created by Codex on 27/09/2026.
//

import SwiftData

enum FactureclickPersistentSchema {
    /// This version tracks the live SwiftData schema used by the app today.
    /// When we later move to formal VersionedSchema migrations, freeze this
    /// model set as the first immutable migration baseline before changing
    /// stored properties in these model types again.
    static let currentVersion = Schema.Version(1, 0, 0)

    static func makeCurrentSchema() -> Schema {
        Schema(currentModelTypes(), version: currentVersion)
    }

    static func currentModelTypes() -> [any PersistentModel.Type] {
        [
            AppSettings.self,
            ModuleVisibilityConfiguration.self,
            CompanyProfile.self,
            Client.self,
            Product.self,
            WorkEntry.self,
            Invoice.self,
            InvoiceReminder.self,
            InvoiceLine.self,
            MileageEntry.self,
            RecurringInvoiceTemplate.self,
            RecurringInvoiceTemplateLine.self,
            RecurringInvoiceGeneration.self,
            Quote.self,
            QuoteLine.self,
            CollaborationRule.self,
            Attachment.self,
            Receipt.self,
            CustomerSignature.self
        ]
    }
}
