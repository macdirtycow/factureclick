//
//  DataImportExportService.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation
import SwiftData

enum DataImportKind: String, CaseIterable, Identifiable {
    case clients
    case products

    var id: String { rawValue }

    var title: String {
        switch self {
        case .clients:
            "Clients CSV"
        case .products:
            "Products CSV"
        }
    }
}

struct ImportPreviewItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let isValid: Bool
    let validationMessage: String?
    let payload: ImportPayload
}

enum ImportPayload {
    case client(ClientImportRecord)
    case product(ProductImportRecord)
}

struct ClientImportRecord {
    let name: String
    let contactPerson: String
    let email: String
    let phone: String
    let address: String
    let kvkNumber: String
    let vatNumber: String
    let paymentTermDays: Int
    let defaultHourlyRate: Double
    let notes: String
}

struct ProductImportRecord {
    let name: String
    let description: String
    let price: Double
    let vatRate: Double
    let unitType: ProductUnitType
}

struct ImportPreviewResult {
    let kind: DataImportKind
    let sourceFileName: String
    let items: [ImportPreviewItem]
    let errors: [String]
}

struct ImportExecutionSummary {
    let successCount: Int
    let errorMessages: [String]
}

struct ExportedDataFile {
    let url: URL
    let title: String
}

struct AppBackupSnapshot: Codable {
    let exportedAt: Date
    let clients: [ClientBackupRecord]
    let products: [ProductBackupRecord]
    let registrations: [RegistrationBackupRecord]
    let invoices: [InvoiceBackupRecord]
}

struct ClientBackupRecord: Codable {
    let name: String
    let contactPerson: String
    let email: String
    let phone: String
    let address: String
    let kvkNumber: String
    let vatNumber: String
    let paymentTermDays: Int
    let defaultHourlyRate: Double
    let notes: String
}

struct ProductBackupRecord: Codable {
    let name: String
    let description: String
    let price: Double
    let vatRate: Double
    let unitType: String
}

struct RegistrationBackupRecord: Codable {
    let date: Date
    let clientName: String
    let productName: String?
    let hoursWorked: Double
    let quantity: Double
    let notes: String
    let includeInInvoice: Bool
    let isInvoiced: Bool
}

struct InvoiceBackupRecord: Codable {
    let invoiceNumber: String
    let clientName: String
    let date: Date
    let dueDate: Date
    let status: String
    let paidDate: Date?
    let totalAmount: Double
    let vatAmount: Double
    let notes: String
}

struct DataImportExportService {
    private let storageDirectoryName = "FactureclickExports"

    func previewImport(kind: DataImportKind, from fileURL: URL) throws -> ImportPreviewResult {
        let content = try readSecurityScopedText(from: fileURL)
        let rows = parseCSV(content)
        guard let header = rows.first else {
            return ImportPreviewResult(kind: kind, sourceFileName: fileURL.lastPathComponent, items: [], errors: ["The CSV file is empty."])
        }

        let records = Array(rows.dropFirst())
        switch kind {
        case .clients:
            return previewClients(records: records, header: header, sourceFileName: fileURL.lastPathComponent)
        case .products:
            return previewProducts(records: records, header: header, sourceFileName: fileURL.lastPathComponent)
        }
    }

    func executeImport(_ result: ImportPreviewResult, in context: ModelContext) throws -> ImportExecutionSummary {
        var successCount = 0
        let errorMessages = result.errors

        for item in result.items where item.isValid {
            switch item.payload {
            case .client(let record):
                let client = Client(
                    name: record.name,
                    contactPerson: record.contactPerson,
                    email: record.email,
                    phone: record.phone,
                    address: record.address,
                    kvkNumber: record.kvkNumber,
                    vatNumber: record.vatNumber,
                    paymentTermDays: record.paymentTermDays,
                    defaultHourlyRate: record.defaultHourlyRate,
                    notes: record.notes
                )
                context.insert(client)
                successCount += 1
            case .product(let record):
                let product = Product(
                    name: record.name,
                    description: record.description,
                    price: record.price,
                    vatRate: record.vatRate,
                    unitType: record.unitType
                )
                context.insert(product)
                successCount += 1
            }
        }

        try context.save()

        return ImportExecutionSummary(successCount: successCount, errorMessages: errorMessages)
    }

    func exportBackup(
        clients: [Client],
        products: [Product],
        registrations: [WorkEntry],
        invoices: [Invoice]
    ) throws -> ExportedDataFile {
        let snapshot = AppBackupSnapshot(
            exportedAt: .now,
            clients: clients.map {
                ClientBackupRecord(
                    name: $0.name,
                    contactPerson: $0.contactPerson,
                    email: $0.email,
                    phone: $0.phone,
                    address: $0.address,
                    kvkNumber: $0.kvkNumber,
                    vatNumber: $0.vatNumber,
                    paymentTermDays: $0.paymentTermDays,
                    defaultHourlyRate: $0.defaultHourlyRate,
                    notes: $0.notes
                )
            },
            products: products.map {
                ProductBackupRecord(
                    name: $0.name,
                    description: $0.description,
                    price: $0.price,
                    vatRate: $0.vatRate,
                    unitType: $0.unitType.rawValue
                )
            },
            registrations: registrations.map {
                RegistrationBackupRecord(
                    date: $0.date,
                    clientName: $0.client.name,
                    productName: $0.product?.name,
                    hoursWorked: $0.hoursWorked,
                    quantity: $0.quantity,
                    notes: $0.notes,
                    includeInInvoice: $0.includeInInvoice,
                    isInvoiced: $0.isInvoiced
                )
            },
            invoices: invoices.map {
                InvoiceBackupRecord(
                    invoiceNumber: $0.invoiceNumber,
                    clientName: $0.client.name,
                    date: $0.date,
                    dueDate: $0.dueDate,
                    status: $0.status.rawValue,
                    paidDate: $0.paidDate,
                    totalAmount: $0.totalAmount,
                    vatAmount: $0.vatAmount,
                    notes: $0.notes
                )
            }
        )

        let url = try makeExportURL(fileName: "\(AppBrand.displayName)-Backup-\(timestamp()).json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(snapshot).write(to: url, options: .atomic)
        return ExportedDataFile(url: url, title: "Backup export")
    }

    func exportRegistrations(_ registrations: [WorkEntry]) throws -> ExportedDataFile {
        let header = ["date", "client", "product", "hoursWorked", "quantity", "notes", "includeInInvoice", "isInvoiced"]
        let rows = registrations.map {
            [
                ISO8601DateFormatter().string(from: $0.date),
                $0.client.name,
                $0.product?.name ?? "",
                String($0.hoursWorked),
                String($0.quantity),
                $0.notes,
                String($0.includeInInvoice),
                String($0.isInvoiced)
            ]
        }
        return try writeCSV(rows: [header] + rows, fileName: "\(AppBrand.displayName)-Registrations-\(timestamp()).csv", title: "Registrations export")
    }

    func exportInvoices(_ invoices: [Invoice]) throws -> ExportedDataFile {
        let header = ["invoiceNumber", "client", "date", "dueDate", "status", "paidDate", "totalAmount", "vatAmount", "notes"]
        let formatter = ISO8601DateFormatter()
        let rows = invoices.map {
            [
                $0.invoiceNumber,
                $0.client.name,
                formatter.string(from: $0.date),
                formatter.string(from: $0.dueDate),
                $0.status.rawValue,
                $0.paidDate.map(formatter.string(from:)) ?? "",
                String($0.totalAmount),
                String($0.vatAmount),
                $0.notes
            ]
        }
        return try writeCSV(rows: [header] + rows, fileName: "\(AppBrand.displayName)-Invoices-\(timestamp()).csv", title: "Invoices export")
    }

    private func previewClients(records: [[String]], header: [String], sourceFileName: String) -> ImportPreviewResult {
        let mappedHeader = header.map { $0.lowercased() }
        var items: [ImportPreviewItem] = []
        var errors: [String] = []

        for (index, row) in records.enumerated() {
            guard row.count == header.count else {
                errors.append("Row \(index + 2): column count does not match header.")
                continue
            }

            func value(_ key: String) -> String {
                guard let index = mappedHeader.firstIndex(of: key) else { return "" }
                return row[index].trimmingCharacters(in: .whitespacesAndNewlines)
            }

            let paymentTerm = Int(value("paymenttermdays")) ?? 30
            let hourlyRate = Double(value("defaulthourlyrate")) ?? 0
            let record = ClientImportRecord(
                name: value("name"),
                contactPerson: value("contactperson"),
                email: value("email"),
                phone: value("phone"),
                address: value("address"),
                kvkNumber: value("kvknumber"),
                vatNumber: value("vatnumber"),
                paymentTermDays: paymentTerm,
                defaultHourlyRate: hourlyRate,
                notes: value("notes")
            )
            let validationMessage = validate(clientRecord: record)
            items.append(
                ImportPreviewItem(
                    title: record.name.isEmpty ? "Unnamed client" : record.name,
                    subtitle: [record.contactPerson, record.email].filter { !$0.isEmpty }.joined(separator: " · "),
                    isValid: validationMessage == nil,
                    validationMessage: validationMessage,
                    payload: .client(record)
                )
            )
        }

        return ImportPreviewResult(kind: .clients, sourceFileName: sourceFileName, items: items, errors: errors)
    }

    private func previewProducts(records: [[String]], header: [String], sourceFileName: String) -> ImportPreviewResult {
        let mappedHeader = header.map { $0.lowercased() }
        var items: [ImportPreviewItem] = []
        var errors: [String] = []

        for (index, row) in records.enumerated() {
            guard row.count == header.count else {
                errors.append("Row \(index + 2): column count does not match header.")
                continue
            }

            func value(_ key: String) -> String {
                guard let index = mappedHeader.firstIndex(of: key) else { return "" }
                return row[index].trimmingCharacters(in: .whitespacesAndNewlines)
            }

            let record = ProductImportRecord(
                name: value("name"),
                description: value("description"),
                price: Double(value("price")) ?? -1,
                vatRate: Double(value("vatrate")) ?? -1,
                unitType: ProductUnitType(rawValue: value("unittype").lowercased()) ?? .hour
            )
            let validationMessage = validate(productRecord: record, rawUnitType: value("unittype"))
            items.append(
                ImportPreviewItem(
                    title: record.name.isEmpty ? "Unnamed product" : record.name,
                    subtitle: "\(record.unitType.displayName) · \(record.price.formatted(.number.precision(.fractionLength(0...2))))",
                    isValid: validationMessage == nil,
                    validationMessage: validationMessage,
                    payload: .product(record)
                )
            )
        }

        return ImportPreviewResult(kind: .products, sourceFileName: sourceFileName, items: items, errors: errors)
    }

    private func validate(clientRecord: ClientImportRecord) -> String? {
        if clientRecord.name.isEmpty {
            return "Client name is required."
        }
        if clientRecord.paymentTermDays < 0 {
            return "Payment term must be zero or higher."
        }
        if clientRecord.defaultHourlyRate < 0 {
            return "Hourly rate must be zero or higher."
        }
        return nil
    }

    private func validate(productRecord: ProductImportRecord, rawUnitType: String) -> String? {
        if productRecord.name.isEmpty {
            return "Product name is required."
        }
        if productRecord.price < 0 {
            return "Price must be zero or higher."
        }
        if productRecord.vatRate < 0 {
            return "VAT rate must be zero or higher."
        }
        if ProductUnitType(rawValue: rawUnitType.lowercased()) == nil {
            return "Unit type must be one of: hour, piece, day, fixed."
        }
        return nil
    }

    private func writeCSV(rows: [[String]], fileName: String, title: String) throws -> ExportedDataFile {
        let content = rows.map { row in
            row.map(csvEscaped).joined(separator: ",")
        }.joined(separator: "\n")

        let url = try makeExportURL(fileName: fileName)
        try Data(content.utf8).write(to: url, options: .atomic)
        return ExportedDataFile(url: url, title: title)
    }

    private func csvEscaped(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(",") || escaped.contains("\n") || escaped.contains("\"") {
            return "\"\(escaped)\""
        }
        return escaped
    }

    private func parseCSV(_ content: String) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var isInsideQuotes = false
        let characters = Array(content)
        var index = 0

        while index < characters.count {
            let character = characters[index]

            if character == "\"" {
                if isInsideQuotes, index + 1 < characters.count, characters[index + 1] == "\"" {
                    field.append("\"")
                    index += 1
                } else {
                    isInsideQuotes.toggle()
                }
            } else if character == "," && !isInsideQuotes {
                row.append(field)
                field = ""
            } else if (character == "\n" || character == "\r") && !isInsideQuotes {
                if character == "\r", index + 1 < characters.count, characters[index + 1] == "\n" {
                    index += 1
                }
                row.append(field)
                if !(row.count == 1 && row[0].isEmpty) {
                    rows.append(row)
                }
                row = []
                field = ""
            } else {
                field.append(character)
            }

            index += 1
        }

        if !field.isEmpty || !row.isEmpty {
            row.append(field)
            rows.append(row)
        }

        return rows
    }

    private func readSecurityScopedText(from url: URL) throws -> String {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let data = try Data(contentsOf: url)
        guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .unicode) else {
            throw CocoaError(.fileReadInapplicableStringEncoding)
        }
        return text
    }

    private func makeExportURL(fileName: String) throws -> URL {
        let baseDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directory = baseDirectory.appendingPathComponent(storageDirectoryName, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent(fileName)
    }

    private func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        return formatter.string(from: .now)
    }
}
