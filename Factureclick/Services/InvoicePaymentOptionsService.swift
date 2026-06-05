//
//  InvoicePaymentOptionsService.swift
//  Factureclick
//
//  Created by Codex on 03/05/2026.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import UIKit

struct InvoicePaymentOption {
    let title: String
    let detailLines: [String]
    let actionLabel: String?
    let actionURL: URL?
    let qrCodePNGData: Data?
}

struct InvoicePaymentOptionsService {
    private let localization: DocumentExportLocalization
    private let qrContext = CIContext()

    init(localization: DocumentExportLocalization) {
        self.localization = localization
    }

    func makePaymentOptions(invoice: Invoice, companyProfile: CompanyProfile?) -> [InvoicePaymentOption] {
        var options = [InvoicePaymentOption]()

        if let bankTransferOption = makeBankTransferOption(invoice: invoice, companyProfile: companyProfile) {
            options.append(bankTransferOption)
        }

        if companyProfile?.isPayPalPaymentEnabled == true,
           let paypalOption = makeURLPaymentOption(
            title: localization.paypalLabel,
            urlString: companyProfile?.paypalPaymentURL,
            invoiceNumber: invoice.invoiceNumber
        ) {
            options.append(paypalOption)
        }

        return options
    }

    private func makeBankTransferOption(invoice: Invoice, companyProfile: CompanyProfile?) -> InvoicePaymentOption? {
        guard companyProfile?.showSEPAPaymentQRCode == true else { return nil }

        let iban = normalizedIBAN(companyProfile?.iban)
        guard !iban.isEmpty else { return nil }

        let accountHolder = resolvedAccountHolder(companyProfile)
        let paymentInstruction = localization.resolvedPaymentInstruction(
            customText: companyProfile?.defaultPaymentText,
            invoiceNumber: invoice.invoiceNumber
        )
        guard let qrCodePNGData = makeSEPAPaymentQRCodePNGData(
            name: accountHolder,
            iban: iban,
            amount: max(invoice.totalAmount, 0),
            remittance: paymentInstruction
        ) else {
            return nil
        }

        return InvoicePaymentOption(
            title: localization.bankTransferLabel,
            detailLines: [
                "\(localization.ibanLabel): \(iban)",
                "\(localization.accountHolderLabel): \(accountHolder)",
                "\(localization.messageLabel): \(paymentInstruction)"
            ],
            actionLabel: nil,
            actionURL: nil,
            qrCodePNGData: qrCodePNGData
        )
    }

    private func makeURLPaymentOption(title: String, urlString: String?, invoiceNumber: String) -> InvoicePaymentOption? {
        guard let actionURL = normalizedURL(from: urlString) else { return nil }

        return InvoicePaymentOption(
            title: title,
            detailLines: [
                "\(localization.paymentLinkLabel): \(actionURL.absoluteString)",
                "\(localization.messageLabel): \(invoiceNumber)"
            ],
            actionLabel: localization.openPaymentLinkLabel,
            actionURL: actionURL,
            qrCodePNGData: makeQRCodePNGData(from: actionURL.absoluteString)
        )
    }

    private func normalizedURL(from value: String?) -> URL? {
        guard let rawValue = value?.trimmingCharacters(in: .whitespacesAndNewlines), !rawValue.isEmpty else {
            return nil
        }

        if let directURL = URL(string: rawValue), directURL.scheme != nil {
            return directURL
        }

        return URL(string: "https://\(rawValue)")
    }

    private func resolvedAccountHolder(_ companyProfile: CompanyProfile?) -> String {
        if let ownerName = companyProfile?.ownerName.trimmingCharacters(in: .whitespacesAndNewlines), !ownerName.isEmpty {
            return ownerName
        }
        if let companyName = companyProfile?.name.trimmingCharacters(in: .whitespacesAndNewlines), !companyName.isEmpty {
            return companyName
        }
        return AppBrand.displayName
    }

    private func makeSEPAPaymentQRCodePNGData(name: String, iban: String, amount: Double, remittance: String) -> Data? {
        let normalizedName = normalizedSEPAText(name, maxLength: 70)
        let normalizedRemittance = normalizedSEPAText(remittance, maxLength: 140)
        let amountString = amount > 0 ? String(format: "EUR%.2f", amount) : ""
        let payloadLines = [
            "BCD",
            "002",
            "2",
            "SCT",
            "",
            normalizedName,
            iban,
            amountString,
            "",
            normalizedRemittance
        ]
        let payload = payloadLines.joined(separator: "\n")
        guard let payloadData = payload.data(using: .isoLatin1, allowLossyConversion: true) else {
            return nil
        }

        return makeQRCodePNGData(from: payloadData)
    }

    private func normalizedIBAN(_ value: String?) -> String {
        (value ?? "")
            .uppercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .joined()
    }

    private func normalizedSEPAText(_ value: String, maxLength: Int) -> String {
        let collapsedWhitespace = value
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return String(collapsedWhitespace.prefix(maxLength))
    }

    private func makeQRCodePNGData(from messageData: Data) -> Data? {
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(messageData, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")

        guard let outputImage = filter.outputImage else { return nil }
        let scaleTransform = CGAffineTransform(scaleX: 12, y: 12)
        let scaledImage = outputImage.transformed(by: scaleTransform)
        guard let cgImage = qrContext.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }

        let image = UIImage(cgImage: cgImage)
        return image.pngData()
    }

    private func makeQRCodePNGData(from value: String) -> Data? {
        guard let messageData = value.data(using: .utf8) else { return nil }
        return makeQRCodePNGData(from: messageData)
    }
}
