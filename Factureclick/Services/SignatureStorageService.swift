//
//  SignatureStorageService.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import Foundation
import SwiftData
import UIKit
import UniformTypeIdentifiers

struct SignaturePoint: Codable, Hashable {
    var x: CGFloat
    var y: CGFloat
}

struct SignatureStroke: Codable, Hashable, Identifiable {
    var id: UUID
    var points: [SignaturePoint]

    init(id: UUID = UUID(), points: [SignaturePoint] = []) {
        self.id = id
        self.points = points
    }
}

struct SignatureDrawing: Codable, Hashable {
    var strokes: [SignatureStroke]

    init(strokes: [SignatureStroke] = []) {
        self.strokes = strokes
    }

    var isEmpty: Bool {
        strokes.allSatisfy { $0.points.isEmpty }
    }

    var strokeCount: Int {
        strokes.count
    }

    var pointCount: Int {
        strokes.reduce(into: 0) { $0 += $1.points.count }
    }
}

struct StoredSignaturePayload {
    let imageFileName: String
    let imageLocalPath: String
    let strokeFileName: String
    let strokeLocalPath: String
    let contentType: String
    let fileSize: Int64
    let strokeCount: Int
    let pointCount: Int
}

struct SignatureCaptureDraft {
    let signerName: String
    let dateSigned: Date
    let note: String
    let drawing: SignatureDrawing
}

struct SignatureStorageService {
    private let fileManager: FileManager
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func storeSignature(
        drawing: SignatureDrawing,
        fileNameStem: String
    ) throws -> StoredSignaturePayload {
        guard !drawing.isEmpty else {
            throw SignatureStorageError.emptySignature
        }

        let directory = try makeSignaturesDirectory()
        let baseName = sanitize(fileNameStem).isEmpty ? "signature" : sanitize(fileNameStem)
        let uniqueBaseName = "\(UUID().uuidString)-\(baseName)"
        let imageURL = directory.appendingPathComponent(uniqueBaseName).appendingPathExtension("png")
        let strokesURL = directory.appendingPathComponent(uniqueBaseName).appendingPathExtension("json")

        let imageData = try renderImageData(from: drawing)
        try imageData.write(to: imageURL, options: [.atomic])

        let drawingData = try encoder.encode(drawing)
        try drawingData.write(to: strokesURL, options: [.atomic])

        let attributes = try? fileManager.attributesOfItem(atPath: imageURL.path)
        let fileSize = (attributes?[.size] as? NSNumber)?.int64Value ?? Int64(imageData.count)

        return StoredSignaturePayload(
            imageFileName: imageURL.lastPathComponent,
            imageLocalPath: imageURL.path,
            strokeFileName: strokesURL.lastPathComponent,
            strokeLocalPath: strokesURL.path,
            contentType: UTType.png.identifier,
            fileSize: fileSize,
            strokeCount: drawing.strokeCount,
            pointCount: drawing.pointCount
        )
    }

    func loadDrawing(from localPath: String?) -> SignatureDrawing? {
        guard let localPath, !localPath.isEmpty else { return nil }
        guard let data = fileManager.contents(atPath: localPath) else { return nil }
        return try? decoder.decode(SignatureDrawing.self, from: data)
    }

    func deleteStoredSignature(imageLocalPath: String, strokeLocalPath: String?) {
        deleteStoredFile(at: imageLocalPath)
        if let strokeLocalPath {
            deleteStoredFile(at: strokeLocalPath)
        }
    }

    func deleteStoredFile(at localPath: String) {
        guard fileManager.fileExists(atPath: localPath) else { return }
        try? fileManager.removeItem(atPath: localPath)
    }

    private func renderImageData(from drawing: SignatureDrawing) throws -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 720, height: 280))
        let image = renderer.image { context in
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: renderer.format.bounds.size))

            let path = UIBezierPath()
            path.lineWidth = 2.5
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            UIColor.label.setStroke()

            for stroke in drawing.strokes where !stroke.points.isEmpty {
                let mappedPoints = stroke.points.map {
                    CGPoint(
                        x: max(0, min(1, $0.x)) * 720,
                        y: max(0, min(1, $0.y)) * 280
                    )
                }

                if let firstPoint = mappedPoints.first {
                    path.move(to: firstPoint)
                    for point in mappedPoints.dropFirst() {
                        path.addLine(to: point)
                    }
                    if mappedPoints.count == 1 {
                        path.addLine(to: firstPoint)
                    }
                }
            }

            path.stroke()
        }

        guard let data = image.pngData() else {
            throw SignatureStorageError.unableToEncodeSignature
        }

        return data
    }

    private func makeSignaturesDirectory() throws -> URL {
        let baseDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let directory = baseDirectory.appendingPathComponent("FactureclickSignatures", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func sanitize(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: " ", with: "-")
            .lowercased()
    }
}

enum SignatureStorageError: LocalizedError {
    case emptySignature
    case unableToEncodeSignature

    var errorDescription: String? {
        switch self {
        case .emptySignature:
            return "Add a signature before saving."
        case .unableToEncodeSignature:
            return "The signature could not be saved."
        }
    }
}

struct SignaturePersistenceService {
    private let storageService: SignatureStorageService

    init(storageService: SignatureStorageService = SignatureStorageService()) {
        self.storageService = storageService
    }

    func upsertSignature(
        _ draft: SignatureCaptureDraft,
        for quote: Quote,
        in context: ModelContext
    ) throws {
        let signature = quote.customerSignature ?? CustomerSignature(imageFileName: "", imageLocalPath: "")
        try replaceStoredData(for: signature, with: draft, fileNameStem: "quote-\(quote.quoteNumber)", in: context)
        signature.quote = quote
        signature.invoice = nil
        signature.workEntry = nil
        quote.customerSignature = signature
    }

    func upsertSignature(
        _ draft: SignatureCaptureDraft,
        for invoice: Invoice,
        in context: ModelContext
    ) throws {
        let signature = invoice.customerSignature ?? CustomerSignature(imageFileName: "", imageLocalPath: "")
        try replaceStoredData(for: signature, with: draft, fileNameStem: "invoice-\(invoice.invoiceNumber)", in: context)
        signature.quote = nil
        signature.invoice = invoice
        signature.workEntry = nil
        invoice.customerSignature = signature
    }

    func upsertSignature(
        _ draft: SignatureCaptureDraft,
        for workEntry: WorkEntry,
        in context: ModelContext
    ) throws {
        let signature = workEntry.customerSignature ?? CustomerSignature(imageFileName: "", imageLocalPath: "")
        try replaceStoredData(for: signature, with: draft, fileNameStem: "work-entry-\(workEntry.id.uuidString)", in: context)
        signature.quote = nil
        signature.invoice = nil
        signature.workEntry = workEntry
        workEntry.customerSignature = signature
    }

    func deleteSignature(for quote: Quote, in context: ModelContext) throws {
        try delete(signature: quote.customerSignature, in: context)
        quote.customerSignature = nil
    }

    func deleteSignature(for invoice: Invoice, in context: ModelContext) throws {
        try delete(signature: invoice.customerSignature, in: context)
        invoice.customerSignature = nil
    }

    func deleteSignature(for workEntry: WorkEntry, in context: ModelContext) throws {
        try delete(signature: workEntry.customerSignature, in: context)
        workEntry.customerSignature = nil
    }

    private func replaceStoredData(
        for signature: CustomerSignature,
        with draft: SignatureCaptureDraft,
        fileNameStem: String,
        in context: ModelContext
    ) throws {
        storageService.deleteStoredSignature(
            imageLocalPath: signature.imageLocalPath,
            strokeLocalPath: signature.strokeLocalPath
        )

        let stored = try storageService.storeSignature(drawing: draft.drawing, fileNameStem: fileNameStem)
        signature.signerName = draft.signerName
        signature.dateSigned = draft.dateSigned
        signature.note = draft.note
        signature.imageFileName = stored.imageFileName
        signature.imageLocalPath = stored.imageLocalPath
        signature.strokeFileName = stored.strokeFileName
        signature.strokeLocalPath = stored.strokeLocalPath
        signature.contentType = stored.contentType
        signature.fileSize = stored.fileSize
        signature.strokeCount = stored.strokeCount
        signature.pointCount = stored.pointCount
        signature.updatedAt = .now

        if signature.modelContext == nil {
            context.insert(signature)
        }

        try context.save()
    }

    private func delete(signature: CustomerSignature?, in context: ModelContext) throws {
        guard let signature else { return }
        storageService.deleteStoredSignature(
            imageLocalPath: signature.imageLocalPath,
            strokeLocalPath: signature.strokeLocalPath
        )
        context.delete(signature)
        try context.save()
    }
}
