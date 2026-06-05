//
//  FactureclickPersistentSchema.swift
//  Factureclick
//
//  Created by Codex on 27/09/2026.
//

import SwiftData

enum FactureclickPersistentSchema {
    static func makeCurrentSchema() -> Schema {
        Schema(versionedSchema: V1.self)
    }

    enum V1: VersionedSchema {
        static let versionIdentifier = Schema.Version(1, 0, 0)

        static var models: [any PersistentModel.Type] {
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
}
