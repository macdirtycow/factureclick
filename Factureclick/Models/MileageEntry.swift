//
//  MileageEntry.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import Foundation
import SwiftData

@Model
final class MileageEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    var startLocation: String
    var endLocation: String
    var purpose: String
    var numberOfKilometers: Double
    var reimbursementRatePerKilometer: Double
    var totalTravelCost: Double
    var includeOnInvoice: Bool
    var createdAt: Date

    var client: Client?
    var invoice: Invoice?

    init(
        id: UUID = UUID(),
        date: Date = .now,
        client: Client? = nil,
        startLocation: String = "",
        endLocation: String = "",
        purpose: String = "",
        numberOfKilometers: Double = 0,
        reimbursementRatePerKilometer: Double = 0,
        totalTravelCost: Double = 0,
        includeOnInvoice: Bool = true,
        createdAt: Date = .now,
        invoice: Invoice? = nil
    ) {
        self.id = id
        self.date = date
        self.client = client
        self.startLocation = startLocation
        self.endLocation = endLocation
        self.purpose = purpose
        self.numberOfKilometers = numberOfKilometers
        self.reimbursementRatePerKilometer = reimbursementRatePerKilometer
        self.totalTravelCost = totalTravelCost
        self.includeOnInvoice = includeOnInvoice
        self.createdAt = createdAt
        self.invoice = invoice
    }
}
