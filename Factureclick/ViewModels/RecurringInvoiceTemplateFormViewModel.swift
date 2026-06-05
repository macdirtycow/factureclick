//
//  RecurringInvoiceTemplateFormViewModel.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import Foundation
import Observation

@Observable
final class RecurringInvoiceTemplateFormViewModel {
    var title: String
    var selectedClientID: UUID?
    var frequency: RecurringInvoiceFrequency
    var startDate: Date
    var endDate: Date?
    var hasEndDate: Bool
    var paymentTermDays: Int
    var notes: String
    var isActive: Bool
    var lineDrafts: [InvoiceLineDraft]

    init(template: RecurringInvoiceTemplate? = nil) {
        self.title = template?.title ?? ""
        self.selectedClientID = template?.client.id
        self.frequency = template?.frequency ?? .monthly
        self.startDate = template?.startDate ?? .now
        self.endDate = template?.endDate
        self.hasEndDate = template?.endDate != nil
        self.paymentTermDays = template?.paymentTermDays ?? 30
        self.notes = template?.notes ?? ""
        self.isActive = template?.isActive ?? true
        self.lineDrafts = template?.lines
            .sorted { $0.sortOrder < $1.sortOrder }
            .map {
                InvoiceLineDraft(
                    description: $0.description,
                    quantity: $0.quantity,
                    unitPrice: $0.unitPrice,
                    vatRate: $0.vatRate
                )
            } ?? []
    }

    var isValid: Bool {
        !trimmedTitle.isEmpty && selectedClientID != nil && !lineDrafts.isEmpty && (!hasEndDate || startDate <= (endDate ?? startDate))
    }

    func addLine() {
        lineDrafts.append(
            InvoiceLineDraft(
                description: "Recurring service",
                quantity: 1,
                unitPrice: 0,
                vatRate: 21
            )
        )
    }

    func removeLine(id: UUID) {
        lineDrafts.removeAll { $0.id == id }
    }

    func updateLine(_ line: InvoiceLineDraft, at index: Int) {
        guard lineDrafts.indices.contains(index) else { return }
        lineDrafts[index] = line
    }

    func apply(to template: RecurringInvoiceTemplate, client: Client, companyProfile: CompanyProfile?) {
        template.title = trimmedTitle
        template.client = client
        template.companyProfile = companyProfile ?? client.companyProfile
        template.frequency = frequency
        template.startDate = Calendar.current.startOfDay(for: startDate)
        template.endDate = hasEndDate ? endDate : nil
        template.paymentTermDays = max(paymentTermDays, 1)
        template.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        template.isActive = isActive
        for (index, draft) in lineDrafts.enumerated() {
            let line = RecurringInvoiceTemplateLine(
                description: draft.description.trimmingCharacters(in: .whitespacesAndNewlines),
                quantity: draft.quantity,
                unitPrice: draft.unitPrice,
                vatRate: draft.vatRate,
                sortOrder: index,
                template: template
            )
            template.lines.append(line)
        }
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
