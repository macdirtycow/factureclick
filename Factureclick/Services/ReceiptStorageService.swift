//
//  ReceiptStorageService.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import Foundation
import UIKit
import UniformTypeIdentifiers

struct StoredReceiptPayload {
    let fileName: String
    let localPath: String
    let contentType: String
    let fileSize: Int64
}

struct ReceiptOCRPreparationDraft {
    let imageURL: URL
    let fileName: String
    let contentType: String
}

struct ReceiptStorageService {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func storeImportedImage(from sourceURL: URL) throws -> StoredReceiptPayload {
        let didAccess = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        let imageData = try Data(contentsOf: sourceURL)
        let contentType = UTType(filenameExtension: sourceURL.pathExtension) ?? .jpeg
        let fileName = sourceURL.lastPathComponent.isEmpty ? "receipt.\(contentType.preferredFilenameExtension ?? "jpg")" : sourceURL.lastPathComponent
        return try storeImageData(imageData, fileName: fileName, contentType: contentType)
    }

    func storePhotoLibraryImage(data: Data, suggestedFileName: String = "photo-library-receipt.jpg") throws -> StoredReceiptPayload {
        try storeImageData(data, fileName: suggestedFileName, contentType: .jpeg)
    }

    func storeCapturedImage(_ image: UIImage) throws -> StoredReceiptPayload {
        guard let imageData = image.jpegData(compressionQuality: 0.82) else {
            throw ReceiptStorageError.unableToEncodeImage
        }

        return try storeImageData(
            imageData,
            fileName: "camera-receipt-\(UUID().uuidString).jpg",
            contentType: .jpeg
        )
    }

    func deleteStoredFile(at localPath: String) {
        guard fileManager.fileExists(atPath: localPath) else { return }
        try? fileManager.removeItem(atPath: localPath)
    }

    func makeOCRPreparationDraft(for payload: StoredReceiptPayload) -> ReceiptOCRPreparationDraft {
        ReceiptOCRPreparationDraft(
            imageURL: URL(fileURLWithPath: payload.localPath),
            fileName: payload.fileName,
            contentType: payload.contentType
        )
    }

    private func storeImageData(
        _ data: Data,
        fileName: String,
        contentType: UTType
    ) throws -> StoredReceiptPayload {
        guard !data.isEmpty else {
            throw ReceiptStorageError.emptyImageData
        }

        let receiptsDirectory = try makeReceiptsDirectory()
        let sanitizedName = sanitize(fileName: NSString(string: fileName).deletingPathExtension)
        let fileExtension = contentType.preferredFilenameExtension ?? "jpg"
        let destinationURL = receiptsDirectory.appendingPathComponent("\(UUID().uuidString)-\(sanitizedName)")
            .appendingPathExtension(fileExtension)

        try data.write(to: destinationURL, options: [.atomic])

        let attributes = try? fileManager.attributesOfItem(atPath: destinationURL.path)
        let fileSize = (attributes?[.size] as? NSNumber)?.int64Value ?? Int64(data.count)

        return StoredReceiptPayload(
            fileName: fileName,
            localPath: destinationURL.path,
            contentType: contentType.identifier,
            fileSize: fileSize
        )
    }

    private func makeReceiptsDirectory() throws -> URL {
        let baseDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let directory = baseDirectory.appendingPathComponent("FactureclickReceipts", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func sanitize(fileName: String) -> String {
        fileName
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: " ", with: "-")
    }
}

enum ReceiptStorageError: LocalizedError {
    case emptyImageData
    case unableToEncodeImage

    var errorDescription: String? {
        switch self {
        case .emptyImageData:
            "The selected image could not be loaded."
        case .unableToEncodeImage:
            "The captured receipt image could not be saved."
        }
    }
}
