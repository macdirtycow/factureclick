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

        if let paypalOption = makeURLPaymentOption(
            title: localization.paypalLabel,
            urlString: companyProfile?.paypalPaymentURL,
            invoiceNumber: invoice.invoiceNumber
        ) {
            options.append(paypalOption)
        }

        if let weroOption = makeURLPaymentOption(
            title: localization.weroLabel,
            urlString: companyProfile?.weroPaymentURL,
            invoiceNumber: invoice.invoiceNumber
        ) {
            options.append(weroOption)
        }

        return options
    }

    private func makeBankTransferOption(invoice: Invoice, companyProfile: CompanyProfile?) -> InvoicePaymentOption? {
        guard companyProfile?.showSEPAPaymentQRCode == true else { return nil }

        let iban = companyProfile?.iban.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !iban.isEmpty else { return nil }

        let accountHolder = resolvedAccountHolder(companyProfile)
        let paymentInstruction = localization.resolvedPaymentInstruction(
            customText: companyProfile?.defaultPaymentText,
            invoiceNumber: invoice.invoiceNumber
        )
        let qrString = makeSEPAPayload(
            name: accountHolder,
            iban: iban,
            amount: max(invoice.totalAmount, 0),
            remittance: paymentInstruction
        )

        return InvoicePaymentOption(
            title: localization.bankTransferLabel,
            detailLines: [
                "\(localization.ibanLabel): \(iban)",
                "\(localization.accountHolderLabel): \(accountHolder)",
                "\(localization.messageLabel): \(paymentInstruction)"
            ],
            actionLabel: nil,
            actionURL: nil,
            qrCodePNGData: makeQRCodePNGData(from: qrString)
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

    private func makeSEPAPayload(name: String, iban: String, amount: Double, remittance: String) -> String {
        let normalizedName = String(name.prefix(70))
        let normalizedRemittance = String(remittance.prefix(140))
        let amountString = amount > 0 ? String(format: "EUR%.2f", amount) : ""

        return [
            "BCD",
            "002",
            "1",
            "SCT",
            "",
            normalizedName,
            iban,
            amountString,
            "",
            normalizedRemittance,
            ""
        ].joined(separator: "\n")
    }

    private func makeQRCodePNGData(from value: String) -> Data? {
        guard let messageData = value.data(using: .utf8) else { return nil }

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
}
