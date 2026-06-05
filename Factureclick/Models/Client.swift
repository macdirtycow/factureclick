//
//  Client.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation
import SwiftData

@Model
final class Client {
    @Attribute(.unique) var id: UUID
    var name: String
    var contactPerson: String
    var email: String
    var phone: String
    var address: String
    var kvkNumber: String
    var vatNumber: String
    var paymentTermDays: Int
    var defaultHourlyRate: Double

    @Relationship(deleteRule: .deny, inverse: \WorkEntry.client)
    var workEntries: [WorkEntry]

    @Relationship(deleteRule: .deny, inverse: \Invoice.client)
    var invoices: [Invoice]

    @Relationship(deleteRule: .nullify, inverse: \CollaborationRule.client)
    var collaborationRules: [CollaborationRule]

    init(
        id: UUID = UUID(),
        name: String = "",
        contactPerson: String = "",
        email: String = "",
        phone: String = "",
        address: String = "",
        kvkNumber: String = "",
        vatNumber: String = "",
        paymentTermDays: Int = 30,
        defaultHourlyRate: Double = 0,
        workEntries: [WorkEntry] = [],
        invoices: [Invoice] = [],
        collaborationRules: [CollaborationRule] = []
    ) {
        self.id = id
        self.name = name
        self.contactPerson = contactPerson
        self.email = email
        self.phone = phone
        self.address = address
        self.kvkNumber = kvkNumber
        self.vatNumber = vatNumber
        self.paymentTermDays = paymentTermDays
        self.defaultHourlyRate = defaultHourlyRate
        self.workEntries = workEntries
        self.invoices = invoices
        self.collaborationRules = collaborationRules
    }
}
