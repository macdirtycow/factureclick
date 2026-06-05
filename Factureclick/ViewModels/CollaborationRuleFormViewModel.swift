//
//  CollaborationRuleFormViewModel.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation
import Observation
import SwiftData

@Observable
final class CollaborationRuleFormViewModel {
    var selectedClientID: UUID?
    var partnerName: String
    var percentage: Double
    var notes: String

    init(rule: CollaborationRule? = nil) {
        self.selectedClientID = rule?.client?.id
        self.partnerName = rule?.partnerName ?? ""
        self.percentage = rule?.percentage ?? 0
        self.notes = rule?.notes ?? ""
    }

    var canSave: Bool {
        !partnerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && percentage >= 0 && percentage <= 100
    }

    func save(rule: CollaborationRule?, clients: [Client], in context: ModelContext) throws {
        let client = clients.first(where: { $0.id == selectedClientID })

        if let rule {
            rule.client = client
            rule.partnerName = partnerName.trimmingCharacters(in: .whitespacesAndNewlines)
            rule.percentage = percentage
            rule.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            let newRule = CollaborationRule(
                client: client,
                percentage: percentage,
                partnerName: partnerName.trimmingCharacters(in: .whitespacesAndNewlines),
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            context.insert(newRule)
        }

        try context.save()
    }
}
