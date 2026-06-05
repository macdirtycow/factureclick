//
//  DocumentExportLocalization.swift
//  Factureclick
//
//  Created by Codex on 17/04/2026.
//

import Foundation

struct DocumentExportLocalization {
    enum DocumentKind {
        case invoice
        case quote
    }

    let localeCode: String

    init(localeCode: String = Locale.preferredLanguages.first ?? Locale.current.identifier) {
        self.localeCode = localeCode.lowercased()
    }

    var invoiceTitle: String {
        switch language {
        case .dutch:
            "Factuur"
        case .german:
            "Rechnung"
        case .english:
            "Invoice"
        }
    }

    var quoteTitle: String {
        switch language {
        case .dutch:
            "Offerte"
        case .german:
            "Angebot"
        case .english:
            "Quote"
        }
    }

    var fromLabel: String {
        switch language {
        case .dutch:
            "Van"
        case .german:
            "Von"
        case .english:
            "From"
        }
    }

    var billToLabel: String {
        switch language {
        case .dutch:
            "Aan"
        case .german:
            "Rechnung an"
        case .english:
            "Bill To"
        }
    }

    var quoteForLabel: String {
        switch language {
        case .dutch:
            "Offerte voor"
        case .german:
            "Angebot für"
        case .english:
            "Quote For"
        }
    }

    var pageLabel: String {
        switch language {
        case .dutch:
            "Pagina"
        case .german:
            "Seite"
        case .english:
            "Page"
        }
    }

    var descriptionLabel: String {
        switch language {
        case .dutch:
            "Beschrijving"
        case .german:
            "Beschreibung"
        case .english:
            "Description"
        }
    }

    var qtyLabel: String {
        switch language {
        case .dutch:
            "Aantal"
        case .german:
            "Menge"
        case .english:
            "Qty"
        }
    }

    var unitLabel: String {
        switch language {
        case .dutch:
            "Eenheid"
        case .german:
            "Einheit"
        case .english:
            "Unit"
        }
    }

    var totalLabel: String {
        switch language {
        case .dutch:
            "Totaal"
        case .german:
            "Gesamt"
        case .english:
            "Total"
        }
    }

    var subtotalLabel: String {
        switch language {
        case .dutch:
            "Subtotaal"
        case .german:
            "Zwischensumme"
        case .english:
            "Subtotal"
        }
    }

    var vatLabel: String {
        switch language {
        case .dutch:
            "Btw"
        case .german:
            "MwSt."
        case .english:
            "VAT"
        }
    }

    var vatBreakdownLabel: String {
        switch language {
        case .dutch:
            "Btw-overzicht"
        case .german:
            "MwSt.-Aufschlüsselung"
        case .english:
            "VAT breakdown"
        }
    }

    var vatAmountLabel: String {
        switch language {
        case .dutch:
            "Btw-bedrag"
        case .german:
            "MwSt.-Betrag"
        case .english:
            "VAT Amount"
        }
    }

    var totalsLabel: String {
        switch language {
        case .dutch:
            "Totalen"
        case .german:
            "Summen"
        case .english:
            "Totals"
        }
    }

    var paymentDetailsLabel: String {
        switch language {
        case .dutch:
            "Betaalgegevens"
        case .german:
            "Zahlungsdaten"
        case .english:
            "Payment details"
        }
    }

    var termsLabel: String {
        switch language {
        case .dutch:
            "Voorwaarden"
        case .german:
            "Bedingungen"
        case .english:
            "Terms"
        }
    }

    var messageLabel: String {
        switch language {
        case .dutch:
            "Bericht"
        case .german:
            "Nachricht"
        case .english:
            "Message"
        }
    }

    var collaborationLabel: String {
        switch language {
        case .dutch:
            "Samenwerking"
        case .german:
            "Zusammenarbeit"
        case .english:
            "Collaboration"
        }
    }

    var grossLabel: String {
        switch language {
        case .dutch:
            "Bruto"
        case .german:
            "Brutto"
        case .english:
            "Gross"
        }
    }

    var netIncomeLabel: String {
        switch language {
        case .dutch:
            "Netto-inkomen"
        case .german:
            "Nettoeinkommen"
        case .english:
            "Net income"
        }
    }

    var invoiceDetailsLabel: String {
        switch language {
        case .dutch:
            "Factuurgegevens"
        case .german:
            "Rechnungsdetails"
        case .english:
            "Invoice Details"
        }
    }

    var quoteDetailsLabel: String {
        switch language {
        case .dutch:
            "Offertegegevens"
        case .german:
            "Angebotsdetails"
        case .english:
            "Quote Details"
        }
    }

    var invoiceLinesLabel: String {
        switch language {
        case .dutch:
            "Factuurregels"
        case .german:
            "Rechnungspositionen"
        case .english:
            "Invoice Lines"
        }
    }

    var quoteLinesLabel: String {
        switch language {
        case .dutch:
            "Offerteregels"
        case .german:
            "Angebotspositionen"
        case .english:
            "Quote Lines"
        }
    }

    var invoiceNumberLabel: String {
        switch language {
        case .dutch:
            "Factuurnummer"
        case .german:
            "Rechnungsnummer"
        case .english:
            "Invoice number"
        }
    }

    var invoiceDateLabel: String {
        switch language {
        case .dutch:
            "Factuurdatum"
        case .german:
            "Rechnungsdatum"
        case .english:
            "Invoice date"
        }
    }

    var dueDateLabel: String {
        switch language {
        case .dutch:
            "Vervaldatum"
        case .german:
            "Fälligkeitsdatum"
        case .english:
            "Due date"
        }
    }

    var quoteNumberLabel: String {
        switch language {
        case .dutch:
            "Offertenummer"
        case .german:
            "Angebotsnummer"
        case .english:
            "Quote number"
        }
    }

    var quoteDateLabel: String {
        switch language {
        case .dutch:
            "Offertedatum"
        case .german:
            "Angebotsdatum"
        case .english:
            "Quote date"
        }
    }

    var expiryDateLabel: String {
        switch language {
        case .dutch:
            "Vervaldatum"
        case .german:
            "Ablaufdatum"
        case .english:
            "Expiry date"
        }
    }

    var statusLabel: String {
        switch language {
        case .dutch:
            "Status"
        case .german:
            "Status"
        case .english:
            "Status"
        }
    }

    var notSetLabel: String {
        switch language {
        case .dutch:
            "Niet ingesteld"
        case .german:
            "Nicht festgelegt"
        case .english:
            "Not set"
        }
    }

    func pageText(_ pageNumber: Int) -> String {
        "\(pageLabel) \(pageNumber)"
    }

    func paymentInstruction(invoiceNumber: String) -> String {
        switch language {
        case .dutch:
            "Vermeld factuurnummer \(invoiceNumber) bij de betaling."
        case .german:
            "Bitte geben Sie bei der Zahlung die Rechnungsnummer \(invoiceNumber) an."
        case .english:
            "Please mention invoice number \(invoiceNumber) with your payment."
        }
    }

    func accountHolder(_ name: String) -> String {
        switch language {
        case .dutch:
            "Rekeninghouder: \(name)"
        case .german:
            "Kontoinhaber: \(name)"
        case .english:
            "Account holder: \(name)"
        }
    }

    func partnerShare(name: String, percentage: String) -> String {
        switch language {
        case .dutch:
            "Partneraandeel (\(name) \(percentage)%):"
        case .german:
            "Partneranteil (\(name) \(percentage)%):"
        case .english:
            "Partner share (\(name) \(percentage)%):"
        }
    }

    func youKeep(_ amount: String) -> String {
        switch language {
        case .dutch:
            "Jij houdt over: \(amount)"
        case .german:
            "Sie behalten: \(amount)"
        case .english:
            "You keep: \(amount)"
        }
    }

    func validUntil(_ date: String) -> String {
        switch language {
        case .dutch:
            "Geldig tot \(date)."
        case .german:
            "Gültig bis \(date)."
        case .english:
            "Valid until \(date)."
        }
    }

    var quoteAcceptanceMessage: String {
        switch language {
        case .dutch:
            "Neem contact met ons op als u deze offerte wilt accepteren."
        case .german:
            "Bitte kontaktieren Sie uns, wenn Sie dieses Angebot annehmen möchten."
        case .english:
            "Please contact us if you would like to accept this quote."
        }
    }

    private var language: Language {
        if localeCode.hasPrefix("nl") {
            return .dutch
        }

        if localeCode.hasPrefix("de") {
            return .german
        }

        return .english
    }

    private enum Language {
        case english
        case dutch
        case german
    }
}
