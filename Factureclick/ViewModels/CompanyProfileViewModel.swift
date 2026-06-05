//
//  CompanyProfileViewModel.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation
import Observation
import SwiftData

enum CompanyProfileValidationError: LocalizedError {
    case invalidIBAN
    case missingPayPalURL

    var errorDescription: String? {
        switch self {
        case .invalidIBAN:
            "The IBAN format looks invalid."
        case .missingPayPalURL:
            "PayPal is enabled, but the PayPal URL is empty."
        }
    }
}

@Observable
final class CompanyProfileViewModel {
    var existingProfileID: UUID?
    var name: String
    var ownerName: String
    var kvkNumber: String
    var vatNumber: String
    var iban: String
    var email: String
    var phone: String
    var address: String
    var logoData: Data?
    var defaultInvoiceText: String
    var defaultPaymentText: String
    var isPayPalPaymentEnabled: Bool
    var paypalPaymentURL: String
    var showSEPAPaymentQRCode: Bool
    var accentColor: String

    init(profile: CompanyProfile? = nil) {
        self.existingProfileID = nil
        self.name = ""
        self.ownerName = ""
        self.kvkNumber = ""
        self.vatNumber = ""
        self.iban = ""
        self.email = ""
        self.phone = ""
        self.address = ""
        self.logoData = nil
        self.defaultInvoiceText = "Thank you for your business."
        self.defaultPaymentText = ""
        self.isPayPalPaymentEnabled = false
        self.paypalPaymentURL = ""
        self.showSEPAPaymentQRCode = true
        self.accentColor = "#1F6FE5"
        load(profile: profile)
    }

    func load(profile: CompanyProfile?) {
        existingProfileID = profile?.id
        name = profile?.name ?? ""
        ownerName = profile?.ownerName ?? ""
        kvkNumber = profile?.kvkNumber ?? ""
        vatNumber = profile?.vatNumber ?? ""
        iban = profile?.iban ?? ""
        email = profile?.email ?? ""
        phone = profile?.phone ?? ""
        address = profile?.address ?? ""
        logoData = profile?.logoData
        defaultInvoiceText = profile?.defaultInvoiceText ?? "Thank you for your business."
        defaultPaymentText = profile?.defaultPaymentText ?? ""
        isPayPalPaymentEnabled = profile?.isPayPalPaymentEnabled ?? false
        paypalPaymentURL = profile?.paypalPaymentURL ?? ""
        showSEPAPaymentQRCode = profile?.showSEPAPaymentQRCode ?? true
        accentColor = profile?.accentColor ?? "#1F6FE5"
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func save(existingProfile: CompanyProfile?, in context: ModelContext) throws -> CompanyProfile {
        try validate()

        if let existingProfile {
            existingProfile.name = name.trimmed
            existingProfile.ownerName = ownerName.trimmed
            existingProfile.kvkNumber = kvkNumber.trimmed
            existingProfile.vatNumber = vatNumber.trimmed
            existingProfile.iban = iban.trimmed
            existingProfile.email = email.trimmed
            existingProfile.phone = phone.trimmed
            existingProfile.address = address.trimmed
            existingProfile.logoData = logoData
            existingProfile.defaultInvoiceText = defaultInvoiceText.trimmed
            existingProfile.defaultPaymentText = defaultPaymentText.trimmed
            existingProfile.isPayPalPaymentEnabled = isPayPalPaymentEnabled
            existingProfile.paypalPaymentURL = paypalPaymentURL.trimmed
            existingProfile.showSEPAPaymentQRCode = showSEPAPaymentQRCode
            existingProfile.accentColor = accentColor
            try context.save()
            return existingProfile
        } else {
            let profile = CompanyProfile(
                name: name.trimmed,
                ownerName: ownerName.trimmed,
                kvkNumber: kvkNumber.trimmed,
                vatNumber: vatNumber.trimmed,
                iban: iban.trimmed,
                email: email.trimmed,
                phone: phone.trimmed,
                address: address.trimmed,
                logoData: logoData,
                defaultInvoiceText: defaultInvoiceText.trimmed,
                defaultPaymentText: defaultPaymentText.trimmed,
                isPayPalPaymentEnabled: isPayPalPaymentEnabled,
                paypalPaymentURL: paypalPaymentURL.trimmed,
                showSEPAPaymentQRCode: showSEPAPaymentQRCode,
                accentColor: accentColor
            )
            context.insert(profile)
            try context.save()
            return profile
        }
    }

    private func validate() throws {
        let normalizedIBAN = iban
            .uppercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .joined()

        if !normalizedIBAN.isEmpty, !Self.isValidIBAN(normalizedIBAN) {
            throw CompanyProfileValidationError.invalidIBAN
        }

        if isPayPalPaymentEnabled, paypalPaymentURL.trimmed.isEmpty {
            throw CompanyProfileValidationError.missingPayPalURL
        }
    }

    private static func isValidIBAN(_ iban: String) -> Bool {
        guard iban.count >= 15, iban.count <= 34 else { return false }
        guard iban.allSatisfy({ $0.isNumber || $0.isLetter }) else { return false }

        let rearranged = iban.dropFirst(4) + iban.prefix(4)
        var remainder = 0

        for character in rearranged {
            let fragment: String
            if let digit = character.wholeNumberValue {
                fragment = String(digit)
            } else if let scalar = character.unicodeScalars.first {
                fragment = String(Int(scalar.value) - 55)
            } else {
                return false
            }

            for scalar in fragment.unicodeScalars {
                guard let digit = Int(String(scalar)) else { return false }
                remainder = (remainder * 10 + digit) % 97
            }
        }

        return remainder == 1
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
