//
//  WorkEntryFormViewModel.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation
import Observation
import SwiftData

enum WorkEntryFormError: LocalizedError {
    case missingClient

    var errorDescription: String? {
        switch self {
        case .missingClient:
            "Selecteer eerst een klant voordat je de registratie opslaat."
        }
    }
}

@Observable
final class WorkEntryFormViewModel {
    var selectedDate: Date
    var selectedClientID: UUID?
    var selectedProductID: UUID?
    var invoiceBasedOnHours: Bool
    var hoursWorked: Double
    var useCustomHourlyRate: Bool
    var customHourlyRate: Double
    var quantity: Double
    var notes: String
    var includeInInvoice: Bool
    var selectedCollaborationRuleID: UUID?
    var pendingAttachmentURLs: [URL]

    private let attachmentStorageService: AttachmentStorageService

    init(
        selectedDate: Date,
        attachmentStorageService: AttachmentStorageService = AttachmentStorageService()
    ) {
        self.selectedDate = selectedDate
        self.invoiceBasedOnHours = true
        self.hoursWorked = 1
        self.useCustomHourlyRate = false
        self.customHourlyRate = 0
        self.quantity = 1
        self.notes = ""
        self.includeInInvoice = true
        self.selectedCollaborationRuleID = nil
        self.pendingAttachmentURLs = []
        self.attachmentStorageService = attachmentStorageService
    }

    func selectedProduct(from products: [Product]) -> Product? {
        guard let selectedProductID else { return nil }
        return products.first(where: { $0.id == selectedProductID })
    }

    var billsByHours: Bool {
        invoiceBasedOnHours
    }

    func setBillingByHours(_ isEnabled: Bool) {
        invoiceBasedOnHours = isEnabled

        if isEnabled {
            selectedProductID = nil
            quantity = 1
            if hoursWorked <= 0 {
                hoursWorked = 1
            }
        }
    }

    func setSelectedProductID(_ productID: UUID?, products: [Product]) {
        selectedProductID = productID
        invoiceBasedOnHours = productID == nil

        guard let productID,
              let product = products.first(where: { $0.id == productID }) else {
            quantity = 1
            return
        }

        if product.unitType == .hour {
            if hoursWorked <= 0 {
                hoursWorked = 1
            }
            quantity = 1
        } else {
            hoursWorked = 0
            quantity = max(quantity, 1)
        }
    }

    func canSave(with products: [Product]) -> Bool {
        guard selectedClientID != nil else { return false }

        if billsByHours {
            return hoursWorked > 0
        }

        guard let product = selectedProduct(from: products) else { return false }

        if product.unitType != .hour {
            return quantity > 0
        }

        return hoursWorked > 0
    }

    func save(
        in context: ModelContext,
        clients: [Client],
        products: [Product],
        collaborationRules: [CollaborationRule],
        activeCompanyProfile: CompanyProfile?
    ) throws {
        guard let selectedClientID,
              let client = clients.first(where: { $0.id == selectedClientID }) else {
            throw WorkEntryFormError.missingClient
        }

        let companyProfile = CompanyProfileSelectionService().resolveWorkEntryProfile(
            explicitProfile: nil,
            client: client,
            fallbackActiveProfile: activeCompanyProfile
        )
        let product = products.first(where: { $0.id == selectedProductID })
        let collaborationRule = collaborationRules.first(where: { $0.id == selectedCollaborationRuleID })
        let workEntry = WorkEntry(
            date: selectedDate,
            client: client,
            hoursWorked: hoursWorked,
            hourlyRateOverride: useCustomHourlyRate ? customHourlyRate : nil,
            product: product,
            quantity: quantity,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            includeInInvoice: includeInInvoice,
            isInvoiced: false,
            collaborationRule: collaborationRule,
            companyProfile: companyProfile
        )

        context.insert(workEntry)
        for url in pendingAttachmentURLs {
            let stored = try attachmentStorageService.storeImportedFile(from: url)
            let attachment = Attachment(
                fileName: stored.fileName,
                localPath: stored.localPath,
                contentType: stored.contentType,
                fileSize: stored.fileSize,
                workEntry: workEntry
            )
            context.insert(attachment)
        }
        try context.save()
    }
}
