//
//  Attachment.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation
import SwiftData

@Model
final class Attachment {
    @Attribute(.unique) var id: UUID
    var fileName: String
    var localPath: String
    var contentType: String
    var fileSize: Int64
    var createdAt: Date

    var workEntry: WorkEntry?
    var invoice: Invoice?

    init(
        id: UUID = UUID(),
        fileName: String = "",
        localPath: String = "",
        contentType: String = "",
        fileSize: Int64 = 0,
        createdAt: Date = .now,
        workEntry: WorkEntry? = nil,
        invoice: Invoice? = nil
    ) {
        self.id = id
        self.fileName = fileName
        self.localPath = localPath
        self.contentType = contentType
        self.fileSize = fileSize
        self.createdAt = createdAt
        self.workEntry = workEntry
        self.invoice = invoice
    }
}
