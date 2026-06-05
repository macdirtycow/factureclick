//
//  QuoteDOCXExportService.swift
//  Factureclick
//
//  Created by Codex on 23/08/2025.
//

import Foundation

struct QuoteDOCXExportService {
    private let pricingService = QuotePricingService()

    func export(
        quote: Quote,
        companyProfile: CompanyProfile?
    ) throws -> ExportedInvoiceFile {
        let totals = pricingService.makeTotals(
            lines: quote.lines.map {
                QuoteLineDraft(
                    id: $0.id,
                    linkedProductID: $0.linkedProduct?.id,
                    description: $0.description,
                    quantity: $0.quantity,
                    unitPrice: $0.unitPrice,
                    vatRate: $0.vatRate
                )
            }
        )
        let vatBreakdown = makeVATBreakdown(from: quote.lines)
        let files = [
            DOCXFile(path: "[Content_Types].xml", data: Data(contentTypesXML.utf8)),
            DOCXFile(path: "_rels/.rels", data: Data(rootRelationshipsXML.utf8)),
            DOCXFile(path: "docProps/app.xml", data: Data(appPropertiesXML.utf8)),
            DOCXFile(path: "docProps/core.xml", data: Data(corePropertiesXML(title: "Quote \(quote.quoteNumber)").utf8)),
            DOCXFile(path: "word/_rels/document.xml.rels", data: Data(documentRelationshipsXML.utf8)),
            DOCXFile(
                path: "word/document.xml",
                data: Data(documentXML(quote: quote, companyProfile: companyProfile, totals: totals, vatBreakdown: vatBreakdown).utf8)
            )
        ]

        let url = makeExportURL(quoteNumber: quote.quoteNumber)
        try SimpleZipWriter.write(files: files, to: url)

        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = (attributes?[.size] as? NSNumber)?.int64Value ?? 0
        return ExportedInvoiceFile(url: url, createdAt: .now, fileSize: fileSize)
    }

    private func makeExportURL(quoteNumber: String) -> URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return directory.appendingPathComponent("Quote-\(quoteNumber).docx")
    }

    private func makeVATBreakdown(from lines: [QuoteLine]) -> [(rate: Double, amount: Double)] {
        let grouped = Dictionary(grouping: lines, by: \.vatRate)
        return grouped
            .map { rate, groupedLines in
                let amount = groupedLines.reduce(0) { $0 + (($1.quantity * $1.unitPrice) * (rate / 100)) }
                return (rate, amount)
            }
            .sorted { $0.rate < $1.rate }
    }

    private var contentTypesXML: String {
        """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
            <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
            <Default Extension="xml" ContentType="application/xml"/>
            <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
            <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
            <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
        </Types>
        """
    }

    private var rootRelationshipsXML: String {
        """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
            <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
            <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
            <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
        </Relationships>
        """
    }

    private var appPropertiesXML: String {
        """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
            <Application>Factureclick</Application>
        </Properties>
        """
    }

    private func corePropertiesXML(title: String) -> String {
        let now = ISO8601DateFormatter().string(from: .now)
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <dc:title>\(title.xmlEscaped)</dc:title>
            <dc:creator>Factureclick</dc:creator>
            <cp:lastModifiedBy>Factureclick</cp:lastModifiedBy>
            <dcterms:created xsi:type="dcterms:W3CDTF">\(now)</dcterms:created>
            <dcterms:modified xsi:type="dcterms:W3CDTF">\(now)</dcterms:modified>
        </cp:coreProperties>
        """
    }

    private var documentRelationshipsXML: String {
        """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"/>
        """
    }

    private func documentXML(
        quote: Quote,
        companyProfile: CompanyProfile?,
        totals: QuoteTotals,
        vatBreakdown: [(rate: Double, amount: Double)]
    ) -> String {
        let companyLines = [
            companyProfile?.name,
            companyProfile?.ownerName,
            companyProfile?.address,
            companyProfile?.email,
            companyProfile?.phone,
            companyProfile?.kvkNumber.isEmpty == false ? "KVK: \(companyProfile!.kvkNumber)" : nil,
            companyProfile?.vatNumber.isEmpty == false ? "VAT: \(companyProfile!.vatNumber)" : nil,
            companyProfile?.iban.isEmpty == false ? "IBAN: \(companyProfile!.iban)" : nil
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }

        let clientLines = [
            quote.client.name,
            quote.client.contactPerson,
            quote.client.address,
            quote.client.email,
            quote.client.phone,
            quote.client.kvkNumber.isEmpty ? nil : "KVK: \(quote.client.kvkNumber)",
            quote.client.vatNumber.isEmpty ? nil : "VAT: \(quote.client.vatNumber)"
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }

        let messageLine = companyProfile?.defaultInvoiceText.isEmpty == false
            ? companyProfile!.defaultInvoiceText
            : "Please contact us if you would like to accept this quote."

        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <w:document xmlns:wpc="http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas" xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:wp14="http://schemas.microsoft.com/office/word/2010/wordprocessingDrawing" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:w10="urn:schemas-microsoft-com:office:word" xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" mc:Ignorable="w14 wp14">
            <w:body>
                \(heading("Quote", size: 32))
                \(paragraph(companyProfile?.name.isEmpty == false ? companyProfile!.name : "Factureclick", bold: true))
                \(paragraphs(from: companyLines))
                \(paragraph(""))
                \(heading("Quote For", size: 24))
                \(paragraphs(from: clientLines))
                \(paragraph(""))
                \(heading("Quote Details", size: 24))
                \(paragraph("Quote number: \(quote.quoteNumber)"))
                \(paragraph("Quote date: \(quote.date.formatted(date: .abbreviated, time: .omitted))"))
                \(paragraph("Expiry date: \(quote.expiryDate.formatted(date: .abbreviated, time: .omitted))"))
                \(paragraph("Status: \(quote.status.displayName)"))
                \(paragraph(""))
                \(heading("Quote Lines", size: 24))
                \(table(
                    rows: [["Description", "Qty", "Unit", "Total"]] + quote.lines.map { line in
                        [
                            line.description,
                            line.quantity.formatted(.number.precision(.fractionLength(0...2))),
                            currency(line.unitPrice),
                            currency(line.quantity * line.unitPrice)
                        ]
                    }
                ))
                \(paragraph(""))
                \(heading("VAT Breakdown", size: 24))
                \(table(
                    rows: [["Rate", "VAT Amount"]] + vatBreakdown.map {
                        [
                            "\($0.rate.formatted(.number.precision(.fractionLength(0...2))))%",
                            currency($0.amount)
                        ]
                    }
                ))
                \(paragraph(""))
                \(heading("Totals", size: 24))
                \(paragraph("Subtotal: \(currency(totals.subtotal))"))
                \(paragraph("VAT: \(currency(totals.vat))"))
                \(paragraph("Total: \(currency(totals.total))", bold: true))
                \(paragraph(""))
                \(heading("Terms", size: 24))
                \(paragraph("Valid until \(quote.expiryDate.formatted(date: .abbreviated, time: .omitted))."))
                \(paragraph(messageLine))
                <w:sectPr>
                    <w:pgSz w:w="12240" w:h="15840"/>
                    <w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" w:header="720" w:footer="720" w:gutter="0"/>
                </w:sectPr>
            </w:body>
        </w:document>
        """
    }

    private func heading(_ text: String, size: Int) -> String {
        paragraph(text, bold: true, size: size)
    }

    private func paragraph(_ text: String, bold: Bool = false, size: Int = 22) -> String {
        let boldTag = bold ? "<w:b/>" : ""
        let safeText = text.isEmpty ? " " : text.xmlEscaped
        return """
        <w:p>
            <w:r>
                <w:rPr>\(boldTag)<w:sz w:val="\(size)"/></w:rPr>
                <w:t xml:space="preserve">\(safeText)</w:t>
            </w:r>
        </w:p>
        """
    }

    private func paragraphs(from lines: [String]) -> String {
        lines.map { paragraph($0) }.joined()
    }

    private func table(rows: [[String]]) -> String {
        let rowXML = rows.map { row in
            """
            <w:tr>
                \(row.map { cell($0) }.joined())
            </w:tr>
            """
        }.joined()

        return """
        <w:tbl>
            <w:tblPr>
                <w:tblBorders>
                    <w:top w:val="single" w:sz="4" w:color="D4D4D8"/>
                    <w:left w:val="single" w:sz="4" w:color="D4D4D8"/>
                    <w:bottom w:val="single" w:sz="4" w:color="D4D4D8"/>
                    <w:right w:val="single" w:sz="4" w:color="D4D4D8"/>
                    <w:insideH w:val="single" w:sz="4" w:color="D4D4D8"/>
                    <w:insideV w:val="single" w:sz="4" w:color="D4D4D8"/>
                </w:tblBorders>
            </w:tblPr>
            \(rowXML)
        </w:tbl>
        """
    }

    private func cell(_ text: String) -> String {
        """
        <w:tc>
            <w:tcPr>
                <w:tcW w:w="2400" w:type="dxa"/>
            </w:tcPr>
            <w:p>
                <w:r>
                    <w:t xml:space="preserve">\(text.xmlEscaped)</w:t>
                </w:r>
            </w:p>
        </w:tc>
        """
    }

    private func currency(_ value: Double) -> String {
        value.formatted(.currency(code: Locale.current.currency?.identifier ?? "EUR"))
    }
}

private struct DOCXFile {
    let path: String
    let data: Data
}

private enum SimpleZipWriter {
    static func write(files: [DOCXFile], to url: URL) throws {
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }

        var archive = Data()
        var centralDirectory = Data()
        var offset: UInt32 = 0

        for file in files {
            let fileNameData = Data(file.path.utf8)
            let crc = CRC32.checksum(of: file.data)
            let compressedSize = UInt32(file.data.count)
            let uncompressedSize = UInt32(file.data.count)

            archive.append(littleEndian: UInt32(0x04034b50))
            archive.append(littleEndian: UInt16(20))
            archive.append(littleEndian: UInt16(0))
            archive.append(littleEndian: UInt16(0))
            archive.append(littleEndian: UInt16(0))
            archive.append(littleEndian: UInt16(0))
            archive.append(littleEndian: crc)
            archive.append(littleEndian: compressedSize)
            archive.append(littleEndian: uncompressedSize)
            archive.append(littleEndian: UInt16(fileNameData.count))
            archive.append(littleEndian: UInt16(0))
            archive.append(fileNameData)
            archive.append(file.data)

            centralDirectory.append(littleEndian: UInt32(0x02014b50))
            centralDirectory.append(littleEndian: UInt16(20))
            centralDirectory.append(littleEndian: UInt16(20))
            centralDirectory.append(littleEndian: UInt16(0))
            centralDirectory.append(littleEndian: UInt16(0))
            centralDirectory.append(littleEndian: UInt16(0))
            centralDirectory.append(littleEndian: UInt16(0))
            centralDirectory.append(littleEndian: crc)
            centralDirectory.append(littleEndian: compressedSize)
            centralDirectory.append(littleEndian: uncompressedSize)
            centralDirectory.append(littleEndian: UInt16(fileNameData.count))
            centralDirectory.append(littleEndian: UInt16(0))
            centralDirectory.append(littleEndian: UInt16(0))
            centralDirectory.append(littleEndian: UInt16(0))
            centralDirectory.append(littleEndian: UInt16(0))
            centralDirectory.append(littleEndian: UInt32(0))
            centralDirectory.append(littleEndian: offset)
            centralDirectory.append(fileNameData)

            offset = UInt32(archive.count)
        }

        let centralDirectoryOffset = UInt32(archive.count)
        archive.append(centralDirectory)
        archive.append(littleEndian: UInt32(0x06054b50))
        archive.append(littleEndian: UInt16(0))
        archive.append(littleEndian: UInt16(0))
        archive.append(littleEndian: UInt16(files.count))
        archive.append(littleEndian: UInt16(files.count))
        archive.append(littleEndian: UInt32(centralDirectory.count))
        archive.append(littleEndian: centralDirectoryOffset)
        archive.append(littleEndian: UInt16(0))

        try archive.write(to: url, options: .atomic)
    }
}

private enum CRC32 {
    private static let table: [UInt32] = {
        (0..<256).map { value in
            var current = UInt32(value)
            for _ in 0..<8 {
                if current & 1 == 1 {
                    current = 0xEDB88320 ^ (current >> 1)
                } else {
                    current >>= 1
                }
            }
            return current
        }
    }()

    static func checksum(of data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFFFFFF
        for byte in data {
            let index = Int((crc ^ UInt32(byte)) & 0xFF)
            crc = table[index] ^ (crc >> 8)
        }
        return crc ^ 0xFFFFFFFF
    }
}

private extension Data {
    mutating func append<T: FixedWidthInteger>(littleEndian value: T) {
        var littleEndianValue = value.littleEndian
        Swift.withUnsafeBytes(of: &littleEndianValue) { bytes in
            append(bytes.bindMemory(to: UInt8.self))
        }
    }
}

private extension String {
    var xmlEscaped: String {
        self
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
