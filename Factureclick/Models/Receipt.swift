//
//  Receipt.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import Foundation
import SwiftData

enum ReceiptCategory: String, CaseIterable, Identifiable, Codable {
    case travel
    case meals
    case supplies
    case equipment
    case lodging
    case software
    case parking
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .travel:
            "Travel"
        case .meals:
            "Meals"
        case .supplies:
            "Supplies"
        case .equipment:
            "Equipment"
        case .lodging:
            "Lodging"
        case .software:
            "Software"
        case .parking:
            "Parking"
        case .other:
            "Other"
        }
    }
}

enum ReceiptImportSource: String, Codable {
    case photoLibrary
    case camera
    case fileImport
    case unknown
}

enum ReceiptOCRStatus: String, Codable {
    case notRequested
    case pending
    case completed
}

@Model
final class Receipt {
    @Attribute(.unique) var id: UUID
    var date: Date
    var supplierName: String
    var amount: Double
    var vatAmount: Double?
    var categoryRawValue: String
    var notes: String
    var fileName: String
    var localPath: String
    var contentType: String
    var fileSize: Int64
    var importSourceRawValue: String
    var ocrStatusRawValue: String
    var createdAt: Date
    var updatedAt: Date

    var linkedClient: Client?
    var linkedWorkEntry: WorkEntry?
    var linkedInvoice: Invoice?

    init(
        id: UUID = UUID(),
        date: Date = .now,
        supplierName: String = "",
        amount: Double = 0,
        vatAmount: Double? = nil,
        category: ReceiptCategory = .other,
        linkedClient: Client? = nil,
        linkedWorkEntry: WorkEntry? = nil,
        linkedInvoice: Invoice? = nil,
        notes: String = "",
        fileName: String = "",
        localPath: String = "",
        contentType: String = "",
        fileSize: Int64 = 0,
        importSource: ReceiptImportSource = .unknown,
        ocrStatus: ReceiptOCRStatus = .notRequested,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.date = date
        self.supplierName = supplierName
        self.amount = amount
        self.vatAmount = vatAmount
        self.categoryRawValue = category.rawValue
        self.linkedClient = linkedClient
        self.linkedWorkEntry = linkedWorkEntry
        self.linkedInvoice = linkedInvoice
        self.notes = notes
        self.fileName = fileName
        self.localPath = localPath
        self.contentType = contentType
        self.fileSize = fileSize
        self.importSourceRawValue = importSource.rawValue
        self.ocrStatusRawValue = ocrStatus.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var category: ReceiptCategory {
        get { ReceiptCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }

    var importSource: ReceiptImportSource {
        get { ReceiptImportSource(rawValue: importSourceRawValue) ?? .unknown }
        set { importSourceRawValue = newValue.rawValue }
    }

    var ocrStatus: ReceiptOCRStatus {
        get { ReceiptOCRStatus(rawValue: ocrStatusRawValue) ?? .notRequested }
        set { ocrStatusRawValue = newValue.rawValue }
    }
}
