//
//  CollaborationRule.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation
import SwiftData

@Model
final class CollaborationRule {
    @Attribute(.unique) var id: UUID
    var percentage: Double
    var partnerName: String
    var notes: String

    var client: Client?

    @Relationship(deleteRule: .nullify, inverse: \WorkEntry.collaborationRule)
    var workEntries: [WorkEntry]

    init(
        id: UUID = UUID(),
        client: Client? = nil,
        percentage: Double = 0,
        partnerName: String = "",
        notes: String = "",
        workEntries: [WorkEntry] = []
    ) {
        self.id = id
        self.client = client
        self.percentage = percentage
        self.partnerName = partnerName
        self.notes = notes
        self.workEntries = workEntries
    }
}
