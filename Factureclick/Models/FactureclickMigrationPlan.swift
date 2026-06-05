//
//  FactureclickMigrationPlan.swift
//  Factureclick
//
//  Created by Codex on 27/09/2026.
//

import SwiftData

enum FactureclickMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [
            FactureclickPersistentSchema.V1.self
        ]
    }

    static var stages: [MigrationStage] {
        []
    }
}
