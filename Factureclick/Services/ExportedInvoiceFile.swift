//
//  ExportedInvoiceFile.swift
//  Factureclick
//
//  Created by Codex on 03/05/2026.
//

import Foundation

struct ExportedInvoiceFile {
    let url: URL
    let createdAt: Date
    let fileSize: Int64

    var id: URL { url }
    var fileName: String { url.lastPathComponent }
}

extension ExportedInvoiceFile: Identifiable {}
