//
//  DataToolsViewModel.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation
import Observation
import SwiftData

@Observable
final class DataToolsViewModel {
    var selectedImportKind: DataImportKind = .clients
    var importPreview: ImportPreviewResult?
    var importSummary: ImportExecutionSummary?
    var errorMessage: String?
    var exportedFile: ExportedDataFile?

    private let service: DataImportExportService

    init(service: DataImportExportService = DataImportExportService()) {
        self.service = service
    }

    func previewImport(from url: URL) {
        do {
            importPreview = try service.previewImport(kind: selectedImportKind, from: url)
            importSummary = nil
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func applyImport(in context: ModelContext) {
        guard let importPreview else { return }
        do {
            importSummary = try service.executeImport(importPreview, in: context)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func exportBackup(clients: [Client], products: [Product], registrations: [WorkEntry], invoices: [Invoice]) {
        do {
            exportedFile = try service.exportBackup(
                clients: clients,
                products: products,
                registrations: registrations,
                invoices: invoices
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func exportRegistrations(_ registrations: [WorkEntry]) {
        do {
            exportedFile = try service.exportRegistrations(registrations)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func exportInvoices(_ invoices: [Invoice]) {
        do {
            exportedFile = try service.exportInvoices(invoices)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
