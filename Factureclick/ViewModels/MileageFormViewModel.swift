//
//  MileageFormViewModel.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import Foundation
import Observation
import SwiftData

@Observable
final class MileageFormViewModel {
    var date: Date
    var selectedClientID: UUID?
    var startLocation: String
    var endLocation: String
    var purpose: String
    var numberOfKilometers: Double
    var reimbursementRatePerKilometer: Double
    var includeOnInvoice: Bool
    var selectedInvoiceID: UUID?

    private let repository: MileageRepository

    init(
        entry: MileageEntry? = nil,
        repository: MileageRepository = MileageRepository()
    ) {
        self.date = entry?.date ?? .now
        self.selectedClientID = entry?.client?.id
        self.startLocation = entry?.startLocation ?? ""
        self.endLocation = entry?.endLocation ?? ""
        self.purpose = entry?.purpose ?? ""
        self.numberOfKilometers = entry?.numberOfKilometers ?? 0
        self.reimbursementRatePerKilometer = entry?.reimbursementRatePerKilometer ?? 0
        self.includeOnInvoice = entry?.includeOnInvoice ?? true
        self.selectedInvoiceID = entry?.invoice?.id
        self.repository = repository
    }

    var totalTravelCost: Double {
        repository.totalTravelCost(kilometers: numberOfKilometers, ratePerKilometer: reimbursementRatePerKilometer)
    }

    var canSave: Bool {
        !trimmedStartLocation.isEmpty &&
        !trimmedEndLocation.isEmpty &&
        !trimmedPurpose.isEmpty &&
        numberOfKilometers > 0 &&
        reimbursementRatePerKilometer >= 0
    }

    func apply(to entry: MileageEntry, clients: [Client], invoices: [Invoice]) {
        let selectedClient = clients.first(where: { $0.id == selectedClientID })
        let selectedInvoice = invoices.first(where: { $0.id == selectedInvoiceID })
        let canLinkInvoice = includeOnInvoice && (selectedInvoice == nil || selectedInvoice?.client.id == selectedClient?.id || selectedClient == nil)

        entry.date = date
        entry.client = selectedClient
        entry.startLocation = trimmedStartLocation
        entry.endLocation = trimmedEndLocation
        entry.purpose = trimmedPurpose
        entry.numberOfKilometers = numberOfKilometers
        entry.reimbursementRatePerKilometer = reimbursementRatePerKilometer
        entry.totalTravelCost = totalTravelCost
        entry.includeOnInvoice = includeOnInvoice
        entry.invoice = canLinkInvoice ? selectedInvoice : nil
    }

    private var trimmedStartLocation: String {
        startLocation.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedEndLocation: String {
        endLocation.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedPurpose: String {
        purpose.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
