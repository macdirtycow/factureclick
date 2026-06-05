//
//  CustomerSignature.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import Foundation
import SwiftData

@Model
final class CustomerSignature {
    @Attribute(.unique) var id: UUID
    var signerName: String
    var dateSigned: Date
    var note: String
    var imageFileName: String
    var imageLocalPath: String
    var strokeFileName: String?
    var strokeLocalPath: String?
    var contentType: String
    var fileSize: Int64
    var strokeCount: Int
    var pointCount: Int
    var createdAt: Date
    var updatedAt: Date

    var quote: Quote?
    var invoice: Invoice?
    var workEntry: WorkEntry?

    init(
        id: UUID = UUID(),
        signerName: String = "",
        dateSigned: Date = .now,
        note: String = "",
        imageFileName: String,
        imageLocalPath: String,
        strokeFileName: String? = nil,
        strokeLocalPath: String? = nil,
        contentType: String = "public.png",
        fileSize: Int64 = 0,
        strokeCount: Int = 0,
        pointCount: Int = 0,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        quote: Quote? = nil,
        invoice: Invoice? = nil,
        workEntry: WorkEntry? = nil
    ) {
        self.id = id
        self.signerName = signerName
        self.dateSigned = dateSigned
        self.note = note
        self.imageFileName = imageFileName
        self.imageLocalPath = imageLocalPath
        self.strokeFileName = strokeFileName
        self.strokeLocalPath = strokeLocalPath
        self.contentType = contentType
        self.fileSize = fileSize
        self.strokeCount = strokeCount
        self.pointCount = pointCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.quote = quote
        self.invoice = invoice
        self.workEntry = workEntry
    }
}
