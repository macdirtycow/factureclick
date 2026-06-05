//
//  QuotePDFExportService.swift
//  Factureclick
//
//  Created by Codex on 23/08/2025.
//

import Foundation
import UIKit

struct QuotePDFExportService {
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
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let margin: CGFloat = templateStyle == .compact ? 24 : 40
        let contentWidth = pageRect.width - (margin * 2)
        let printableBottom = pageRect.height - 44
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "\(localization.quoteTitle) \(quote.quoteNumber)",
            kCGPDFContextAuthor as String: companyProfile?.name.isEmpty == false ? companyProfile?.name as Any : AppBrand.displayName
        ]

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        let url = try makeExportURL(quoteNumber: quote.quoteNumber)
        let accent = UIColor(hex: templateStyle.accentHex(defaultAccent: companyProfile?.accentColor))
            ?? UIColor(red: 0.12, green: 0.40, blue: 0.86, alpha: 1)
        let ink = UIColor(hex: templateStyle.inkHex) ?? UIColor(red: 0.11, green: 0.14, blue: 0.19, alpha: 1)
        let boldFill = UIColor(red: 0.16, green: 0.18, blue: 0.22, alpha: 1)
        let border = UIColor(red: 0.88, green: 0.90, blue: 0.93, alpha: 1)
        let softText = UIColor(red: 0.42, green: 0.46, blue: 0.52, alpha: 1)
        let templateMetrics = QuotePDFTemplateMetrics(style: templateStyle)
        let brandName = companyProfile?.name.isEmpty == false ? companyProfile!.name : AppBrand.displayName

        try renderer.writePDF(to: url) { context in
            var currentY = margin
            var pageNumber = 1

            func beginPageIfNeeded(height: CGFloat) {
                if currentY + height > printableBottom {
                    pageNumber += 1
                    context.beginPage()
                    currentY = margin
                    drawPageHeader(pageNumber: pageNumber)
                }
            }

            func drawText(
                _ text: String,
                frame: CGRect,
                font: UIFont,
                color: UIColor = .label,
                alignment: NSTextAlignment = .left
            ) {
                let paragraph = NSMutableParagraphStyle()
                paragraph.alignment = alignment
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: color,
                    .paragraphStyle: paragraph
                ]
                NSString(string: text).draw(
                    with: frame,
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: attributes,
                    context: nil
                )
            }

            func measuredTextHeight(_ text: String, width: CGFloat, font: UIFont) -> CGFloat {
                let rect = NSString(string: text).boundingRect(
                    with: CGSize(width: width, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: [.font: font],
                    context: nil
                )
                return ceil(rect.height)
            }

            func measuredTextWidth(_ text: String, font: UIFont) -> CGFloat {
                ceil((text as NSString).size(withAttributes: [.font: font]).width)
            }

            func drawDivider(at y: CGFloat) {
                border.setStroke()
                let path = UIBezierPath()
                path.move(to: CGPoint(x: margin, y: y))
                path.addLine(to: CGPoint(x: pageRect.width - margin, y: y))
                path.lineWidth = 1
                path.stroke()
            }

            func drawPanel(_ rect: CGRect, fill: UIColor, stroke: UIColor? = nil, radius: CGFloat = 14) {
                let path = UIBezierPath(roundedRect: rect, cornerRadius: radius)
                fill.setFill()
                path.fill()
                if let stroke {
                    stroke.setStroke()
                    path.lineWidth = 1
                    path.stroke()
                }
            }

            func drawSectionHeader(_ title: String, y: CGFloat) {
                drawText(
                    title,
                    frame: CGRect(x: margin, y: y, width: 240, height: 16),
                    font: .systemFont(ofSize: templateStyle == .compact ? 12 : 14, weight: .semibold),
                    color: templateStyle == .bold ? ink : accent
                )
                drawDivider(at: y + 22)
            }

            func drawFactureclickBadge(at origin: CGPoint) {
                guard templateStyle != .compact else { return }
                let badgeRect = CGRect(x: origin.x, y: origin.y, width: 164, height: 22)
                let markRect = CGRect(x: badgeRect.minX, y: badgeRect.minY, width: 22, height: badgeRect.height)
                drawPanel(badgeRect, fill: .white, stroke: border, radius: 11)
                drawPanel(markRect, fill: templateStyle == .bold ? accent : ink, radius: 11)
                drawText("FC", frame: CGRect(x: markRect.minX, y: markRect.minY + 5, width: markRect.width, height: 14), font: .systemFont(ofSize: 9, weight: .bold), color: .white, alignment: .center)
                drawText(localization.factureclickCertifiedLabel, frame: CGRect(x: badgeRect.minX + 30, y: badgeRect.minY + 5, width: badgeRect.width - 38, height: 14), font: .systemFont(ofSize: 9, weight: .semibold), color: softText)
            }

            func drawPageFooter() {
                let footerY = pageRect.height - 30
                drawDivider(at: footerY - 10)
                drawText(
                    localization.poweredByFactureclickLabel,
                    frame: CGRect(x: margin, y: footerY, width: contentWidth, height: 12),
                    font: .systemFont(ofSize: 9, weight: .semibold),
                    color: softText,
                    alignment: .center
                )
            }

            func drawPageHeader(pageNumber: Int) {
                let headerRect = CGRect(x: margin + templateMetrics.headerInset, y: currentY, width: contentWidth - (templateMetrics.headerInset * 2), height: templateMetrics.headerHeight)
                let headerContentX = headerRect.minX + templateMetrics.headerPadding
                let numberFont = UIFont.systemFont(ofSize: templateStyle == .compact || quote.quoteNumber.count > 18 ? 11 : 13, weight: .semibold)
                let numberWidth = min(max(templateStyle == .compact ? 132 : 154, measuredTextWidth(quote.quoteNumber, font: numberFont) + 38), 220)
                let numberRect = CGRect(x: headerRect.maxX - templateMetrics.headerPadding - numberWidth, y: currentY + templateMetrics.numberY, width: numberWidth, height: templateStyle == .compact ? 26 : 32)
                let hasLogo = companyProfile?.logoData.flatMap(UIImage.init(data:)) != nil
                let brandX = headerContentX + (hasLogo ? templateMetrics.logoSize + 14 : 0)
                let brandWidth = max(120, numberRect.minX - brandX - 18)
                let baseBrandFontSize: CGFloat = templateStyle == .compact ? 17 : (templateStyle == .premium ? 25 : 22)
                let brandFontSize = brandWidth < 170 ? baseBrandFontSize - 2 : baseBrandFontSize
                let rightTitleY = max(headerRect.minY + 12, numberRect.minY - 18)

                switch templateStyle {
                case .classic:
                    drawPanel(headerRect, fill: .white, stroke: border, radius: 8)
                    drawDivider(at: headerRect.minY + 14)
                case .premium:
                    drawPanel(headerRect, fill: UIColor(red: 0.965, green: 0.992, blue: 0.984, alpha: 1), stroke: border, radius: 20)
                    drawPanel(CGRect(x: headerRect.minX + 10, y: headerRect.minY + 10, width: 6, height: headerRect.height - 20), fill: accent, radius: 3)
                    drawPanel(CGRect(x: headerRect.minX + 24, y: headerRect.maxY - 14, width: headerRect.width - 48, height: 4), fill: accent.withAlphaComponent(0.75), radius: 2)
                case .compact:
                    drawPanel(headerRect, fill: UIColor(red: 0.985, green: 0.987, blue: 0.992, alpha: 1), stroke: border, radius: 10)
                case .bold:
                    drawPanel(headerRect, fill: boldFill, radius: 18)
                    drawPanel(CGRect(x: headerRect.minX + 18, y: headerRect.maxY - 12, width: headerRect.width - 36, height: 4), fill: accent, radius: 2)
                }

                if let logoData = companyProfile?.logoData, let image = UIImage(data: logoData) {
                    image.draw(in: CGRect(x: headerContentX, y: currentY + templateMetrics.logoY, width: templateMetrics.logoSize, height: templateMetrics.logoSize))
                }

                drawText(
                    brandName,
                    frame: CGRect(x: brandX, y: currentY + templateMetrics.titleY, width: brandWidth, height: 28),
                    font: .systemFont(ofSize: brandFontSize, weight: .bold),
                    color: templateStyle == .bold ? .white : ink
                )

                if templateStyle != .classic {
                    drawText(
                        localization.quoteTitle.uppercased(),
                        frame: CGRect(x: numberRect.minX, y: rightTitleY, width: numberWidth, height: 14),
                        font: .systemFont(ofSize: 10, weight: .bold),
                        color: templateStyle == .bold ? UIColor.white.withAlphaComponent(0.84) : softText,
                        alignment: .right
                    )
                }

                let numberFill = templateStyle == .bold || templateStyle == .premium ? accent : UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1)
                let numberTextColor = templateStyle == .bold || templateStyle == .premium ? UIColor.white : ink
                drawPanel(numberRect, fill: numberFill, stroke: templateStyle == .bold || templateStyle == .premium ? nil : border, radius: templateStyle == .classic ? 8 : 16)
                drawText(
                    quote.quoteNumber,
                    frame: numberRect.insetBy(dx: 12, dy: 6),
                    font: numberFont,
                    color: numberTextColor,
                    alignment: .right
                )

                drawText(
                    localization.pageText(pageNumber),
                    frame: CGRect(x: numberRect.minX, y: currentY + templateMetrics.pageY, width: numberWidth, height: 14),
                    font: .systemFont(ofSize: 10, weight: .medium),
                    color: templateStyle == .bold ? UIColor.white.withAlphaComponent(0.68) : softText,
                    alignment: .right
                )

                if templateStyle != .premium && templateStyle != .classic && templateStyle != .bold {
                    let badgeOriginY = currentY + templateMetrics.badgeY
                    drawFactureclickBadge(at: CGPoint(x: brandX, y: badgeOriginY))
                }
                currentY += templateMetrics.headerAdvance
                if templateStyle == .classic {
                    drawFactureclickBadge(at: CGPoint(x: headerContentX, y: currentY - 6))
                    currentY += 20
                }
                if templateStyle == .bold {
                    drawFactureclickBadge(at: CGPoint(x: headerContentX, y: currentY - 8))
                    currentY += 22
                }
                if templateStyle == .premium {
                    drawFactureclickBadge(at: CGPoint(x: headerContentX, y: currentY - 10))
                    currentY += 22
                }
                drawPageFooter()
            }

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

            context.beginPage()
            drawPageHeader(pageNumber: pageNumber)

            let companyLines = [
                companyProfile?.name,
                companyProfile?.ownerName,
                companyProfile?.address,
                companyProfile?.email,
                companyProfile?.phone,
                companyProfile?.kvkNumber.isEmpty == false ? "\(localization.kvkLabel): \(companyProfile!.kvkNumber)" : nil,
                companyProfile?.vatNumber.isEmpty == false ? "\(localization.vatRegistrationLabel): \(companyProfile!.vatNumber)" : nil,
                companyProfile?.iban.isEmpty == false ? "\(localization.ibanLabel): \(companyProfile!.iban)" : nil
            ].compactMap { $0 }.filter { !$0.isEmpty }

            let clientLines = [
                quote.client.name,
                quote.client.contactPerson,
                quote.client.address,
                quote.client.email,
                quote.client.phone,
                quote.client.kvkNumber.isEmpty ? nil : "\(localization.kvkLabel): \(quote.client.kvkNumber)",
                quote.client.vatNumber.isEmpty ? nil : "\(localization.vatRegistrationLabel): \(quote.client.vatNumber)"
            ].compactMap { $0 }.filter { !$0.isEmpty }

            let addressGutter: CGFloat = templateStyle == .compact ? 10 : 18
            let addressWidth = (contentWidth - addressGutter) / 2
            let addressFont = UIFont.systemFont(ofSize: templateStyle == .compact ? 10 : 13)
            let companyAddressHeight = measuredTextHeight(companyLines.joined(separator: "\n"), width: addressWidth - 28, font: addressFont)
            let clientAddressHeight = measuredTextHeight(clientLines.joined(separator: "\n"), width: addressWidth - 28, font: addressFont)
            let addressHeight = max(templateStyle == .compact ? 92.0 : 120.0, max(companyAddressHeight, clientAddressHeight) + (templateStyle == .compact ? 32 : 42))
            beginPageIfNeeded(height: addressHeight + (templateStyle == .compact ? 10 : 14))
            let senderRect = CGRect(x: margin, y: currentY, width: addressWidth, height: addressHeight)
            let clientRect = CGRect(x: margin + addressWidth + addressGutter, y: currentY, width: addressWidth, height: addressHeight)
            let addressFill = templateStyle == .classic ? UIColor.white : UIColor(red: 0.99, green: 0.992, blue: 0.996, alpha: 1)
            drawPanel(senderRect, fill: addressFill, stroke: border, radius: templateStyle == .classic ? 8 : 14)
            drawPanel(clientRect, fill: addressFill, stroke: border, radius: templateStyle == .classic ? 8 : 14)
            let addressLabelY = templateStyle == .compact ? 10.0 : 12.0
            let addressTextY = templateStyle == .compact ? 24.0 : 28.0
            let addressTextHeight = templateStyle == .compact ? addressHeight - 28 : addressHeight - 34
            drawText(localization.fromLabel, frame: CGRect(x: senderRect.minX + 14, y: senderRect.minY + addressLabelY, width: 200, height: 16), font: .systemFont(ofSize: 10, weight: .bold), color: softText)
            drawText(companyLines.joined(separator: "\n"), frame: CGRect(x: senderRect.minX + 14, y: senderRect.minY + addressTextY, width: senderRect.width - 28, height: addressTextHeight), font: addressFont, color: ink)
            drawText(localization.quoteForLabel, frame: CGRect(x: clientRect.minX + 14, y: clientRect.minY + addressLabelY, width: 200, height: 16), font: .systemFont(ofSize: 10, weight: .bold), color: softText)
            drawText(clientLines.joined(separator: "\n"), frame: CGRect(x: clientRect.minX + 14, y: clientRect.minY + addressTextY, width: clientRect.width - 28, height: addressTextHeight), font: addressFont, color: ink)
            currentY += addressHeight + (templateStyle == .compact ? 10 : 14)

            let isCompact = templateStyle == .compact
            let metaHeight = isCompact ? 72.0 : 72.0
            let metaRect = CGRect(x: margin, y: currentY, width: contentWidth, height: metaHeight)
            drawPanel(metaRect, fill: templateStyle == .bold ? boldFill : UIColor(red: 0.985, green: 0.987, blue: 0.992, alpha: 1), stroke: templateStyle == .bold ? nil : border, radius: templateStyle == .classic ? 8 : 14)
            drawText("\(localization.quoteNumberLabel)\n\(localization.quoteDateLabel)\n\(localization.expiryDateLabel)", frame: CGRect(x: metaRect.minX + 16, y: metaRect.minY + (isCompact ? 11 : 10), width: 136, height: isCompact ? 56 : 48), font: .systemFont(ofSize: isCompact ? 11 : 12, weight: .semibold), color: softText)
            drawText("\(quote.quoteNumber)\n\(quote.date.formatted(date: .abbreviated, time: .omitted))\n\(quote.expiryDate.formatted(date: .abbreviated, time: .omitted))", frame: CGRect(x: metaRect.minX + 158, y: metaRect.minY + (isCompact ? 11 : 10), width: metaRect.width - 176, height: isCompact ? 56 : 48), font: .systemFont(ofSize: isCompact ? 12 : 13, weight: .medium), color: templateStyle == .bold ? .white : ink)
            currentY += metaHeight + (isCompact ? 12 : 18)

            let tableHeaderHeight = templateStyle == .compact ? 24.0 : 32.0
            let headerBackground = CGRect(x: margin, y: currentY, width: contentWidth, height: tableHeaderHeight)
            let tableHeaderFill = templateStyle == .bold ? boldFill : UIColor(red: 0.965, green: 0.972, blue: 0.982, alpha: 1)
            let tableHeaderText = templateStyle == .bold ? UIColor.white : ink
            drawPanel(headerBackground, fill: tableHeaderFill, stroke: templateStyle == .bold ? nil : border, radius: templateStyle == .classic ? 6 : 10)
            drawText(localization.descriptionLabel, frame: CGRect(x: margin + 10, y: currentY + 7, width: 250, height: 16), font: .systemFont(ofSize: 12, weight: .bold), color: tableHeaderText)
            drawText(localization.qtyLabel, frame: CGRect(x: margin + 275, y: currentY + 7, width: 50, height: 16), font: .systemFont(ofSize: 12, weight: .bold), color: tableHeaderText, alignment: .right)
            drawText(localization.unitLabel, frame: CGRect(x: margin + 340, y: currentY + 7, width: 70, height: 16), font: .systemFont(ofSize: 12, weight: .bold), color: tableHeaderText, alignment: .right)
            drawText(localization.totalLabel, frame: CGRect(x: margin + 425, y: currentY + 7, width: 90, height: 16), font: .systemFont(ofSize: 12, weight: .bold), color: tableHeaderText, alignment: .right)
            currentY += tableHeaderHeight + (templateStyle == .compact ? 11 : 6)

            for (index, line) in quote.lines.enumerated() {
                let descriptionFont = UIFont.systemFont(ofSize: templateStyle == .compact ? 10 : 13)
                let valueFont = UIFont.systemFont(ofSize: templateStyle == .compact ? 10 : 13)
                let totalFont = UIFont.systemFont(ofSize: templateStyle == .compact ? 10 : 13, weight: .semibold)
                let descriptionHeight = measuredTextHeight(line.description, width: 250, font: descriptionFont)
                let rowHeight = max(templateMetrics.lineHeight, descriptionHeight + (templateStyle == .compact ? 8 : 10))
                let rowTextYOffset: CGFloat = templateStyle == .compact ? 3 : 0
                beginPageIfNeeded(height: rowHeight + 16)
                let lineSubtotal = line.quantity * line.unitPrice
                if index.isMultiple(of: 2), templateStyle != .classic {
                    drawPanel(CGRect(x: margin, y: currentY - 5, width: contentWidth, height: rowHeight), fill: UIColor(red: 0.992, green: 0.994, blue: 0.996, alpha: 1), radius: 8)
                }
                drawText(line.description, frame: CGRect(x: margin, y: currentY + rowTextYOffset, width: 250, height: rowHeight - 4), font: descriptionFont, color: ink)
                drawText(line.quantity.formatted(.number.precision(.fractionLength(0...2))), frame: CGRect(x: margin + 275, y: currentY + rowTextYOffset, width: 50, height: 18), font: valueFont, color: ink, alignment: .right)
                drawText(currency(line.unitPrice), frame: CGRect(x: margin + 340, y: currentY + rowTextYOffset, width: 70, height: 18), font: valueFont, color: ink, alignment: .right)
                drawText(currency(lineSubtotal), frame: CGRect(x: margin + 425, y: currentY + rowTextYOffset, width: 90, height: 18), font: totalFont, color: ink, alignment: .right)
                currentY += rowHeight - 6
                drawDivider(at: currentY)
                currentY += templateStyle == .compact ? 4 : 8
            }

            if templateStyle == .compact {
                currentY += 10
            }

            beginPageIfNeeded(height: 180)
            let compactSummaryLayout = templateStyle == .compact
            let compactBreakdownRows = max(vatBreakdown.count, 1)
            let compactSummaryPanelY = currentY - 2
            let compactSummaryPanelHeight = 36 + CGFloat(compactBreakdownRows * 18) + 24 + 100
            if compactSummaryLayout {
                drawPanel(
                    CGRect(x: margin, y: compactSummaryPanelY, width: contentWidth, height: compactSummaryPanelHeight),
                    fill: UIColor(red: 0.978, green: 0.982, blue: 0.988, alpha: 1),
                    stroke: border,
                    radius: 14
                )
            }
            let compactContentX = compactSummaryLayout ? margin + 12 : margin
            if compactSummaryLayout {
                drawText(
                    localization.vatBreakdownLabel,
                    frame: CGRect(x: compactContentX, y: currentY + 2, width: contentWidth - 24, height: 16),
                    font: .systemFont(ofSize: 13, weight: .semibold),
                    color: softText
                )
                let cgContext = context.cgContext
                cgContext.setStrokeColor(border.cgColor)
                cgContext.setLineWidth(1)
                cgContext.move(to: CGPoint(x: margin + 12, y: currentY + 24))
                cgContext.addLine(to: CGPoint(x: margin + contentWidth - 12, y: currentY + 24))
                cgContext.strokePath()
                currentY += 32
            } else {
                drawSectionHeader(localization.vatBreakdownLabel, y: currentY)
                currentY += 26
            }

            for item in vatBreakdown {
                let compactValueWidth = compactSummaryLayout ? contentWidth - 24 - 120 : 120
                drawText("\(item.rate.formatted(.number.precision(.fractionLength(0...2))))%", frame: CGRect(x: compactContentX, y: currentY, width: 120, height: 16), font: .systemFont(ofSize: 13), color: ink)
                drawText(currency(item.amount), frame: CGRect(x: compactContentX + 120, y: currentY, width: compactValueWidth, height: 16), font: .systemFont(ofSize: 13), color: ink, alignment: .right)
                currentY += 18
            }

            let totalsX = compactSummaryLayout ? compactContentX : pageRect.width - margin - 220
            let boldSummaryLayout = templateStyle == .bold && !compactSummaryLayout
            let totalsY = compactSummaryLayout ? currentY + 14 : currentY - CGFloat(max(vatBreakdown.count, 1) * 18) - (boldSummaryLayout ? 4 : 24)
            let totalsRect = compactSummaryLayout
                ? CGRect(x: margin, y: totalsY - 12, width: contentWidth, height: 96)
                : CGRect(x: totalsX - 16, y: totalsY - 16, width: pageRect.width - margin - (totalsX - 16), height: 96)
            if !compactSummaryLayout {
                drawPanel(totalsRect, fill: templateStyle == .bold ? boldFill : UIColor(red: 0.985, green: 0.987, blue: 0.992, alpha: 1), stroke: templateStyle == .bold ? nil : border, radius: templateStyle == .classic ? 8 : 14)
            }

            let summaryValueColor = templateStyle == .bold ? UIColor.white : ink
            let summaryLabelColor = templateStyle == .bold ? UIColor(white: 0.82, alpha: 1) : softText
            let totalsValueWidth = compactSummaryLayout
                ? contentWidth - 24 - 110
                : pageRect.width - margin - totalsX - 110 - 6
            drawText(localization.subtotalLabel, frame: CGRect(x: totalsX, y: totalsY, width: 110, height: 18), font: .systemFont(ofSize: 13), color: summaryLabelColor)
            drawText(currency(totals.subtotal), frame: CGRect(x: totalsX + 110, y: totalsY, width: totalsValueWidth, height: 18), font: .systemFont(ofSize: 13, weight: .medium), color: summaryValueColor, alignment: .right)
            drawText(localization.vatLabel, frame: CGRect(x: totalsX, y: totalsY + 22, width: 110, height: 18), font: .systemFont(ofSize: 13), color: summaryLabelColor)
            drawText(currency(totals.vat), frame: CGRect(x: totalsX + 110, y: totalsY + 22, width: totalsValueWidth, height: 18), font: .systemFont(ofSize: 13, weight: .medium), color: summaryValueColor, alignment: .right)
            if compactSummaryLayout {
                let cgContext = context.cgContext
                cgContext.setStrokeColor(border.cgColor)
                cgContext.setLineWidth(1)
                cgContext.move(to: CGPoint(x: margin + 12, y: totalsY + 48))
                cgContext.addLine(to: CGPoint(x: margin + contentWidth - 12, y: totalsY + 48))
                cgContext.strokePath()
            } else {
                if boldSummaryLayout {
                    let cgContext = context.cgContext
                    cgContext.setStrokeColor(UIColor(white: 1, alpha: 0.16).cgColor)
                    cgContext.setLineWidth(1)
                    cgContext.move(to: CGPoint(x: totalsRect.minX + 16, y: totalsY + 48))
                    cgContext.addLine(to: CGPoint(x: totalsRect.maxX - 16, y: totalsY + 48))
                    cgContext.strokePath()
                } else {
                    drawDivider(at: totalsY + 48)
                }
            }
            drawText(localization.totalLabel, frame: CGRect(x: totalsX, y: totalsY + 58, width: 110, height: 20), font: .systemFont(ofSize: 15, weight: .bold), color: templateStyle == .bold ? .white : ink)
            drawText(currency(totals.total), frame: CGRect(x: totalsX + 110, y: totalsY + 58, width: totalsValueWidth, height: 20), font: .systemFont(ofSize: 16, weight: .bold), color: templateStyle == .bold ? .white : accent, alignment: .right)

            currentY = compactSummaryLayout ? compactSummaryPanelY + compactSummaryPanelHeight + 10 : max(currentY, totalsY + 90)
            drawDivider(at: currentY)
            currentY += 18
            drawSectionHeader(localization.termsLabel, y: currentY)
            currentY += 28

            let quoteNotes = quote.notes.trimmingCharacters(in: .whitespacesAndNewlines)
            let messageLine = localization.resolvedDefaultMessage(
                customText: companyProfile?.defaultInvoiceText,
                fallback: localization.quoteAcceptanceMessage
            )
            let termsText = [
                "\(localization.statusLabel): \(quote.status.displayName)",
                localization.validUntil(quote.expiryDate.formatted(date: .abbreviated, time: .omitted)),
                quoteNotes.isEmpty ? nil : quoteNotes,
                messageLine
            ].compactMap { $0 }.joined(separator: "\n\n")
            let termsFont = UIFont.systemFont(ofSize: templateStyle == .compact ? 11 : 13)
            let termsTextHeight = measuredTextHeight(termsText, width: contentWidth - 28, font: termsFont)
            let termsHeight = max(templateStyle == .compact ? 72 : 76, termsTextHeight + 26)
            beginPageIfNeeded(height: termsHeight + 8)
            let termsRect = CGRect(x: margin, y: currentY - 4, width: contentWidth, height: termsHeight)
            drawPanel(termsRect, fill: .white, stroke: border, radius: 14)
            drawText(
                termsText,
                frame: CGRect(x: margin + 14, y: currentY + 8, width: contentWidth - 28, height: termsRect.height - 18),
                font: termsFont,
                color: ink
            )
        }

        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = (attributes?[.size] as? NSNumber)?.int64Value ?? 0
        return ExportedInvoiceFile(url: url, createdAt: .now, fileSize: fileSize)
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

    private func makeExportURL(quoteNumber: String) throws -> URL {
        try exportFileStorageService.makeURL(fileName: "Quote-\(quoteNumber)-\(templateStyle.fileNameComponent).pdf")
    }

    private func currency(_ value: Double) -> String {
        value.formatted(.currency(code: Locale.current.currency?.identifier ?? "EUR"))
    }
}

private struct QuotePDFTemplateMetrics {
    let headerInset: CGFloat
    let headerPadding: CGFloat
    let headerHeight: CGFloat
    let headerAdvance: CGFloat
    let logoY: CGFloat
    let logoSize: CGFloat
    let logoOffset: CGFloat
    let titleY: CGFloat
    let badgeY: CGFloat
    let numberY: CGFloat
    let pageY: CGFloat
    let lineHeight: CGFloat

    init(style: DocumentTemplateStyle) {
        switch style {
        case .classic:
            headerInset = 0
            headerPadding = 20
            headerHeight = 96
            headerAdvance = 112
            logoY = 18
            logoSize = 52
            logoOffset = 66
            titleY = 22
            badgeY = 72
            numberY = 42
            pageY = 76
            lineHeight = 30
        case .premium:
            headerInset = 18
            headerPadding = 22
            headerHeight = 122
            headerAdvance = 138
            logoY = 24
            logoSize = 58
            logoOffset = 66
            titleY = 28
            badgeY = 92
            numberY = 42
            pageY = 92
            lineHeight = 32
        case .compact:
            headerInset = 0
            headerPadding = 14
            headerHeight = 72
            headerAdvance = 84
            logoY = 18
            logoSize = 34
            logoOffset = 54
            titleY = 14
            badgeY = 56
            numberY = 24
            pageY = 56
            lineHeight = 22
        case .bold:
            headerInset = 8
            headerPadding = 24
            headerHeight = 120
            headerAdvance = 138
            logoY = 28
            logoSize = 56
            logoOffset = 72
            titleY = 28
            badgeY = 78
            numberY = 40
            pageY = 80
            lineHeight = 34
        }
    }
}

private extension UIColor {
    convenience init?(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard cleaned.count == 6, let value = Int(cleaned, radix: 16) else { return nil }
        self.init(
            red: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1
        )
    }
}
