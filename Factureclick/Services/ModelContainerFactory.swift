//
//  ModelContainerFactory.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation
import SwiftData

enum ModelContainerFactory {
    static func makeShared(isStoredInMemoryOnly: Bool = false) -> ModelContainer {
        let schema = FactureclickPersistentSchema.makeCurrentSchema()

        do {
            return try makeSharedContainer(schema: schema, isStoredInMemoryOnly: isStoredInMemoryOnly)
        } catch {
            do {
                return try makeRecoveryContainer(schema: schema, isStoredInMemoryOnly: isStoredInMemoryOnly)
            } catch {
                fatalError("Unable to create SwiftData container: \(error.localizedDescription)")
            }
        }
    }

    private static func makeSharedContainer(schema: Schema, isStoredInMemoryOnly: Bool) throws -> ModelContainer {
        if isStoredInMemoryOnly {
            return try makeContainer(schema: schema, configuration: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        }

        let candidateURLs = orderedPersistentStoreURLs()
        let existingURLs = candidateURLs.filter { FileManager.default.fileExists(atPath: $0.path) }

        // Existing user stores must always be attempted first. We do not
        // silently delete or replace them as part of normal app startup.
        for url in existingURLs {
            do {
                return try makeContainer(
                    schema: schema,
                    configuration: ModelConfiguration(schema: schema, url: url)
                )
            } catch {
                continue
            }
        }

        guard existingURLs.isEmpty else {
            throw ModelContainerFactoryError.unableToOpenExistingStores(urls: existingURLs)
        }

        return try makeFreshContainer(schema: schema)
    }

    private static func makeContainer(schema: Schema, configuration: ModelConfiguration) throws -> ModelContainer {
        try ModelContainer(
            for: schema,
            migrationPlan: FactureclickMigrationPlan.self,
            configurations: [configuration]
        )
    }

    private static func makeRecoveryContainer(schema: Schema, isStoredInMemoryOnly: Bool) throws -> ModelContainer {
        if isStoredInMemoryOnly {
            return try makeContainer(schema: schema, configuration: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        }

        return try makeFreshContainer(schema: schema, preferredURL: recoveryPersistentStoreURL())
    }

    private static func makeFreshContainer(schema: Schema, preferredURL: URL? = nil) throws -> ModelContainer {
        let targetURL = preferredURL ?? canonicalPersistentStoreURL()
        return try makeContainer(
            schema: schema,
            configuration: ModelConfiguration(schema: schema, url: targetURL)
        )
    }

    private static func canonicalPersistentStoreURL() -> URL {
        let applicationSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? URL.documentsDirectory

        let directoryURL = applicationSupportURL.appendingPathComponent("Factureclick", isDirectory: true)
        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }

        return directoryURL.appendingPathComponent("Factureclick.store")
    }

    private static func recoveryPersistentStoreURL() -> URL {
        let baseDirectoryURL = canonicalPersistentStoreURL().deletingLastPathComponent()
        let timestamp = ISO8601DateFormatter().string(from: .now)
            .replacingOccurrences(of: ":", with: "-")
        return baseDirectoryURL.appendingPathComponent("Factureclick-recovery-\(timestamp).store")
    }

    private static func orderedPersistentStoreURLs() -> [URL] {
        let fileManager = FileManager.default
        let canonicalURL = canonicalPersistentStoreURL()
        let applicationSupportDirectory = canonicalURL.deletingLastPathComponent()
        let documentsDirectory = URL.documentsDirectory

        // Legacy compatibility only. Older builds relied on SwiftData's
        // default store naming, while newer builds used explicit filenames.
        let preferredCandidates = [
            canonicalURL,
            applicationSupportDirectory.appendingPathComponent("Factureclick-v2.store"),
            applicationSupportDirectory.appendingPathComponent("default.store"),
            documentsDirectory.appendingPathComponent("default.store")
        ]

        let discoveredCandidates = discoverLegacyStoreURLs(
            excluding: Set(preferredCandidates.map(\.standardizedFileURL))
        )

        return prioritizedStoreURLs(preferredCandidates + discoveredCandidates, fileManager: fileManager)
    }

    private static func discoverLegacyStoreURLs(excluding excludedURLs: Set<URL>) -> [URL] {
        let candidateDirectories = [
            canonicalPersistentStoreURL().deletingLastPathComponent(),
            URL.documentsDirectory
        ]

        let fileManager = FileManager.default
        var discoveredURLs: [URL] = []

        for directoryURL in candidateDirectories {
            guard let enumerator = fileManager.enumerator(
                at: directoryURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) else {
                continue
            }

            for case let fileURL as URL in enumerator {
                guard fileURL.pathExtension == "store" else {
                    continue
                }

                let standardizedURL = fileURL.standardizedFileURL
                guard !excludedURLs.contains(standardizedURL) else {
                    continue
                }

                discoveredURLs.append(fileURL)
            }
        }

        return discoveredURLs
    }

    private static func prioritizedStoreURLs(_ urls: [URL], fileManager: FileManager) -> [URL] {
        Array(Set(urls.map(\.standardizedFileURL))).sorted { lhs, rhs in
            let lhsExists = fileManager.fileExists(atPath: lhs.path)
            let rhsExists = fileManager.fileExists(atPath: rhs.path)

            if lhsExists != rhsExists {
                return lhsExists && !rhsExists
            }

            let lhsDate = modificationDate(for: lhs)
            let rhsDate = modificationDate(for: rhs)

            if lhsDate != rhsDate {
                return lhsDate > rhsDate
            }

            return lhs.lastPathComponent < rhs.lastPathComponent
        }
    }

    private static func modificationDate(for url: URL) -> Date {
        let fileManager = FileManager.default
        let attributes = try? fileManager.attributesOfItem(atPath: url.path)
        return (attributes?[.modificationDate] as? Date) ?? .distantPast
    }
}

private enum ModelContainerFactoryError: LocalizedError {
    case unableToOpenExistingStores(urls: [URL])

    var errorDescription: String? {
        switch self {
        case .unableToOpenExistingStores(let urls):
            let paths = urls.map(\.lastPathComponent).joined(separator: ", ")
            return "Unable to open existing SwiftData stores: \(paths)"
        }
    }
}
