//
//  ReceiptFormViewModel.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import Foundation
import Observation

struct ReceiptFileDraft {
    let fileName: String
    let localPath: String
    let contentType: String
    let fileSize: Int64
    let importSource: ReceiptImportSource
}

@Observable
final class ReceiptFormViewModel {
    var date: Date
    var supplierName: String
    var amount: Double
    var vatAmount: Double?
    var selectedCategory: ReceiptCategory
    var selectedClientID: UUID?
    var selectedWorkEntryID: UUID?
    var selectedInvoiceID: UUID?
    var notes: String
    var receiptFile: ReceiptFileDraft?
    var ocrStatus: ReceiptOCRStatus

    init(receipt: Receipt? = nil) {
        self.date = receipt?.date ?? .now
        self.supplierName = receipt?.supplierName ?? ""
        self.amount = receipt?.amount ?? 0
        self.vatAmount = receipt?.vatAmount
        self.selectedCategory = receipt?.category ?? .other
        self.selectedClientID = receipt?.linkedClient?.id
        self.selectedWorkEntryID = receipt?.linkedWorkEntry?.id
        self.selectedInvoiceID = receipt?.linkedInvoice?.id
        self.notes = receipt?.notes ?? ""
        self.ocrStatus = receipt?.ocrStatus ?? .notRequested

        if let receipt {
            self.receiptFile = ReceiptFileDraft(
                fileName: receipt.fileName,
                localPath: receipt.localPath,
                contentType: receipt.contentType,
                fileSize: receipt.fileSize,
                importSource: receipt.importSource
            )
        } else {
            self.receiptFile = nil
        }
    }

    var canSave: Bool {
        !trimmedSupplierName.isEmpty && amount > 0 && receiptFile != nil
    }

    func updateStoredFile(_ payload: StoredReceiptPayload, importSource: ReceiptImportSource) {
        receiptFile = ReceiptFileDraft(
            fileName: payload.fileName,
            localPath: payload.localPath,
            contentType: payload.contentType,
            fileSize: payload.fileSize,
            importSource: importSource
        )
        ocrStatus = .pending
    }

    func applyRecognizedReceipt(_ recognizedReceipt: RecognizedReceiptDraft) {
        if supplierName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let recognizedSupplierName = recognizedReceipt.supplierName {
            supplierName = recognizedSupplierName
        }

        if amount <= 0, let recognizedAmount = recognizedReceipt.amount {
            amount = recognizedAmount
        }

        if vatAmount == nil, let recognizedVATAmount = recognizedReceipt.vatAmount {
            vatAmount = recognizedVATAmount
        }

        if selectedCategory == .other, let recognizedCategory = recognizedReceipt.category {
            selectedCategory = recognizedCategory
        }

        if let recognizedDate = recognizedReceipt.date {
            date = recognizedDate
        }

        ocrStatus = .completed
    }

    func markOCRFailed() {
        ocrStatus = .notRequested
    }

    func apply(
        to receipt: Receipt,
        clients: [Client],
        workEntries: [WorkEntry],
        invoices: [Invoice]
    ) {
        let linkedClient = clients.first(where: { $0.id == selectedClientID })
        let linkedWorkEntry = workEntries.first(where: { $0.id == selectedWorkEntryID })
        let linkedInvoice = invoices.first(where: { $0.id == selectedInvoiceID })

        receipt.date = date
        receipt.supplierName = trimmedSupplierName
        receipt.amount = amount
        receipt.vatAmount = vatAmount.flatMap { $0 > 0 ? $0 : nil }
        receipt.category = selectedCategory
        receipt.linkedClient = linkedClient ?? linkedWorkEntry?.client ?? linkedInvoice?.client
        receipt.linkedWorkEntry = linkedWorkEntry
        receipt.linkedInvoice = linkedInvoice
        receipt.notes = trimmedNotes
        receipt.ocrStatus = ocrStatus
        receipt.updatedAt = .now

        if let receiptFile {
            receipt.fileName = receiptFile.fileName
            receipt.localPath = receiptFile.localPath
            receipt.contentType = receiptFile.contentType
            receipt.fileSize = receiptFile.fileSize
            receipt.importSource = receiptFile.importSource
        }
    }

    func selectLinkedWorkEntry(_ workEntryID: UUID?) {
        selectedWorkEntryID = workEntryID
        if workEntryID != nil {
            selectedInvoiceID = nil
        }
    }

    func selectLinkedInvoice(_ invoiceID: UUID?) {
        selectedInvoiceID = invoiceID
        if invoiceID != nil {
            selectedWorkEntryID = nil
        }
    }

    private var trimmedSupplierName: String {
        supplierName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedNotes: String {
        notes.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
