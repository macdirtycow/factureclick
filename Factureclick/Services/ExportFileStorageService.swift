//
//  ExportFileStorageService.swift
//  Factureclick
//
//  Created by Codex on 23/08/2025.
//

import Foundation

struct ExportFileStorageService {
    private let directoryName = "Exports"

    func makeURL(fileName: String) throws -> URL {
        let baseDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directory = baseDirectory.appendingPathComponent(directoryName, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent(sanitizedFileName(fileName))
    }

    private func sanitizedFileName(_ fileName: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/:\\?%*|\"<>")
        let cleanedScalars = fileName.unicodeScalars.map { scalar in
            invalidCharacters.contains(scalar) ? "-" : Character(scalar)
        }
        let cleaned = String(cleanedScalars)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "Export.dat" : cleaned
    }
}
