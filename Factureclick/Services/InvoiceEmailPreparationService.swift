//
//  InvoiceEmailPreparationService.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import Foundation
import SwiftData

struct InvoiceEmailDraft {
    var recipientEmail: String
    var subject: String
    var body: String
}

struct PreparedInvoiceEmail: Identifiable {
    let id = UUID()
    let draft: InvoiceEmailDraft
    let attachment: ExportedInvoiceFile
}

struct InvoiceEmailPreparationService {
    func prepareEmail(
        for invoice: Invoice,
        companyProfile: CompanyProfile?,
        collaborationRule: CollaborationRule?,
        appSettings: AppSettings? = nil,
        localeIdentifier: String? = nil,
        templateStyle: DocumentTemplateStyle? = nil
    ) throws -> PreparedInvoiceEmail {
        let resolvedTemplateStyle = templateStyle ?? appSettings?.invoiceTemplateStyle ?? .premium
        let attachment = try InvoicePDFExportService(
            localeIdentifier: localeIdentifier,
            templateStyle: resolvedTemplateStyle
        ).export(
            invoice: invoice,
            companyProfile: companyProfile,
            collaborationRule: collaborationRule
        )

        return PreparedInvoiceEmail(
            draft: makeDraft(for: invoice, companyProfile: companyProfile, appSettings: appSettings, localeIdentifier: localeIdentifier),
            attachment: attachment
        )
    }

    func makeDraft(
        for invoice: Invoice,
        companyProfile: CompanyProfile?,
        appSettings: AppSettings? = nil,
        localeIdentifier: String? = nil
    ) -> InvoiceEmailDraft {
        let recipient = invoice.lastEmailRecipient.isEmpty ? invoice.client.email : invoice.lastEmailRecipient
        let resolvedLocale = SupportedLocale.resolving(localeIdentifier ?? Locale.preferredLanguages.first ?? Locale.current.identifier)
        let localization = DocumentExportLocalization(localeCode: resolvedLocale.rawValue)
        let documentTitle = localization.invoiceTitle(for: invoice)
        let brandName = companyProfile?.name.isEmpty == false ? companyProfile!.name : AppBrand.displayName
        let fallbackSubject = localizedSubject(
            documentTitle: documentTitle,
            invoiceNumber: invoice.invoiceNumber,
            brandName: brandName,
            locale: resolvedLocale
        )
        let defaultSubject = appSettings?.defaultInvoiceEmailSubject.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let subject = invoice.lastEmailSubject.isEmpty
            ? renderedEmailTemplate(defaultSubject, fallback: fallbackSubject, for: invoice, companyProfile: companyProfile)
            : invoice.lastEmailSubject

        let greetingName = invoice.client.contactPerson.isEmpty ? invoice.client.name : invoice.client.contactPerson
        let paymentText = companyProfile?.defaultPaymentText.isEmpty == false
            ? companyProfile!.defaultPaymentText
            : localizedPaymentFallback(locale: resolvedLocale)
        let documentSentence = localizedDocumentSentence(for: invoice, locale: resolvedLocale)
        let dueDateSentence = localizedDueDateSentence(for: invoice, locale: resolvedLocale)
        let greeting = localizedGreeting(name: greetingName, locale: resolvedLocale)
        let signOff = localizedSignOff(locale: resolvedLocale)

        let fallbackBody = """
        \(greeting)

        \(documentSentence)

        \(dueDateSentence)

        \(paymentText)

        \(signOff),
        \(companyProfile?.ownerName.isEmpty == false ? companyProfile!.ownerName : companyProfile?.name ?? AppBrand.displayName)
        """
        let defaultBody = appSettings?.defaultInvoiceEmailBody.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let body = renderedEmailTemplate(defaultBody, fallback: fallbackBody, for: invoice, companyProfile: companyProfile)

        return InvoiceEmailDraft(
            recipientEmail: recipient,
            subject: subject,
            body: body
        )
    }

    func markEmailInitiated(
        invoice: Invoice,
        recipientEmail: String,
        subject: String,
        in context: ModelContext
    ) throws {
        invoice.lastEmailRecipient = recipientEmail
        invoice.lastEmailSubject = subject
        invoice.emailDeliveryStatus = .initiated
        invoice.emailInitiatedAt = .now
        invoice.emailSentAt = invoice.emailSentAt ?? .now
        if invoice.status == .draft {
            invoice.status = .sent
        }
        try context.save()
    }

    func markEmailSent(
        invoice: Invoice,
        recipientEmail: String,
        subject: String,
        in context: ModelContext
    ) throws {
        invoice.lastEmailRecipient = recipientEmail
        invoice.lastEmailSubject = subject
        invoice.emailDeliveryStatus = .sent
        invoice.emailInitiatedAt = invoice.emailInitiatedAt ?? .now
        invoice.emailSentAt = .now
        if invoice.status == .draft {
            invoice.status = .sent
        }
        try context.save()
    }

    func markEmailFailed(
        invoice: Invoice,
        recipientEmail: String,
        subject: String,
        in context: ModelContext
    ) throws {
        invoice.lastEmailRecipient = recipientEmail
        invoice.lastEmailSubject = subject
        invoice.emailDeliveryStatus = .failed
        invoice.emailInitiatedAt = invoice.emailInitiatedAt ?? .now
        try context.save()
    }

    private func currency(_ value: Double) -> String {
        let formatter = AppFormatters.currencyFormatter()
        return formatter.string(from: NSNumber(value: value)) ?? "EUR 0.00"
    }

    private func localizedSubject(
        documentTitle: String,
        invoiceNumber: String,
        brandName: String,
        locale: SupportedLocale
    ) -> String {
        switch locale {
        case .english:
            "\(documentTitle) \(invoiceNumber) from \(brandName)"
        case .dutch:
            "\(documentTitle) \(invoiceNumber) van \(brandName)"
        case .german:
            "\(documentTitle) \(invoiceNumber) von \(brandName)"
        }
    }

    private func localizedGreeting(name: String, locale: SupportedLocale) -> String {
        switch locale {
        case .english:
            "Hello \(name),"
        case .dutch:
            "Hallo \(name),"
        case .german:
            "Hallo \(name),"
        }
    }

    private func localizedPaymentFallback(locale: SupportedLocale) -> String {
        switch locale {
        case .english:
            "Please let us know if you have any questions."
        case .dutch:
            "Laat het gerust weten als u vragen heeft."
        case .german:
            "Bitte melden Sie sich, wenn Sie Fragen haben."
        }
    }

    private func localizedDocumentSentence(for invoice: Invoice, locale: SupportedLocale) -> String {
        let invoiceDate = AppFormatters.mediumDateFormatter.string(from: invoice.date)
        let amount = currency(invoice.totalAmount)

        return switch (locale, invoice.isCreditInvoice) {
        case (.english, true):
            "Please find attached credit invoice \(invoice.invoiceNumber), dated \(invoiceDate), for \(amount)."
        case (.english, false):
            "Please find attached invoice \(invoice.invoiceNumber), dated \(invoiceDate), for \(amount)."
        case (.dutch, true):
            "In de bijlage vindt u creditfactuur \(invoice.invoiceNumber), gedateerd op \(invoiceDate), voor \(amount)."
        case (.dutch, false):
            "In de bijlage vindt u factuur \(invoice.invoiceNumber), gedateerd op \(invoiceDate), voor \(amount)."
        case (.german, true):
            "Im Anhang finden Sie die Gutschrift \(invoice.invoiceNumber) vom \(invoiceDate) uber \(amount)."
        case (.german, false):
            "Im Anhang finden Sie die Rechnung \(invoice.invoiceNumber) vom \(invoiceDate) uber \(amount)."
        }
    }

    private func localizedDueDateSentence(for invoice: Invoice, locale: SupportedLocale) -> String {
        let dueDate = AppFormatters.mediumDateFormatter.string(from: invoice.dueDate)

        return switch (locale, invoice.isCreditInvoice) {
        case (.english, true):
            "This credit invoice has been issued for your records and does not require a payment reminder."
        case (.english, false):
            "The payment due date is \(dueDate)."
        case (.dutch, true):
            "Deze creditfactuur is voor uw administratie en vereist geen betaalherinnering."
        case (.dutch, false):
            "De uiterste betaaldatum is \(dueDate)."
        case (.german, true):
            "Diese Gutschrift ist fur Ihre Unterlagen bestimmt und erfordert keine Zahlungserinnerung."
        case (.german, false):
            "Das Zahlungsziel ist der \(dueDate)."
        }
    }

    private func localizedSignOff(locale: SupportedLocale) -> String {
        switch locale {
        case .english:
            "Kind regards"
        case .dutch:
            "Met vriendelijke groet"
        case .german:
            "Mit freundlichen Gruessen"
        }
    }

    private func renderedEmailTemplate(
        _ template: String,
        fallback: String,
        for invoice: Invoice,
        companyProfile: CompanyProfile?
    ) -> String {
        let trimmedTemplate = template.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTemplate.isEmpty else {
            return fallback
        }

        let contactName = invoice.client.contactPerson.trimmingCharacters(in: .whitespacesAndNewlines)
        let clientName = invoice.client.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let companyName = companyProfile?.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let ownerName = companyProfile?.ownerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let replacements = [
            "{client}": clientName,
            "{contact}": contactName.isEmpty ? clientName : contactName,
            "{invoiceNumber}": invoice.invoiceNumber,
            "{invoiceDate}": AppFormatters.mediumDateFormatter.string(from: invoice.date),
            "{dueDate}": AppFormatters.mediumDateFormatter.string(from: invoice.dueDate),
            "{amount}": currency(invoice.totalAmount),
            "{company}": companyName?.isEmpty == false ? companyName! : AppBrand.displayName,
            "{owner}": ownerName?.isEmpty == false ? ownerName! : companyName ?? AppBrand.displayName
        ]

        return replacements.reduce(trimmedTemplate) { rendered, replacement in
            rendered.replacingOccurrences(of: replacement.key, with: replacement.value)
        }
    }
}
