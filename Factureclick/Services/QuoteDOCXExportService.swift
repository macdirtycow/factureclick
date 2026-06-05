//
//  QuoteDOCXExportService.swift
//  Factureclick
//
//  Created by Codex on 23/08/2025.
//

import Foundation

struct QuoteDOCXExportService {
    private let pricingService = QuotePricingService()
    private let exportFileStorageService = ExportFileStorageService()
    private let localization: DocumentExportLocalization
    private let templateStyle: DocumentTemplateStyle

    init(localeIdentifier: String? = nil, templateStyle: DocumentTemplateStyle = .premium) {
        localization = DocumentExportLocalization(
            localeCode: localeIdentifier ?? Locale.preferredLanguages.first ?? Locale.current.identifier
        )
        self.templateStyle = templateStyle
    }

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
        let logo = logoAsset(from: companyProfile?.logoData)
        var files = [
            DOCXFile(path: "[Content_Types].xml", data: Data(contentTypesXML.utf8)),
            DOCXFile(path: "_rels/.rels", data: Data(rootRelationshipsXML.utf8)),
            DOCXFile(path: "docProps/app.xml", data: Data(appPropertiesXML.utf8)),
            DOCXFile(path: "docProps/core.xml", data: Data(corePropertiesXML(title: "\(localization.quoteTitle) \(quote.quoteNumber)").utf8)),
            DOCXFile(path: "word/_rels/document.xml.rels", data: Data(documentRelationshipsXML(logoFileExtension: logo?.fileExtension).utf8)),
            DOCXFile(path: "word/footer1.xml", data: Data(footerXML(accentHex: normalizedHexColor(templateStyle.accentHex(defaultAccent: companyProfile?.accentColor)) ?? "2563EB").utf8)),
            DOCXFile(
                path: "word/document.xml",
                data: Data(documentXML(quote: quote, companyProfile: companyProfile, totals: totals, vatBreakdown: vatBreakdown, includesLogo: logo != nil).utf8)
            )
        ]
        if let logo {
            files.append(DOCXFile(path: "word/media/company-logo.\(logo.fileExtension)", data: logo.data))
        }

        let url = try makeExportURL(quoteNumber: quote.quoteNumber)
        try SimpleZipWriter.write(files: files, to: url)

        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = (attributes?[.size] as? NSNumber)?.int64Value ?? 0
        return ExportedInvoiceFile(url: url, createdAt: .now, fileSize: fileSize)
    }

    private func makeExportURL(quoteNumber: String) throws -> URL {
        try exportFileStorageService.makeURL(fileName: "Quote-\(quoteNumber)-\(templateStyle.fileNameComponent).docx")
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
            <Default Extension="png" ContentType="image/png"/>
            <Default Extension="jpg" ContentType="image/jpeg"/>
            <Default Extension="jpeg" ContentType="image/jpeg"/>
            <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
            <Override PartName="/word/footer1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml"/>
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
            <Application>\(AppBrand.displayName)</Application>
        </Properties>
        """
    }

    private func corePropertiesXML(title: String) -> String {
        let now = ISO8601DateFormatter().string(from: .now)
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <dc:title>\(title.xmlEscaped)</dc:title>
            <dc:creator>\(AppBrand.displayName)</dc:creator>
            <cp:lastModifiedBy>\(AppBrand.displayName)</cp:lastModifiedBy>
            <dcterms:created xsi:type="dcterms:W3CDTF">\(now)</dcterms:created>
            <dcterms:modified xsi:type="dcterms:W3CDTF">\(now)</dcterms:modified>
        </cp:coreProperties>
        """
    }

    private func documentRelationshipsXML(logoFileExtension: String?) -> String {
        let logoRelationship = logoFileExtension
            .map { #"<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/company-logo.\#($0)"/>"# }
            ?? ""
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
            <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer" Target="footer1.xml"/>
            \(logoRelationship)
        </Relationships>
        """
    }

    private func footerXML(accentHex: String) -> String {
        """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <w:ftr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
            <w:p>
                <w:pPr>
                    <w:jc w:val="center"/>
                    <w:pBdr>
                        <w:top w:val="single" w:sz="6" w:space="2" w:color="\(accentHex)"/>
                    </w:pBdr>
                </w:pPr>
                <w:r>
                    <w:rPr>
                        <w:b/>
                        <w:color w:val="\(accentHex)"/>
                        <w:sz w:val="16"/>
                    </w:rPr>
                    <w:t>\(localization.poweredByFactureclickLabel.xmlEscaped)</w:t>
                </w:r>
            </w:p>
        </w:ftr>
        """
    }

    private func documentXML(
        quote: Quote,
        companyProfile: CompanyProfile?,
        totals: QuoteTotals,
        vatBreakdown: [(rate: Double, amount: Double)],
        includesLogo: Bool
    ) -> String {
        let companyLines = [
            companyProfile?.name,
            companyProfile?.ownerName,
            companyProfile?.address,
            companyProfile?.email,
            companyProfile?.phone,
            companyProfile?.kvkNumber.isEmpty == false ? "\(localization.kvkLabel): \(companyProfile!.kvkNumber)" : nil,
            companyProfile?.vatNumber.isEmpty == false ? "\(localization.vatRegistrationLabel): \(companyProfile!.vatNumber)" : nil,
            companyProfile?.iban.isEmpty == false ? "\(localization.ibanLabel): \(companyProfile!.iban)" : nil
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }

        let clientLines = [
            quote.client.name,
            quote.client.contactPerson,
            quote.client.address,
            quote.client.email,
            quote.client.phone,
            quote.client.kvkNumber.isEmpty ? nil : "\(localization.kvkLabel): \(quote.client.kvkNumber)",
            quote.client.vatNumber.isEmpty ? nil : "\(localization.vatRegistrationLabel): \(quote.client.vatNumber)"
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }

        let quoteNotes = quote.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let messageLine = localization.resolvedDefaultMessage(
            customText: companyProfile?.defaultInvoiceText,
            fallback: localization.quoteAcceptanceMessage
        )
        let messageLines = [quoteNotes, messageLine].filter { !$0.isEmpty }
        let accentHex = normalizedHexColor(templateStyle.accentHex(defaultAccent: companyProfile?.accentColor)) ?? "2563EB"
        let inkHex = normalizedHexColor(templateStyle.inkHex) ?? "111827"
        let softAccentHex = normalizedHexColor(templateStyle.softAccentHex) ?? "EEF4FF"
        let layout = QuoteDOCXTemplateLayout(style: templateStyle)
        let brandName = companyProfile?.name.isEmpty == false ? companyProfile!.name : AppBrand.displayName

        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <w:document xmlns:wpc="http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas" xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:wp14="http://schemas.microsoft.com/office/word/2010/wordprocessingDrawing" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:w10="urn:schemas-microsoft-com:office:word" xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" mc:Ignorable="w14 wp14">
            <w:body>
                \(quoteHeader(title: localization.quoteTitle.uppercased(), brandName: brandName, quoteNumber: quote.quoteNumber, accentHex: accentHex, inkHex: inkHex, softAccentHex: softAccentHex, includesLogo: includesLogo))
                \(layout.showsBadge ? brandBadge(accentHex: accentHex, softAccentHex: softAccentHex) : paragraph("", size: 6))
                \(twoColumnDetailsTable(leftTitle: localization.fromLabel, leftLines: companyLines, rightTitle: localization.quoteForLabel, rightLines: clientLines, accentHex: accentHex, panelHex: layout.panelHex, borderHex: "E5E7EB", inkHex: inkHex))
                \(paragraph("", size: layout.spacingParagraphSize))
                \(heading(localization.quoteDetailsLabel, size: layout.headingSize, colorHex: layout.headingColorHex(accentHex: accentHex, inkHex: inkHex)))
                \(keyValueTable(
                    rows: [
                        [localization.quoteNumberLabel, quote.quoteNumber],
                        [localization.quoteDateLabel, quote.date.formatted(date: .abbreviated, time: .omitted)],
                        [localization.expiryDateLabel, quote.expiryDate.formatted(date: .abbreviated, time: .omitted)],
                        [localization.statusLabel, quote.status.displayName]
                    ],
                    accentHex: accentHex
                ))
                \(paragraph("", size: layout.spacingParagraphSize))
                \(heading(localization.quoteLinesLabel, size: layout.headingSize, colorHex: layout.headingColorHex(accentHex: accentHex, inkHex: inkHex)))
                \(table(
                    rows: [[localization.descriptionLabel, localization.qtyLabel, localization.unitLabel, localization.totalLabel]] + quote.lines.map { line in
                        [
                            line.description,
                            line.quantity.formatted(.number.precision(.fractionLength(0...2))),
                            currency(line.unitPrice),
                            currency(line.quantity * line.unitPrice)
                        ]
                    },
                    accentHex: accentHex,
                    headerFillHex: layout.tableHeaderFillHex(accentHex: accentHex, inkHex: inkHex, softAccentHex: softAccentHex),
                    headerTextHex: layout.tableHeaderTextHex,
                    columnWidths: layout.lineColumnWidths
                ))
                \(paragraph("", size: layout.spacingParagraphSize))
                \(heading(localization.vatBreakdownLabel, size: layout.headingSize, colorHex: layout.headingColorHex(accentHex: accentHex, inkHex: inkHex)))
                \(table(
                    rows: [["Rate", localization.vatAmountLabel]] + vatBreakdown.map {
                        [
                            "\($0.rate.formatted(.number.precision(.fractionLength(0...2))))%",
                            currency($0.amount)
                        ]
                    },
                    accentHex: accentHex,
                    headerFillHex: softAccentHex,
                    headerTextHex: inkHex,
                    columnWidths: [2600, 2600]
                ))
                \(paragraph("", size: layout.spacingParagraphSize))
                \(heading(localization.totalsLabel, size: layout.headingSize, colorHex: layout.headingColorHex(accentHex: accentHex, inkHex: inkHex)))
                \(keyValueTable(
                    rows: [
                        [localization.subtotalLabel, currency(totals.subtotal)],
                        [localization.vatLabel, currency(totals.vat)],
                        [localization.totalLabel, currency(totals.total)]
                    ],
                    accentHex: accentHex,
                    emphasizeLastRow: true
                ))
                \(paragraph("", size: layout.spacingParagraphSize))
                \(heading(localization.termsLabel, size: layout.headingSize, colorHex: layout.headingColorHex(accentHex: accentHex, inkHex: inkHex)))
                \(keyValueTable(
                    rows: [
                        [localization.expiryDateLabel, localization.validUntil(quote.expiryDate.formatted(date: .abbreviated, time: .omitted))],
                        [localization.messageLabel, messageLines.joined(separator: "\n\n")]
                    ],
                    accentHex: accentHex
                ))
                <w:sectPr>
                    <w:pgSz w:w="12240" w:h="15840"/>
                    <w:pgMar w:top="\(layout.pageMargin)" w:right="\(layout.pageMargin)" w:bottom="\(layout.pageMargin)" w:left="\(layout.pageMargin)" w:header="720" w:footer="720" w:gutter="0"/>
                    <w:footerReference w:type="default" r:id="rId1"/>
                </w:sectPr>
            </w:body>
        </w:document>
        """
    }

    private func heading(_ text: String, size: Int, colorHex: String) -> String {
        paragraph(text, bold: true, size: size, colorHex: colorHex)
    }

    private func paragraph(_ text: String, bold: Bool = false, size: Int = 22, colorHex: String? = nil) -> String {
        let boldTag = bold ? "<w:b/>" : ""
        let colorTag = colorHex.map { "<w:color w:val=\"\($0)\"/>" } ?? ""
        let safeText = text.isEmpty ? " " : text.xmlEscaped
        return """
        <w:p>
            <w:r>
                <w:rPr>\(boldTag)\(colorTag)<w:sz w:val="\(size)"/></w:rPr>
                <w:t xml:space="preserve">\(safeText)</w:t>
            </w:r>
        </w:p>
        """
    }

    private func paragraphs(from lines: [String]) -> String {
        lines.map { paragraph($0) }.joined()
    }

    private func quoteHeader(title: String, brandName: String, quoteNumber: String, accentHex: String, inkHex: String, softAccentHex: String, includesLogo: Bool) -> String {
        switch templateStyle {
        case .classic:
            return logoPrefix(includesLogo: includesLogo, inkHex: inkHex) + headerTable(
                columnWidths: [6100, 3100],
                borderHex: "E5E7EB",
                topBorderHex: accentHex,
                rows: [
                    cell(brandName, width: 6100, bold: true, textColor: inkHex, size: 24) + cell(quoteNumber, width: 3100, bold: true, textColor: inkHex, alignment: "right", size: 22),
                    cell(title, width: 6100, bold: true, textColor: accentHex, size: 18) + cell(localization.quoteNumberLabel, width: 3100, textColor: "9CA3AF", alignment: "right", size: 16)
                ]
            )
        case .premium:
            return logoPrefix(includesLogo: includesLogo, inkHex: inkHex) + headerTable(
                columnWidths: [5600, 3600],
                borderHex: "E5E7EB",
                topBorderHex: accentHex,
                rows: [
                    cell(brandName, width: 5600, bold: true, shaded: softAccentHex, textColor: inkHex, size: 24) + cell(quoteNumber, width: 3600, bold: true, shaded: accentHex, textColor: "FFFFFF", alignment: "right", size: 24),
                    cell(title, width: 5600, bold: true, textColor: accentHex, size: 18) + cell(localization.quoteNumberLabel, width: 3600, textColor: "6B7280", alignment: "right", size: 16)
                ]
            )
        case .compact:
            return logoPrefix(includesLogo: includesLogo, inkHex: inkHex) + headerTable(
                columnWidths: [6350, 2850],
                borderHex: "E5E7EB",
                topBorderHex: "CBD5E1",
                rows: [
                    cell("\(brandName) | \(title)", width: 6350, bold: true, shaded: "F8FAFC", textColor: inkHex, size: 18) + cell(quoteNumber, width: 2850, bold: true, shaded: "FFFFFF", textColor: inkHex, alignment: "right", size: 18)
                ]
            )
        case .bold:
            return logoPrefix(includesLogo: includesLogo, inkHex: inkHex) + headerTable(
                columnWidths: [5900, 3300],
                borderHex: inkHex,
                topBorderHex: accentHex,
                rows: [
                    cell(title, width: 5900, bold: true, shaded: inkHex, textColor: "FFFFFF", size: 28) + cell(quoteNumber, width: 3300, bold: true, shaded: accentHex, textColor: "FFFFFF", alignment: "right", size: 26),
                    cell(brandName, width: 5900, bold: true, shaded: inkHex, textColor: "FFFFFF", size: 20) + cell(localization.quoteNumberLabel, width: 3300, shaded: inkHex, textColor: "FFFFFF", alignment: "right", size: 18)
                ]
            )
        }
    }

    private func brandBadge(accentHex: String, softAccentHex: String) -> String {
        headerTable(
            columnWidths: [700, 3200],
            borderHex: "E5E7EB",
            topBorderHex: "E5E7EB",
            rows: [
                cell("FC", width: 700, bold: true, shaded: accentHex, textColor: "FFFFFF", alignment: "center", size: 18) +
                cell(localization.factureclickCertifiedLabel, width: 3200, bold: true, shaded: softAccentHex, textColor: accentHex, size: 18)
            ]
        ) + paragraph("", size: 10)
    }

    private func twoColumnDetailsTable(
        leftTitle: String,
        leftLines: [String],
        rightTitle: String,
        rightLines: [String],
        accentHex: String,
        panelHex: String,
        borderHex: String,
        inkHex: String
    ) -> String {
        let rowCount = max(leftLines.count, rightLines.count) + 1
        let rows = (0..<rowCount).map { index in
            [
                index == 0 ? leftTitle : (index - 1 < leftLines.count ? leftLines[index - 1] : ""),
                index == 0 ? rightTitle : (index - 1 < rightLines.count ? rightLines[index - 1] : "")
            ]
        }
        return table(
            rows: rows,
            accentHex: accentHex,
            headerFillHex: panelHex,
            headerTextHex: "6B7280",
            bodyTextHex: inkHex,
            borderHex: borderHex,
            columnWidths: [4500, 4700]
        )
    }

    private func keyValueTable(rows: [[String]], accentHex: String, emphasizeLastRow: Bool = false) -> String {
        let columnWidths = [3000, 6200]
        let rowXML = rows.enumerated().map { index, row in
            let isLast = emphasizeLastRow && index == rows.indices.last
            return """
            <w:tr>
                \(cell(row.first ?? "", width: columnWidths[0], bold: isLast, shaded: isLast ? "EEF4FF" : nil, textColor: isLast ? "111827" : "6B7280"))
                \(cell(row.count > 1 ? row[1] : "", width: columnWidths[1], bold: isLast, shaded: isLast ? "EEF4FF" : nil, textColor: "111827", alignment: "right"))
            </w:tr>
            """
        }.joined()

        return """
        <w:tbl>
            <w:tblPr>
                <w:tblW w:w="\(columnWidths.reduce(0, +))" w:type="dxa"/>
                <w:tblLayout w:type="fixed"/>
                <w:tblBorders>
                    <w:top w:val="single" w:sz="4" w:color="\(accentHex)"/>
                    <w:left w:val="single" w:sz="4" w:color="E5E7EB"/>
                    <w:bottom w:val="single" w:sz="4" w:color="E5E7EB"/>
                    <w:right w:val="single" w:sz="4" w:color="E5E7EB"/>
                    <w:insideH w:val="single" w:sz="4" w:color="F1F5F9"/>
                    <w:insideV w:val="nil"/>
                </w:tblBorders>
            </w:tblPr>
            \(tableGrid(columnWidths: columnWidths))
            \(rowXML)
        </w:tbl>
        """
    }

    private func table(
        rows: [[String]],
        accentHex: String,
        headerFillHex: String,
        headerTextHex: String,
        bodyTextHex: String = "111827",
        borderHex: String = "E5E7EB",
        columnWidths: [Int]
    ) -> String {
        let tableWidth = columnWidths.reduce(0, +)
        let rowXML = rows.enumerated().map { rowIndex, row in
            let isHeader = rowIndex == 0
            return """
            <w:tr>
                \(row.enumerated().map { index, value in
                    cell(
                        value,
                        width: columnWidths.indices.contains(index) ? columnWidths[index] : 2400,
                        bold: isHeader,
                        shaded: isHeader ? headerFillHex : "FFFFFF",
                        textColor: isHeader ? headerTextHex : bodyTextHex,
                        alignment: index == 0 ? "left" : "right"
                    )
                }.joined())
            </w:tr>
            """
        }.joined()

        return """
        <w:tbl>
            <w:tblPr>
                <w:tblW w:w="\(tableWidth)" w:type="dxa"/>
                <w:tblLayout w:type="fixed"/>
                <w:tblBorders>
                    <w:top w:val="single" w:sz="4" w:color="\(accentHex)"/>
                    <w:left w:val="single" w:sz="4" w:color="\(borderHex)"/>
                    <w:bottom w:val="single" w:sz="4" w:color="\(borderHex)"/>
                    <w:right w:val="single" w:sz="4" w:color="\(borderHex)"/>
                    <w:insideH w:val="single" w:sz="4" w:color="F1F5F9"/>
                    <w:insideV w:val="single" w:sz="4" w:color="F1F5F9"/>
                </w:tblBorders>
            </w:tblPr>
            \(tableGrid(columnWidths: columnWidths))
            \(rowXML)
        </w:tbl>
        """
    }

    private func headerTable(columnWidths: [Int], borderHex: String, topBorderHex: String, rows: [String]) -> String {
        """
        <w:tbl>
            <w:tblPr>
                <w:tblW w:w="\(columnWidths.reduce(0, +))" w:type="dxa"/>
                <w:tblLayout w:type="fixed"/>
                <w:tblBorders>
                    <w:top w:val="single" w:sz="12" w:color="\(topBorderHex)"/>
                    <w:left w:val="single" w:sz="4" w:color="\(borderHex)"/>
                    <w:bottom w:val="single" w:sz="4" w:color="\(borderHex)"/>
                    <w:right w:val="single" w:sz="4" w:color="\(borderHex)"/>
                    <w:insideH w:val="nil"/>
                    <w:insideV w:val="nil"/>
                </w:tblBorders>
            </w:tblPr>
            \(tableGrid(columnWidths: columnWidths))
            \(rows.map { "<w:tr>\($0)</w:tr>" }.joined())
        </w:tbl>
        """
    }

    private func tableGrid(columnWidths: [Int]) -> String {
        """
        <w:tblGrid>
            \(columnWidths.map { "<w:gridCol w:w=\"\($0)\"/>" }.joined())
        </w:tblGrid>
        """
    }

    private func cell(
        _ text: String,
        width: Int,
        bold: Bool = false,
        shaded: String? = nil,
        textColor: String? = nil,
        alignment: String = "left",
        size: Int = 20
    ) -> String {
        let shading = shaded.map { "<w:shd w:val=\"clear\" w:color=\"auto\" w:fill=\"\($0)\"/>" } ?? ""
        let boldTag = bold ? "<w:b/>" : ""
        let colorTag = textColor.map { "<w:color w:val=\"\($0)\"/>" } ?? ""
        return """
        <w:tc>
            <w:tcPr>
                <w:tcW w:w="\(width)" w:type="dxa"/>
                \(shading)
            </w:tcPr>
            <w:p>
                <w:pPr><w:jc w:val="\(alignment)"/></w:pPr>
                <w:r>
                    <w:rPr>\(boldTag)\(colorTag)<w:sz w:val="\(size)"/></w:rPr>
                    <w:t xml:space="preserve">\(text.xmlEscaped)</w:t>
                </w:r>
            </w:p>
        </w:tc>
        """
    }

    private func logoPrefix(includesLogo: Bool, inkHex: String) -> String {
        guard includesLogo else { return "" }
        return headerTable(
            columnWidths: [900, 8300],
            borderHex: "E5E7EB",
            topBorderHex: "E5E7EB",
            rows: [
                imageCell(width: 900, shaded: templateStyle == .bold ? inkHex : "FFFFFF") + cell("", width: 8300, shaded: templateStyle == .bold ? inkHex : "FFFFFF")
            ]
        )
    }

    private func imageCell(width: Int, shaded: String) -> String {
        """
        <w:tc>
            <w:tcPr>
                <w:tcW w:w="\(width)" w:type="dxa"/>
                <w:shd w:val="clear" w:color="auto" w:fill="\(shaded)"/>
            </w:tcPr>
            <w:p>
                <w:pPr><w:jc w:val="center"/></w:pPr>
                <w:r>
                    \(logoDrawingXML)
                </w:r>
            </w:p>
        </w:tc>
        """
    }

    private var logoDrawingXML: String {
        let extent: Int64 = 548_640
        return """
        <w:drawing>
            <wp:inline distT="0" distB="0" distL="0" distR="0">
                <wp:extent cx="\(extent)" cy="\(extent)"/>
                <wp:effectExtent l="0" t="0" r="0" b="0"/>
                <wp:docPr id="1" name="Company logo"/>
                <wp:cNvGraphicFramePr/>
                <a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
                    <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">
                        <pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
                            <pic:nvPicPr>
                                <pic:cNvPr id="1" name="company-logo"/>
                                <pic:cNvPicPr/>
                            </pic:nvPicPr>
                            <pic:blipFill>
                                <a:blip r:embed="rId2"/>
                                <a:stretch><a:fillRect/></a:stretch>
                            </pic:blipFill>
                            <pic:spPr>
                                <a:xfrm><a:off x="0" y="0"/><a:ext cx="\(extent)" cy="\(extent)"/></a:xfrm>
                                <a:prstGeom prst="rect"><a:avLst/></a:prstGeom>
                            </pic:spPr>
                        </pic:pic>
                    </a:graphicData>
                </a:graphic>
            </wp:inline>
        </w:drawing>
        """
    }

    private func logoAsset(from data: Data?) -> (data: Data, fileExtension: String)? {
        guard let data, !data.isEmpty else { return nil }
        if data.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
            return (data, "png")
        }
        if data.starts(with: [0xFF, 0xD8, 0xFF]) {
            return (data, "jpg")
        }
        return (data, "png")
    }

    private func currency(_ value: Double) -> String {
        value.formatted(.currency(code: Locale.current.currency?.identifier ?? "EUR"))
    }

    private func normalizedHexColor(_ value: String?) -> String? {
        guard let value else { return nil }
        let cleaned = value.trimmingCharacters(in: CharacterSet.alphanumerics.inverted).uppercased()
        guard cleaned.count == 6 else { return nil }
        return cleaned
    }
}

private struct DOCXFile {
    let path: String
    let data: Data
}

private struct QuoteDOCXTemplateLayout {
    let headingSize: Int
    let spacingParagraphSize: Int
    let pageMargin: Int
    let lineColumnWidths: [Int]
    let panelHex: String
    let showsBadge: Bool

    init(style: DocumentTemplateStyle) {
        switch style {
        case .classic:
            headingSize = 24
            spacingParagraphSize = 18
            pageMargin = 1440
            lineColumnWidths = [4300, 1200, 1800, 1900]
            panelHex = "FFFFFF"
            showsBadge = true
        case .premium:
            headingSize = 24
            spacingParagraphSize = 18
            pageMargin = 1080
            lineColumnWidths = [4300, 1200, 1800, 1900]
            panelHex = "F8FAFC"
            showsBadge = true
        case .compact:
            headingSize = 18
            spacingParagraphSize = 8
            pageMargin = 900
            lineColumnWidths = [5000, 1000, 1500, 1700]
            panelHex = "F3F4F6"
            showsBadge = false
        case .bold:
            headingSize = 26
            spacingParagraphSize = 20
            pageMargin = 1080
            lineColumnWidths = [4200, 1200, 1800, 2000]
            panelHex = "FFF7ED"
            showsBadge = true
        }
    }

    func headingColorHex(accentHex: String, inkHex: String) -> String {
        headingSize == 26 ? inkHex : accentHex
    }

    func tableHeaderFillHex(accentHex: String, inkHex: String, softAccentHex: String) -> String {
        switch headingSize {
        case 18:
            return "F3F4F6"
        case 26:
            return inkHex
        default:
            return softAccentHex
        }
    }

    var tableHeaderTextHex: String {
        headingSize == 26 ? "FFFFFF" : "111827"
    }
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
