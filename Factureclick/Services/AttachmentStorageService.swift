//
//  AttachmentStorageService.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation
import UniformTypeIdentifiers

struct StoredAttachmentPayload {
    let fileName: String
    let localPath: String
    let contentType: String
    let fileSize: Int64
}

struct AttachmentStorageService {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func storeImportedFile(from sourceURL: URL) throws -> StoredAttachmentPayload {
        let didAccess = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        let attachmentsDirectory = try makeAttachmentsDirectory()
        let sanitizedName = sanitize(fileName: sourceURL.lastPathComponent)
        let destinationURL = attachmentsDirectory.appendingPathComponent("\(UUID().uuidString)-\(sanitizedName)")

        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }

        try fileManager.copyItem(at: sourceURL, to: destinationURL)

        let attributes = try? fileManager.attributesOfItem(atPath: destinationURL.path)
        let fileSize = (attributes?[.size] as? NSNumber)?.int64Value ?? 0
        let contentType = UTType(filenameExtension: destinationURL.pathExtension)?.identifier ?? "public.data"

        return StoredAttachmentPayload(
            fileName: sourceURL.lastPathComponent,
            localPath: destinationURL.path,
            contentType: contentType,
            fileSize: fileSize
        )
    }

    func deleteStoredFile(at localPath: String) {
        guard fileManager.fileExists(atPath: localPath) else { return }
        try? fileManager.removeItem(atPath: localPath)
    }

    private func makeAttachmentsDirectory() throws -> URL {
        let baseDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let directory = baseDirectory.appendingPathComponent("FactureclickAttachments", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func sanitize(fileName: String) -> String {
        fileName.replacingOccurrences(of: "/", with: "-")
    }
}
