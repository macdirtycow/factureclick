//
//  ClientFormViewModel.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation
import Observation

@Observable
final class ClientFormViewModel {
    var name: String
    var contactPerson: String
    var email: String
    var phone: String
    var address: String
    var kvkNumber: String
    var vatNumber: String
    var paymentTermDays: Int
    var defaultHourlyRate: Double
    var notes: String

    init(client: Client? = nil) {
        self.name = client?.name ?? ""
        self.contactPerson = client?.contactPerson ?? ""
        self.email = client?.email ?? ""
        self.phone = client?.phone ?? ""
        self.address = client?.address ?? ""
        self.kvkNumber = client?.kvkNumber ?? ""
        self.vatNumber = client?.vatNumber ?? ""
        self.paymentTermDays = client?.paymentTermDays ?? 30
        self.defaultHourlyRate = client?.defaultHourlyRate ?? 0
        self.notes = client?.notes ?? ""
    }

    var isValid: Bool {
        !trimmedName.isEmpty
    }

    func apply(to client: Client, companyProfile: CompanyProfile?) {
        client.name = trimmedName
        client.contactPerson = contactPerson.trimmingCharacters(in: .whitespacesAndNewlines)
        client.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        client.phone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        client.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        client.kvkNumber = kvkNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        client.vatNumber = vatNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        client.paymentTermDays = max(0, paymentTermDays)
        client.defaultHourlyRate = defaultHourlyRate
        client.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if client.companyProfile == nil {
            client.companyProfile = companyProfile
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
