//
//  LocalizationSupport.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation

enum SupportedLocale: String, CaseIterable, Identifiable {
    case english = "en"
    case dutch = "nl"
    case german = "de"

    var id: String { rawValue }

    static func resolving(_ localeIdentifier: String?) -> SupportedLocale {
        let normalized = (localeIdentifier ?? "")
            .lowercased()
            .replacingOccurrences(of: "_", with: "-")

        if normalized.hasPrefix("nl") {
            return .dutch
        }

        if normalized.hasPrefix("de") {
            return .german
        }

        if normalized.hasPrefix("en") {
            return .english
        }

        return .english
    }

    var title: String {
        switch self {
        case .english:
            "English"
        case .dutch:
            "Nederlands"
        case .german:
            "Deutsch"
        }
    }
}

struct AppLocalization {
    private let locale: SupportedLocale

    init(localeIdentifier: String?) {
        locale = SupportedLocale.resolving(localeIdentifier)
    }

    func text(_ key: Key) -> String {
        key.values[locale] ?? key.values[.english] ?? key.rawValue
    }

    func phrase(_ english: String) -> String {
        phrases[english]?[locale] ?? english
    }

    func enableSEPAPaymentLabel() -> String {
        switch locale {
        case .english:
            "Enable bank transfer (SEPA)"
        case .dutch:
            "Bankoverschrijving (SEPA) inschakelen"
        case .german:
            "Banküberweisung (SEPA) aktivieren"
        }
    }

    func enablePayPalLabel() -> String {
        switch locale {
        case .english:
            "Enable PayPal"
        case .dutch:
            "PayPal inschakelen"
        case .german:
            "PayPal aktivieren"
        }
    }

    func payPalURLLabel() -> String {
        switch locale {
        case .english:
            "PayPal payment link"
        case .dutch:
            "PayPal-betaallink"
        case .german:
            "PayPal-Zahlungslink"
        }
    }

    func sepaPaymentHelperText() -> String {
        switch locale {
        case .english:
            "Customers can scan a SEPA QR code generated automatically from your IBAN and invoice amount."
        case .dutch:
            "Klanten kunnen een SEPA-QR-code scannen die automatisch wordt gemaakt op basis van je IBAN en factuurbedrag."
        case .german:
            "Kunden können einen SEPA-QR-Code scannen, der automatisch aus Ihrer IBAN und dem Rechnungsbetrag erstellt wird."
        }
    }

    func payPalHelperText() -> String {
        switch locale {
        case .english:
            "Paste your PayPal Business payment link or PayPal.Me link here."
        case .dutch:
            "Plak hier je PayPal Business-betaallink of PayPal.Me-link."
        case .german:
            "Fügen Sie hier Ihren PayPal-Business-Zahlungslink oder PayPal.Me-Link ein."
        }
    }

    func savedFile(_ fileName: String) -> String {
        switch locale {
        case .english:
            "Saved \(fileName) locally."
        case .dutch:
            "\(fileName) lokaal opgeslagen."
        case .german:
            "\(fileName) lokal gespeichert."
        }
    }

    func mailNotConfigured() -> String {
        switch locale {
        case .english:
            "Mail is not configured on this device. You can still review the email and share the PDF manually."
        case .dutch:
            "Mail is niet ingesteld op dit apparaat. Je kunt de e-mail nog steeds bekijken en de PDF handmatig delen."
        case .german:
            "Mail ist auf diesem Gerät nicht eingerichtet. Du kannst die E-Mail trotzdem prüfen und die PDF manuell teilen."
        }
    }

    func mileageRoute(from start: String, to end: String) -> String {
        switch locale {
        case .english:
            "\(start) to \(end)"
        case .dutch:
            "\(start) naar \(end)"
        case .german:
            "\(start) nach \(end)"
        }
    }

    func mileageMeta(kilometers: String, date: String) -> String {
        switch locale {
        case .english:
            "\(kilometers) km on \(date)"
        case .dutch:
            "\(kilometers) km op \(date)"
        case .german:
            "\(kilometers) km am \(date)"
        }
    }

    func reminderSubject(level: InvoiceReminderLevel, invoiceNumber: String) -> String {
        switch locale {
        case .english:
            switch level {
            case .friendly:
                "Payment reminder - invoice \(invoiceNumber)"
            case .second:
                "Second payment reminder - invoice \(invoiceNumber)"
            case .final:
                "Final payment reminder - invoice \(invoiceNumber)"
            }
        case .dutch:
            switch level {
            case .friendly:
                "Betalingsherinnering - factuur \(invoiceNumber)"
            case .second:
                "Tweede betalingsherinnering - factuur \(invoiceNumber)"
            case .final:
                "Laatste betalingsherinnering - factuur \(invoiceNumber)"
            }
        case .german:
            switch level {
            case .friendly:
                "Zahlungserinnerung - Rechnung \(invoiceNumber)"
            case .second:
                "Zweite Zahlungserinnerung - Rechnung \(invoiceNumber)"
            case .final:
                "Letzte Zahlungserinnerung - Rechnung \(invoiceNumber)"
            }
        }
    }

    func reminderGreeting(recipientName: String) -> String {
        switch locale {
        case .english:
            "Dear \(recipientName),"
        case .dutch:
            "Beste \(recipientName),"
        case .german:
            "Guten Tag \(recipientName),"
        }
    }

    func reminderIntro(
        level: InvoiceReminderLevel,
        invoiceNumber: String,
        amountDue: String,
        originalDueDate: String
    ) -> String {
        switch locale {
        case .english:
            switch level {
            case .friendly:
                "This is a friendly payment reminder for invoice \(invoiceNumber). The outstanding amount of \(amountDue) was originally due on \(originalDueDate)."
            case .second:
                "This is a second payment reminder for invoice \(invoiceNumber). The outstanding amount of \(amountDue) was originally due on \(originalDueDate)."
            case .final:
                "This is the final payment reminder for invoice \(invoiceNumber). The outstanding amount of \(amountDue) was originally due on \(originalDueDate)."
            }
        case .dutch:
            switch level {
            case .friendly:
                "Dit is een vriendelijke betalingsherinnering voor factuur \(invoiceNumber). Het openstaande bedrag van \(amountDue) had oorspronkelijk betaald moeten zijn op \(originalDueDate)."
            case .second:
                "Dit is een tweede betalingsherinnering voor factuur \(invoiceNumber). Het openstaande bedrag van \(amountDue) had oorspronkelijk betaald moeten zijn op \(originalDueDate)."
            case .final:
                "Dit is de laatste betalingsherinnering voor factuur \(invoiceNumber). Het openstaande bedrag van \(amountDue) had oorspronkelijk betaald moeten zijn op \(originalDueDate)."
            }
        case .german:
            switch level {
            case .friendly:
                "Dies ist eine freundliche Zahlungserinnerung für Rechnung \(invoiceNumber). Der offene Betrag von \(amountDue) war ursprünglich am \(originalDueDate) fällig."
            case .second:
                "Dies ist eine zweite Zahlungserinnerung für Rechnung \(invoiceNumber). Der offene Betrag von \(amountDue) war ursprünglich am \(originalDueDate) fällig."
            case .final:
                "Dies ist die letzte Zahlungserinnerung für Rechnung \(invoiceNumber). Der offene Betrag von \(amountDue) war ursprünglich am \(originalDueDate) fällig."
            }
        }
    }

    func reminderPaymentDeadline(_ deadline: String) -> String {
        switch locale {
        case .english:
            "Please pay no later than \(deadline)."
        case .dutch:
            "Wij verzoeken je om uiterlijk op \(deadline) te betalen."
        case .german:
            "Bitte zahlen Sie spätestens bis zum \(deadline)."
        }
    }

    func reminderDisregardNotice() -> String {
        switch locale {
        case .english:
            "If payment has already been made, you can disregard this reminder."
        case .dutch:
            "Als de betaling al is voldaan, kun je deze herinnering als niet verzonden beschouwen."
        case .german:
            "Falls die Zahlung bereits erfolgt ist, können Sie diese Erinnerung als gegenstandslos betrachten."
        }
    }

    func reminderClosing() -> String {
        switch locale {
        case .english:
            "Kind regards,"
        case .dutch:
            "Met vriendelijke groet,"
        case .german:
            "Mit freundlichen Grüßen,"
        }
    }

    enum Key: String {
        case tabDashboard
        case tabAgenda
        case tabRegistrations
        case tabClients
        case tabProducts
        case tabInvoices
        case tabSettings
        case settingsAlertTitle
        case settingsHeroTitle
        case settingsHeroSubtitle
        case invoicesAndFieldWork
        case brandProfileTitle
        case yourCompany
        case addCompanyProfileHint
        case activeCompany
        case owner
        case email
        case noActiveCompanyProfile
        case addCompanyProfile
        case manageCompanyProfile
        case languageAppearance
        case language
        case followSystemAppearance
        case colorMode
        case appTheme
        case invoiceNumbering
        case invoicePrefix
        case sequenceDigits
        case preview
        case billingDefaults
        case defaultPaymentTerm
        case days
        case defaultVAT
        case appliedTo
        case appliedToInvoiceLines
        case shortcuts
        case shortcutsDescription
        case addOrManageCompanyProfile
        case saveChanges
        case saveChangesDescription
        case saveSettings
        case settingsSaved
        case exportAndShare
        case sendByEmail
        case exportPDF
        case exportDOCX
        case attachments
        case addAttachment
        case noAttachments
        case linkedMileage
        case noMileageLinked
        case totals
        case subtotal
        case extraCharges
        case travelCosts
        case materialCosts
        case manualAdjustments
        case gross
        case discounts
        case netSubtotal
        case vat
        case total
        case grossAmount
        case youKeep
        case attachmentImportFailed
        case unableToSaveReminder
        case emailReady
        case emailFailed
        case exportFailed
        case emailSent
        case emailPreparationSaved
        case emailCouldNotBeSent
        case unknownMailResult
        case sent
        case savedAsDraft

        var values: [SupportedLocale: String] {
            switch self {
            case .tabDashboard: [.english: "Dashboard", .dutch: "Dashboard", .german: "Dashboard"]
            case .tabAgenda: [.english: "Agenda", .dutch: "Agenda", .german: "Agenda"]
            case .tabRegistrations: [.english: "Registrations", .dutch: "Registraties", .german: "Erfassungen"]
            case .tabClients: [.english: "Clients", .dutch: "Klanten", .german: "Kunden"]
            case .tabProducts: [.english: "Products", .dutch: "Producten", .german: "Produkte"]
            case .tabInvoices: [.english: "Invoices", .dutch: "Facturen", .german: "Rechnungen"]
            case .tabSettings: [.english: "Settings", .dutch: "Instellingen", .german: "Einstellungen"]
            case .settingsAlertTitle: [.english: "Settings", .dutch: "Instellingen", .german: "Einstellungen"]
            case .settingsHeroTitle: [.english: "App settings", .dutch: "App-instellingen", .german: "App-Einstellungen"]
            case .settingsHeroSubtitle: [.english: "Personalize your app theme, brand it with your company profile and logo, and control invoicing defaults from one place.", .dutch: "Personaliseer je app-thema, gebruik je bedrijfsprofiel en logo, en beheer factuurstandaarden op één plek.", .german: "Passe dein App-Design an, nutze dein Firmenprofil und Logo und verwalte Rechnungsvorgaben an einem Ort."]
            case .invoicesAndFieldWork: [.english: "Invoices and field work", .dutch: "Facturen en werkregistratie", .german: "Rechnungen und Arbeitserfassung"]
            case .brandProfileTitle: [.english: "Brand and company profile", .dutch: "Merk en bedrijfsprofiel", .german: "Marke und Firmenprofil"]
            case .yourCompany: [.english: "Your company", .dutch: "Je bedrijf", .german: "Dein Unternehmen"]
            case .addCompanyProfileHint: [.english: "Add a company profile to brand exports", .dutch: "Voeg een bedrijfsprofiel toe voor exports", .german: "Füge ein Firmenprofil für Exporte hinzu"]
            case .activeCompany: [.english: "Active company", .dutch: "Actief bedrijf", .german: "Aktives Unternehmen"]
            case .owner: [.english: "Owner", .dutch: "Eigenaar", .german: "Inhaber"]
            case .email: [.english: "Email", .dutch: "E-mail", .german: "E-Mail"]
            case .noActiveCompanyProfile: [.english: "No active company profile yet. Add one to use your business name and logo across invoices, quotes, and exported files.", .dutch: "Er is nog geen actief bedrijfsprofiel. Voeg er één toe om je bedrijfsnaam en logo te gebruiken op facturen, offertes en exports.", .german: "Es gibt noch kein aktives Firmenprofil. Füge eines hinzu, um Firmenname und Logo auf Rechnungen, Angeboten und Exporten zu verwenden."]
            case .addCompanyProfile: [.english: "Add Company Profile", .dutch: "Bedrijfsprofiel toevoegen", .german: "Firmenprofil hinzufügen"]
            case .manageCompanyProfile: [.english: "Manage Company Profile", .dutch: "Bedrijfsprofiel beheren", .german: "Firmenprofil verwalten"]
            case .languageAppearance: [.english: "Language and appearance", .dutch: "Taal en weergave", .german: "Sprache und Darstellung"]
            case .language: [.english: "Language", .dutch: "Taal", .german: "Sprache"]
            case .followSystemAppearance: [.english: "Follow system appearance", .dutch: "Volg systeemweergave", .german: "Systemdarstellung verwenden"]
            case .colorMode: [.english: "Color mode", .dutch: "Kleurmodus", .german: "Farbmodus"]
            case .appTheme: [.english: "App theme", .dutch: "App-thema", .german: "App-Design"]
            case .invoiceNumbering: [.english: "Invoice numbering", .dutch: "Factuurnummering", .german: "Rechnungsnummerierung"]
            case .invoicePrefix: [.english: "Invoice prefix", .dutch: "Factuurvoorvoegsel", .german: "Rechnungspräfix"]
            case .sequenceDigits: [.english: "Sequence digits", .dutch: "Aantal cijfers", .german: "Anzahl Ziffern"]
            case .preview: [.english: "Preview", .dutch: "Voorbeeld", .german: "Vorschau"]
            case .billingDefaults: [.english: "Billing defaults", .dutch: "Factuurstandaarden", .german: "Rechnungsvorgaben"]
            case .defaultPaymentTerm: [.english: "Default payment term", .dutch: "Standaard betaaltermijn", .german: "Standard-Zahlungsfrist"]
            case .days: [.english: "days", .dutch: "dagen", .german: "Tage"]
            case .defaultVAT: [.english: "Default VAT (%)", .dutch: "Standaard btw (%)", .german: "Standard-MwSt. (%)"]
            case .appliedTo: [.english: "Applied to", .dutch: "Toegepast op", .german: "Angewendet auf"]
            case .appliedToInvoiceLines: [.english: "New manual invoice lines and general work invoice lines", .dutch: "Nieuwe handmatige factuurregels en algemene werkregels", .german: "Neue manuelle Rechnungszeilen und allgemeine Arbeitszeilen"]
            case .shortcuts: [.english: "Shortcuts", .dutch: "Snelkoppelingen", .german: "Verknüpfungen"]
            case .shortcutsDescription: [.english: "Business profile data stays separate from app settings, but you can jump there directly.", .dutch: "Bedrijfsgegevens blijven gescheiden van app-instellingen, maar je kunt er direct naartoe.", .german: "Firmendaten bleiben von App-Einstellungen getrennt, sind aber direkt erreichbar."]
            case .addOrManageCompanyProfile: [.english: "Add or Manage Company Profile", .dutch: "Bedrijfsprofiel toevoegen of beheren", .german: "Firmenprofil hinzufügen oder verwalten"]
            case .saveChanges: [.english: "Save changes", .dutch: "Wijzigingen opslaan", .german: "Änderungen speichern"]
            case .saveChangesDescription: [.english: "Changes are stored in SwiftData and update the app immediately after saving.", .dutch: "Wijzigingen worden opgeslagen in SwiftData en direct toegepast na opslaan.", .german: "Änderungen werden in SwiftData gespeichert und nach dem Speichern direkt angewendet."]
            case .saveSettings: [.english: "Save Settings", .dutch: "Instellingen opslaan", .german: "Einstellungen speichern"]
            case .settingsSaved: [.english: "Settings saved.", .dutch: "Instellingen opgeslagen.", .german: "Einstellungen gespeichert."]
            case .exportAndShare: [.english: "Export and share", .dutch: "Exporteren en delen", .german: "Exportieren und teilen"]
            case .sendByEmail: [.english: "Send by email", .dutch: "Verstuur per e-mail", .german: "Per E-Mail senden"]
            case .exportPDF: [.english: "Export PDF", .dutch: "Exporteer PDF", .german: "PDF exportieren"]
            case .exportDOCX: [.english: "Export DOCX", .dutch: "Exporteer DOCX", .german: "DOCX exportieren"]
            case .attachments: [.english: "Attachments", .dutch: "Bijlagen", .german: "Anhänge"]
            case .addAttachment: [.english: "Add Attachment", .dutch: "Bijlage toevoegen", .german: "Anhang hinzufügen"]
            case .noAttachments: [.english: "No attachments yet.", .dutch: "Nog geen bijlagen.", .german: "Noch keine Anhänge."]
            case .linkedMileage: [.english: "Linked mileage", .dutch: "Gekoppelde kilometers", .german: "Verknüpfte Kilometer"]
            case .noMileageLinked: [.english: "No mileage entries linked.", .dutch: "Geen kilometerregistraties gekoppeld.", .german: "Keine Kilometererfassungen verknüpft."]
            case .totals: [.english: "Totals", .dutch: "Totalen", .german: "Summen"]
            case .subtotal: [.english: "Subtotal", .dutch: "Subtotaal", .german: "Zwischensumme"]
            case .extraCharges: [.english: "Extra charges", .dutch: "Extra kosten", .german: "Zusatzkosten"]
            case .travelCosts: [.english: "Travel costs", .dutch: "Reiskosten", .german: "Reisekosten"]
            case .materialCosts: [.english: "Material costs", .dutch: "Materiaalkosten", .german: "Materialkosten"]
            case .manualAdjustments: [.english: "Manual adjustments", .dutch: "Handmatige correcties", .german: "Manuelle Korrekturen"]
            case .gross: [.english: "Gross", .dutch: "Bruto", .german: "Brutto"]
            case .discounts: [.english: "Discounts", .dutch: "Kortingen", .german: "Rabatte"]
            case .netSubtotal: [.english: "Net subtotal", .dutch: "Netto subtotaal", .german: "Netto-Zwischensumme"]
            case .vat: [.english: "VAT", .dutch: "Btw", .german: "MwSt."]
            case .total: [.english: "Total", .dutch: "Totaal", .german: "Gesamt"]
            case .grossAmount: [.english: "Gross amount", .dutch: "Brutobedrag", .german: "Bruttobetrag"]
            case .youKeep: [.english: "You keep", .dutch: "Jij houdt over", .german: "Du behältst"]
            case .attachmentImportFailed: [.english: "Attachment Import Failed", .dutch: "Bijlage importeren mislukt", .german: "Anhangimport fehlgeschlagen"]
            case .unableToSaveReminder: [.english: "Unable to Save Reminder", .dutch: "Herinnering opslaan mislukt", .german: "Erinnerung konnte nicht gespeichert werden"]
            case .emailReady: [.english: "Email Ready", .dutch: "E-mail klaar", .german: "E-Mail bereit"]
            case .emailFailed: [.english: "Email Failed", .dutch: "E-mail mislukt", .german: "E-Mail fehlgeschlagen"]
            case .exportFailed: [.english: "Export Failed", .dutch: "Export mislukt", .german: "Export fehlgeschlagen"]
            case .emailSent: [.english: "Invoice email sent.", .dutch: "Factuurmail verzonden.", .german: "Rechnungs-E-Mail gesendet."]
            case .emailPreparationSaved: [.english: "Email preparation saved.", .dutch: "E-mailvoorbereiding opgeslagen.", .german: "E-Mail-Vorbereitung gespeichert."]
            case .emailCouldNotBeSent: [.english: "The email could not be sent.", .dutch: "De e-mail kon niet worden verzonden.", .german: "Die E-Mail konnte nicht gesendet werden."]
            case .unknownMailResult: [.english: "An unknown Mail result occurred.", .dutch: "Er is een onbekend Mail-resultaat opgetreden.", .german: "Es ist ein unbekanntes Mail-Ergebnis aufgetreten."]
            case .sent: [.english: "Sent", .dutch: "Verzonden", .german: "Gesendet"]
            case .savedAsDraft: [.english: "Saved as draft", .dutch: "Opgeslagen als concept", .german: "Als Entwurf gespeichert"]
            }
        }
    }

    private var phrases: [String: [SupportedLocale: String]] {
        [
            "Clients": [.dutch: "Klanten", .german: "Kunden"],
            "Products": [.dutch: "Producten", .german: "Produkte"],
            "Client": [.dutch: "Klant", .german: "Kunde"],
            "Product": [.dutch: "Product", .german: "Produkt"],
            "Company": [.dutch: "Bedrijf", .german: "Unternehmen"],
            "Details": [.dutch: "Gegevens", .german: "Details"],
            "Contact": [.dutch: "Contact", .german: "Kontakt"],
            "Business": [.dutch: "Zakelijk", .german: "Geschäftlich"],
            "Notes": [.dutch: "Notities", .german: "Notizen"],
            "Name": [.dutch: "Naam", .german: "Name"],
            "Description": [.dutch: "Beschrijving", .german: "Beschreibung"],
            "Contact person": [.dutch: "Contactpersoon", .german: "Ansprechpartner"],
            "Phone": [.dutch: "Telefoon", .german: "Telefon"],
            "Address": [.dutch: "Adres", .german: "Adresse"],
            "Payment term": [.dutch: "Betaaltermijn", .german: "Zahlungsfrist"],
            "Default invoice email": [.dutch: "Standaard factuurmail", .german: "Standard-Rechnungs-E-Mail"],
            "Default subject": [.dutch: "Standaard onderwerp", .german: "Standard-Betreff"],
            "Default message": [.dutch: "Standaard bericht", .german: "Standardnachricht"],
            "Available placeholders: {client}, {contact}, {invoiceNumber}, {invoiceDate}, {dueDate}, {amount}, {company}, {owner}": [.dutch: "Beschikbare placeholders: {client}, {contact}, {invoiceNumber}, {invoiceDate}, {dueDate}, {amount}, {company}, {owner}", .german: "Verfugbare Platzhalter: {client}, {contact}, {invoiceNumber}, {invoiceDate}, {dueDate}, {amount}, {company}, {owner}"],
            "Theme applied.": [.dutch: "Thema toegepast.", .german: "Design angewendet."],
            "Brand & company": [.dutch: "Merk en bedrijf", .german: "Marke und Unternehmen"],
            "Company profile and logo settings.": [.dutch: "Bedrijfsprofiel en logo-instellingen.", .german: "Unternehmensprofil und Logo-Einstellungen."],
            "Appearance": [.dutch: "Weergave", .german: "Darstellung"],
            "Language, theme and app icon.": [.dutch: "Taal, thema en app-icoon.", .german: "Sprache, Thema und App-Symbol."],
            "Documents": [.dutch: "Documenten", .german: "Dokumente"],
            "Numbering and document styles.": [.dutch: "Nummering en documentstijlen.", .german: "Nummerierung und Dokumentstile."],
            "Defaults": [.dutch: "Standaarden", .german: "Standards"],
            "Billing and email defaults.": [.dutch: "Standaarden voor facturatie en e-mail.", .german: "Standards für Abrechnung und E-Mail."],
            "Shortcuts and save.": [.dutch: "Snelkoppelingen en opslaan.", .german: "Kurzbefehle und Speichern."],
            "App icon": [.dutch: "App-icoon", .german: "App-Symbol"],
            "Choose the icon shown on the Home Screen.": [.dutch: "Kies welk icoon op het beginscherm wordt getoond.", .german: "Wähle, welches Symbol auf dem Home-Bildschirm angezeigt wird."],
            "Default icon": [.dutch: "Standaard icoon", .german: "Standardsymbol"],
            "Dark icon": [.dutch: "Donker icoon", .german: "Dunkles Symbol"],
            "Tinted icon": [.dutch: "Getint icoon", .german: "Getöntes Symbol"],
            "Uses the regular app icon.": [.dutch: "Gebruikt het gewone app-icoon.", .german: "Verwendet das normale App-Symbol."],
            "Uses the dark app icon.": [.dutch: "Gebruikt het donkere app-icoon.", .german: "Verwendet das dunkle App-Symbol."],
            "Uses the tinted app icon.": [.dutch: "Gebruikt het getinte app-icoon.", .german: "Verwendet das getönte App-Symbol."],
            "This device does not support alternate app icons.": [.dutch: "Dit apparaat ondersteunt geen alternatieve app-iconen.", .german: "Dieses Gerät unterstützt keine alternativen App-Symbole."],
            "Unable to change app icon.": [.dutch: "App-icoon wijzigen mislukt.", .german: "App-Symbol konnte nicht geändert werden."],
            "App icon updated.": [.dutch: "App-icoon bijgewerkt.", .german: "App-Symbol aktualisiert."],
            "Hourly rate": [.dutch: "Uurtarief", .german: "Stundensatz"],
            "Default hourly rate": [.dutch: "Standaard uurtarief", .german: "Standard-Stundensatz"],
            "Client name": [.dutch: "Klantnaam", .german: "Kundenname"],
            "Notes about client": [.dutch: "Notities over klant", .german: "Notizen zum Kunden"],
            "New client": [.dutch: "Nieuwe klant", .german: "Neuer Kunde"],
            "Edit client": [.dutch: "Klant bewerken", .german: "Kunde bearbeiten"],
            "New product": [.dutch: "Nieuw product", .german: "Neues Produkt"],
            "Edit product": [.dutch: "Product bewerken", .german: "Produkt bearbeiten"],
            "Product name": [.dutch: "Productnaam", .german: "Produktname"],
            "Pricing": [.dutch: "Prijsstelling", .german: "Preise"],
            "Price": [.dutch: "Prijs", .german: "Preis"],
            "VAT rate": [.dutch: "Btw-tarief", .german: "MwSt.-Satz"],
            "Unit type": [.dutch: "Eenheid", .german: "Einheit"],
            "Usage": [.dutch: "Gebruik", .german: "Nutzung"],
            "Work entries": [.dutch: "Registraties", .german: "Erfassungen"],
            "Quote lines": [.dutch: "Offerteregels", .german: "Angebotszeilen"],
            "Related": [.dutch: "Gekoppeld", .german: "Verknüpft"],
            "Client history": [.dutch: "Klanthistorie", .german: "Kundenhistorie"],
            "Total registered hours": [.dutch: "Totaal geregistreerde uren", .german: "Erfasste Stunden gesamt"],
            "Total invoice revenue": [.dutch: "Totale factuuromzet", .german: "Gesamter Rechnungsumsatz"],
            "Last registration": [.dutch: "Laatste registratie", .german: "Letzte Erfassung"],
            "Last invoice": [.dutch: "Laatste factuur", .german: "Letzte Rechnung"],
            "Recent registrations": [.dutch: "Recente registraties", .german: "Letzte Erfassungen"],
            "Recent invoices": [.dutch: "Recente facturen", .german: "Letzte Rechnungen"],
            "Recent quotes": [.dutch: "Recente offertes", .german: "Letzte Angebote"],
            "Invoices": [.dutch: "Facturen", .german: "Rechnungen"],
            "Quotes": [.dutch: "Offertes", .german: "Angebote"],
            "No email": [.dutch: "Geen e-mail", .german: "Keine E-Mail"],
            "Not set": [.dutch: "Niet ingesteld", .german: "Nicht festgelegt"],
            "None": [.dutch: "Geen", .german: "Keine"],
            "Edit": [.dutch: "Bewerk", .german: "Bearbeiten"],
            "Delete": [.dutch: "Verwijder", .german: "Löschen"],
            "Cancel": [.dutch: "Annuleer", .german: "Abbrechen"],
            "Save": [.dutch: "Bewaar", .german: "Speichern"],
            "Search clients": [.dutch: "Klanten zoeken", .german: "Kunden suchen"],
            "Search products": [.dutch: "Producten zoeken", .german: "Produkte suchen"],
            "Unable to Delete Client": [.dutch: "Klant verwijderen mislukt", .german: "Kunde kann nicht gelöscht werden"],
            "Unable to Delete Product": [.dutch: "Product verwijderen mislukt", .german: "Produkt kann nicht gelöscht werden"],
            "Delete Invoice": [.dutch: "Factuur verwijderen", .german: "Rechnung löschen"],
            "Delete Credit Invoice": [.dutch: "Creditfactuur verwijderen", .german: "Gutschrift löschen"],
            "Delete Quote": [.dutch: "Offerte verwijderen", .german: "Angebot löschen"],
            "Unable to Delete Invoice": [.dutch: "Factuur verwijderen mislukt", .german: "Rechnung kann nicht gelöscht werden"],
            "Unable to Delete Credit Invoice": [.dutch: "Creditfactuur verwijderen mislukt", .german: "Gutschrift kann nicht gelöscht werden"],
            "Unable to Delete Quote": [.dutch: "Offerte verwijderen mislukt", .german: "Angebot kann nicht gelöscht werden"],
            "This invoice will be removed permanently. Linked reminders, attachments, and signature data will also be deleted.": [.dutch: "Deze factuur wordt definitief verwijderd. Gekoppelde herinneringen, bijlagen en handtekeningdata worden ook verwijderd.", .german: "Diese Rechnung wird dauerhaft entfernt. Verknüpfte Erinnerungen, Anhänge und Signaturdaten werden ebenfalls gelöscht."],
            "This credit invoice will be removed permanently.": [.dutch: "Deze creditfactuur wordt definitief verwijderd.", .german: "Diese Gutschrift wird dauerhaft entfernt."],
            "This quote will be removed permanently.": [.dutch: "Deze offerte wordt definitief verwijderd.", .german: "Dieses Angebot wird dauerhaft entfernt."],
            "This client has linked work entries, invoices, or quotes and cannot be deleted.": [.dutch: "Deze klant heeft gekoppelde registraties, facturen of offertes en kan niet worden verwijderd.", .german: "Dieser Kunde hat verknüpfte Erfassungen, Rechnungen oder Angebote und kann nicht gelöscht werden."],
            "This product is linked to work entries or quotes and cannot be deleted.": [.dutch: "Dit product is gekoppeld aan registraties of offertes en kan niet worden verwijderd.", .german: "Dieses Produkt ist mit Erfassungen oder Angeboten verknüpft und kann nicht gelöscht werden."],
            "Enter a valid price.": [.dutch: "Vul een geldige prijs in.", .german: "Gib einen gültigen Preis ein."],
            "Enter a valid hourly rate.": [.dutch: "Vul een geldig uurtarief in.", .german: "Gib einen gültigen Stundensatz ein."],
            "Hour": [.dutch: "Uur", .german: "Stunde"],
            "Piece": [.dutch: "Stuk", .german: "Stück"],
            "Day": [.dutch: "Dag", .german: "Tag"],
            "Fixed": [.dutch: "Vast", .german: "Pauschal"],
            "Draft": [.dutch: "Concept", .german: "Entwurf"],
            "Paid": [.dutch: "Betaald", .german: "Bezahlt"],
            "Overdue": [.dutch: "Achterstallig", .german: "Überfällig"],
            "Open": [.dutch: "Open", .german: "Offen"],
            "Dashboard quick invoice": [.dutch: "Dashboard snelle factuur", .german: "Dashboard-Schnellrechnung"],
            "Dashboard": [.dutch: "Dashboard", .german: "Dashboard"],
            "Credited this month": [.dutch: "Deze maand gecrediteerd", .german: "Diesen Monat gutgeschrieben"],
            "Credit invoices issued": [.dutch: "Creditfacturen uitgegeven", .german: "Erstellte Gutschriften"],
            "Gross": [.dutch: "Bruto", .german: "Brutto"],
            "Logo theme": [.dutch: "Logothema", .german: "Logo-Design"],
            "Ocean": [.dutch: "Oceaan", .german: "Ozean"],
            "Forest": [.dutch: "Bos", .german: "Wald"],
            "Amber": [.dutch: "Amber", .german: "Amber"],
            "Rose": [.dutch: "Roos", .german: "Rosa"],
            "Slate": [.dutch: "Leisteen", .german: "Schiefer"],
            "Use logo color as app theme": [.dutch: "Gebruik logokleur als app-thema", .german: "Logofarbe als App-Design verwenden"],
            "Uses the dominant logo color as the app accent theme.": [.dutch: "Gebruikt de dominante logokleur als accentkleur van de app.", .german: "Verwendet die dominante Logofarbe als Akzentfarbe der App."],
            "Clean and professional blue for general business use.": [.dutch: "Helder en professioneel blauw voor algemeen zakelijk gebruik.", .german: "Klares, professionelles Blau für den allgemeinen Geschäftseinsatz."],
            "Calm green for a grounded and trustworthy look.": [.dutch: "Rustig groen voor een betrouwbare en stabiele uitstraling.", .german: "Ruhiges Grün für einen bodenständigen und vertrauenswürdigen Eindruck."],
            "Warm gold for a bold and energetic identity.": [.dutch: "Warm goud voor een krachtige en energieke identiteit.", .german: "Warmes Gold für eine markante und energiegeladene Identität."],
            "Expressive red for a more premium branded feel.": [.dutch: "Expressief rood voor een meer premium merkuitstraling.", .german: "Ausdrucksstarkes Rot für einen hochwertigeren Markenauftritt."],
            "Neutral graphite for a restrained, minimal theme.": [.dutch: "Neutraal grafiet voor een ingetogen, minimaal thema.", .german: "Neutrales Graphit für ein zurückhaltendes, minimalistisches Design."],
            "Credit preview": [.dutch: "Creditvoorbeeld", .german: "Gutschriftvorschau"],
            "Document versions": [.dutch: "Documentversies", .german: "Dokumentvarianten"],
            "Invoice version": [.dutch: "Factuurversie", .german: "Rechnungsversion"],
            "Quote version": [.dutch: "Offerteversie", .german: "Angebotsversion"],
            "Invoice sample": [.dutch: "Factuurvoorbeeld", .german: "Rechnungsmuster"],
            "Quote sample": [.dutch: "Offertevoorbeeld", .german: "Angebotsmuster"],
            "Classic": [.dutch: "Klassiek", .german: "Klassisch"],
            "Premium": [.dutch: "Premium", .german: "Premium"],
            "Compact": [.dutch: "Compact", .german: "Kompakt"],
            "Bold": [.dutch: "Vet", .german: "Prägnant"],
            "Rustig, herkenbaar en zakelijk.": [.english: "Calm, familiar, and businesslike.", .german: "Ruhig, vertraut und geschäftlich."],
            "Meer contrast, zachte panelen en moderne accenten.": [.english: "More contrast, soft panels, and modern accents.", .german: "Mehr Kontrast, weiche Flächen und moderne Akzente."],
            "Strakker en compacter voor veel regels.": [.english: "Tighter and more compact for many line items.", .german: "Kompakter und straffer für viele Positionen."],
            "Sterke kop, donkere balken en opvallende totalen.": [.english: "Strong header, dark bars, and prominent totals.", .german: "Starker Kopfbereich, dunkle Balken und markante Summen."],
            "You keep": [.dutch: "Jij houdt over", .german: "Du behältst"],
            "Weekly split": [.dutch: "Weekverdeling", .german: "Wochenaufteilung"],
            "open": [.dutch: "open", .german: "offen"],
            "h logged": [.dutch: "u geregistreerd", .german: "Std. erfasst"],
            "accepted quotes": [.dutch: "geaccepteerde offertes", .german: "angenommene Angebote"],
            "End-of-week billing": [.dutch: "Weekafsluiting facturatie", .german: "Wochenabschluss Abrechnung"],
            "Open Weekly Review": [.dutch: "Open weekcontrole", .german: "Wochenprüfung öffnen"],
            "Quick actions": [.dutch: "Snelle acties", .german: "Schnellaktionen"],
            "Annual revenue summary": [.dutch: "Jaaromzetoverzicht", .german: "Jahresumsatzübersicht"],
            "Review yearly revenue, VAT, delivered work, and top clients in one business snapshot.": [.dutch: "Bekijk jaaromzet, btw, geleverd werk en topklanten in één zakelijk overzicht.", .german: "Prüfe Jahresumsatz, MwSt., geleistete Arbeit und Top-Kunden in einer Geschäftsübersicht."],
            "Freelancer overview": [.dutch: "Freelancer-overzicht", .german: "Freelancer-Übersicht"],
            "Freelancer": [.dutch: "Freelancer", .german: "Freelancer"],
            "Business overview": [.dutch: "Bedrijfsoverzicht", .german: "Geschäftsübersicht"],
            "All overview": [.dutch: "Alles-overzicht", .german: "Alles-Übersicht"],
            "Custom overview": [.dutch: "Aangepast overzicht", .german: "Benutzerdefinierte Übersicht"],
            "Track hours, registrations, uninvoiced work, and invoice progress from one focused dashboard.": [.dutch: "Volg uren, registraties, niet-gefactureerd werk en factuurvoortgang vanuit één dashboard.", .german: "Verfolge Stunden, Erfassungen, nicht abgerechnete Arbeit und Rechnungsfortschritt in einem Dashboard."],
            "Track quotes, invoices, and client-facing business activity without operational noise.": [.dutch: "Volg offertes, facturen en klantgerichte bedrijfsactiviteit zonder operationele ruis.", .german: "Verfolge Angebote, Rechnungen und kundenbezogene Aktivitäten ohne operatives Rauschen."],
            "Follow every workflow and business tool in one complete overview.": [.dutch: "Volg elke workflow en zakelijke tool in één compleet overzicht.", .german: "Verfolge jeden Workflow und jedes Geschäftstool in einer vollständigen Übersicht."],
            "Follow the exact workflows and modules you enabled for this business.": [.dutch: "Volg precies de workflows en modules die je voor dit bedrijf hebt ingeschakeld.", .german: "Verfolge genau die Workflows und Module, die du für dieses Unternehmen aktiviert hast."],
            "Agenda day invoice": [.dutch: "Agenda dagfactuur", .german: "Agenda-Tagesrechnung"],
            "Agenda registration invoice": [.dutch: "Agenda registratiefactuur", .german: "Agenda-Erfassungsrechnung"],
            "This week": [.dutch: "Deze week", .german: "Diese Woche"],
            "entries": [.dutch: "registraties", .german: "Einträge"],
            "Add Entry": [.dutch: "Registratie toevoegen", .german: "Eintrag hinzufügen"],
            "Invoice Open Work": [.dutch: "Open werk factureren", .german: "Offene Arbeit abrechnen"],
            "No work entries scheduled for this day yet.": [.dutch: "Nog geen registraties gepland voor deze dag.", .german: "Für diesen Tag sind noch keine Einträge geplant."],
            "Weekly review": [.dutch: "Weekcontrole", .german: "Wochenprüfung"],
            "Open Friday Review": [.dutch: "Open vrijdagcontrole", .german: "Freitagsprüfung öffnen"],
            "Week overview": [.dutch: "Weekoverzicht", .german: "Wochenübersicht"],
            "work entries": [.dutch: "registraties", .german: "Arbeitseinträge"]
            ,
            "Hours this week": [.dutch: "Uren deze week", .german: "Stunden diese Woche"],
            "Tracked this week": [.dutch: "Deze week geregistreerd", .german: "Diese Woche erfasst"],
            "Registrations": [.dutch: "Registraties", .german: "Erfassungen"],
            "Work logs this week": [.dutch: "Werklogs deze week", .german: "Arbeitsprotokolle diese Woche"],
            "Uninvoiced work": [.dutch: "Niet-gefactureerd werk", .german: "Nicht abgerechnete Arbeit"],
            "Entries still open": [.dutch: "Registraties nog open", .german: "Einträge noch offen"],
            "Weekly revenue": [.dutch: "Weekomzet", .german: "Wochenumsatz"],
            "Invoices dated this week": [.dutch: "Facturen van deze week", .german: "Rechnungen dieser Woche"],
            "Monthly revenue": [.dutch: "Maandomzet", .german: "Monatsumsatz"],
            "Invoices dated this month": [.dutch: "Facturen van deze maand", .german: "Rechnungen dieses Monats"],
            "Open invoices": [.dutch: "Open facturen", .german: "Offene Rechnungen"],
            "Draft and sent invoices": [.dutch: "Concepten en verzonden facturen", .german: "Entwürfe und gesendete Rechnungen"],
            "Open quotes": [.dutch: "Open offertes", .german: "Offene Angebote"],
            "Draft and sent quotes": [.dutch: "Concepten en verzonden offertes", .german: "Entwürfe und gesendete Angebote"],
            "Accepted quotes": [.dutch: "Geaccepteerde offertes", .german: "Angenommene Angebote"],
            "Ready for invoicing": [.dutch: "Klaar om te factureren", .german: "Bereit zur Abrechnung"],
            "Awaiting payment": [.dutch: "Wacht op betaling", .german: "Warten auf Zahlung"],
            "Tracked work": [.dutch: "Geregistreerd werk", .german: "Erfasste Arbeit"],
            "Products delivered": [.dutch: "Geleverde producten", .german: "Gelieferte Produkte"],
            "Delivered this week": [.dutch: "Deze week geleverd", .german: "Diese Woche geliefert"],
            "Add new Work Entry": [.dutch: "Nieuwe registratie", .german: "Neue Erfassung"],
            "Jump into this week's registrations": [.dutch: "Ga direct naar de registraties van deze week", .german: "Direkt zu den Erfassungen dieser Woche"],
            "Create Invoice": [.dutch: "Factuur maken", .german: "Rechnung erstellen"],
            "Open the billing workspace": [.dutch: "Open de factuurwerkruimte", .german: "Abrechnungsbereich öffnen"],
            "Jump into suggested uninvoiced work": [.dutch: "Ga naar voorgesteld niet-gefactureerd werk", .german: "Zu vorgeschlagener nicht abgerechneter Arbeit"],
            "Weekly Review": [.dutch: "Weekcontrole", .german: "Wochenprüfung"],
            "Prepare Friday billing checks": [.dutch: "Bereid de vrijdagcontrole voor", .german: "Freitagsabrechnung vorbereiten"],
            "open registrations this week": [.dutch: "open registraties deze week", .german: "offene Erfassungen diese Woche"],
            "Open Agenda": [.dutch: "Open agenda", .german: "Agenda öffnen"],
            "Review this week's planning": [.dutch: "Bekijk de planning van deze week", .german: "Planung dieser Woche prüfen"],
            "Review proposals and pipeline": [.dutch: "Bekijk voorstellen en pijplijn", .german: "Angebote und Pipeline prüfen"],
            "Open Clients": [.dutch: "Open klanten", .german: "Kunden öffnen"],
            "Manage client relationships": [.dutch: "Beheer klantrelaties", .german: "Kundenbeziehungen verwalten"],
            "Review proposals and accepted work": [.dutch: "Bekijk voorstellen en geaccepteerd werk", .german: "Angebote und angenommene Arbeit prüfen"]
            ,
            "Loading invoices": [.dutch: "Facturen laden", .german: "Rechnungen werden geladen"],
            "Invoice history": [.dutch: "Factuurhistorie", .german: "Rechnungshistorie"],
            "Search by invoice number or client": [.dutch: "Zoek op factuurnummer of klant", .german: "Nach Rechnungsnummer oder Kunde suchen"],
            "All Clients": [.dutch: "Alle klanten", .german: "Alle Kunden"],
            "This Week": [.dutch: "Deze week", .german: "Diese Woche"],
            "This Month": [.dutch: "Deze maand", .german: "Dieser Monat"],
            "Previous Week": [.dutch: "Vorige week", .german: "Letzte Woche"],
            "Previous Month": [.dutch: "Vorige maand", .german: "Letzter Monat"],
            "Invoiced": [.dutch: "Gefactureerd", .german: "Abgerechnet"],
            "Work Confirmation": [.dutch: "Werkbevestiging", .german: "Arbeitsbestätigung"],
            "Invoice period split": [.dutch: "Factuurperiode verdeling", .german: "Aufteilung Rechnungszeitraum"],
            "Hours": [.dutch: "Uren", .german: "Stunden"],
            "Billable": [.dutch: "Factureerbaar", .german: "Abrechenbar"],
            "Value": [.dutch: "Waarde", .german: "Wert"],
            "Pending": [.dutch: "Open", .german: "Ausstehend"],
            "Partner": [.dutch: "Partner", .german: "Partner"],
            "Keep": [.dutch: "Jij houdt", .german: "Du behältst"],
            "Marked for invoice": [.dutch: "Gemarkeerd voor factuur", .german: "Für Rechnung markiert"],
            "Hourly billing": [.dutch: "Facturatie op uren", .german: "Abrechnung nach Stunden"],
            "Not invoiced yet": [.dutch: "Nog niet gefactureerd", .german: "Noch nicht abgerechnet"],
            "Revenue share": [.dutch: "Omzetverdeling", .german: "Umsatzanteil"],
            "Net revenue": [.dutch: "Netto-omzet", .german: "Nettoerlös"],
            "Factuurperiode": [.english: "Invoice period", .german: "Rechnungszeitraum"],
            "Naar factuur": [.english: "To invoice", .german: "Zur Rechnung"],
            "Uren": [.english: "Hours", .german: "Stunden"],
            "Binnen deze selectie": [.english: "Within this selection", .german: "In dieser Auswahl"],
            "Factureerbaar": [.english: "Billable", .german: "Abrechenbar"],
            "Klaar voor factuur": [.english: "Ready for invoice", .german: "Bereit für Rechnung"],
            "Waarde": [.english: "Value", .german: "Wert"],
            "Op basis van tarief": [.english: "Based on rate", .german: "Auf Basis des Satzes"],
            "Nog niet gefactureerd": [.english: "Not invoiced yet", .german: "Noch nicht abgerechnet"],
            "Verdeling": [.english: "Split", .german: "Aufteilung"],
            "Jij houdt": [.english: "You keep", .german: "Du behältst"],
            "Netto na verdeling": [.english: "Net after split", .german: "Netto nach Aufteilung"],
            "Gebruik 'Naar factuur' om deze registraties direct in het factuurtabblad klaar te zetten.": [.english: "Use 'To invoice' to prepare these registrations directly in the invoice tab.", .german: "Nutze 'Zur Rechnung', um diese Erfassungen direkt im Rechnungstab vorzubereiten."],
            "Registration history": [.dutch: "Registratiehistorie", .german: "Erfassungshistorie"],
            "Search registrations": [.dutch: "Registraties zoeken", .german: "Erfassungen suchen"],
            "Shown": [.dutch: "Getoond", .german: "Angezeigt"],
            "Matching logs": [.dutch: "Overeenkomende logs", .german: "Passende Protokolle"],
            "Filtered hours": [.dutch: "Gefilterde uren", .german: "Gefilterte Stunden"],
            "Revenue": [.dutch: "Omzet", .german: "Umsatz"],
            "Filtered value": [.dutch: "Gefilterde waarde", .german: "Gefilterter Wert"],
            "Still open": [.dutch: "Nog open", .german: "Noch offen"],
            "Mileage tracking": [.dutch: "Kilometerregistratie", .german: "Kilometererfassung"],
            "Track trips, reimbursement costs, and optionally link them to invoices.": [.dutch: "Registreer ritten, vergoedingskosten en koppel ze optioneel aan facturen.", .german: "Erfasse Fahrten, Erstattungen und verknüpfe sie optional mit Rechnungen."],
            "Receipt storage": [.dutch: "Bonnenopslag", .german: "Belegablage"],
            "Keep expense proofs, receipt photos, and billing context organized in one place.": [.dutch: "Bewaar betaalbewijzen, bonfoto's en factuurcontext op één plek.", .german: "Bewahre Ausgabennachweise, Belegfotos und Rechnungskontext an einem Ort auf."],
            "Reading receipt details": [.dutch: "Bongegevens uitlezen", .german: "Belegdaten werden gelesen"],
            "Receipt details recognized": [.dutch: "Bongegevens herkend", .german: "Belegdaten erkannt"],
            "By day": [.dutch: "Per dag", .german: "Nach Tag"],
            "No time logs in the selected invoice period.": [.dutch: "Geen registraties in de geselecteerde factuurperiode.", .german: "Keine Zeiteinträge im ausgewählten Rechnungszeitraum."],
            "By client": [.dutch: "Per klant", .german: "Nach Kunde"],
            "No client hours available in the selected invoice period.": [.dutch: "Geen klanturen beschikbaar in de geselecteerde factuurperiode.", .german: "Keine Kundenstunden im ausgewählten Rechnungszeitraum verfügbar."],
            "Geen registraties gevonden in de gekozen periode.": [.english: "No registrations found in the selected period.", .german: "Keine Erfassungen im ausgewählten Zeitraum gefunden."],
            "Standaard tarief": [.english: "Default rate", .german: "Standardsatz"],
            "Aangepast tarief": [.english: "Custom rate", .german: "Angepasster Satz"],
            "Open factuur": [.english: "Open invoice", .german: "Rechnung öffnen"],
            "Maak factuur": [.english: "Create invoice", .german: "Rechnung erstellen"],
            "Neem op factuur": [.english: "Include on invoice", .german: "Auf Rechnung aufnehmen"],
            "Sign work": [.dutch: "Werk ondertekenen", .german: "Arbeit unterschreiben"],
            "Update signature": [.dutch: "Handtekening bijwerken", .german: "Unterschrift aktualisieren"],
            "Op factuur": [.english: "On invoice", .german: "Auf Rechnung"],
            "Deze registratie is al gekoppeld aan een factuurregel.": [.english: "This registration is already linked to an invoice line.", .german: "Diese Erfassung ist bereits mit einer Rechnungszeile verknüpft."],
            "Deze registratie is al gefactureerd.": [.english: "This registration has already been invoiced.", .german: "Diese Erfassung wurde bereits abgerechnet."],
            "Factuur vanuit registratie": [.english: "Invoice from registration", .german: "Rechnung aus Erfassung"],
            "Deze registratie kon niet naar de factuurworkflow worden gestuurd.": [.english: "This registration could not be sent to the invoice workflow.", .german: "Diese Erfassung konnte nicht an den Rechnungsworkflow gesendet werden."],
            "Bedrijf": [.english: "Company", .german: "Unternehmen"],
            "Planning": [.dutch: "Planning", .german: "Planung"],
            "Datum": [.english: "Date", .german: "Datum"],
            "Werkdetails": [.english: "Work details", .german: "Arbeitsdetails"],
            "Gewerkte uren": [.english: "Hours worked", .german: "Geleistete Stunden"],
            "Geen product": [.english: "No product", .german: "Kein Produkt"],
            "Laat product leeg als je dit puur op uren wilt factureren via het uurtarief van de klant.": [.english: "Leave product empty if you want to invoice this purely by hours using the client's hourly rate.", .german: "Lasse das Produkt leer, wenn du dies nur nach Stunden mit dem Stundensatz des Kunden abrechnen möchtest."],
            "Factureren op basis van uren": [.english: "Invoice based on hours", .german: "Nach Stunden abrechnen"],
            "Deze registratie gebruikt het uurtarief van de klant en laat het product leeg.": [.english: "This registration uses the client's hourly rate and leaves the product empty.", .german: "Diese Registrierung verwendet den Stundensatz des Kunden und lässt das Produkt leer."],
            "Aantal": [.english: "Quantity", .german: "Anzahl"],
            "Dit product wordt op aantal gefactureerd. Uren zijn hier niet nodig.": [.english: "This product is invoiced by quantity. Hours are not needed here.", .german: "Dieses Produkt wird nach Menge abgerechnet. Stunden sind hier nicht erforderlich."],
            "Notities": [.english: "Notes", .german: "Notizen"],
            "Voeg context toe aan deze registratie": [.english: "Add context to this registration", .german: "Kontext zu dieser Erfassung hinzufügen"],
            "Bijlagen": [.english: "Attachments", .german: "Anhänge"],
            "Bijlage toevoegen": [.english: "Add attachment", .german: "Anhang hinzufügen"],
            "Facturatie": [.english: "Invoicing", .german: "Abrechnung"],
            "Meenemen op factuur": [.english: "Include on invoice", .german: "Auf Rechnung aufnehmen"],
            "Later kunnen factureren": [.english: "Available for invoicing later", .german: "Spater abrechnen konnen"],
            "Je kunt uren nu registreren zonder meteen een factuur te maken. Zet dit alleen aan als je deze uren later wilt kunnen factureren.": [.english: "You can register hours now without creating an invoice right away. Only turn this on if you want to invoice these hours later.", .german: "Du kannst Stunden jetzt erfassen, ohne sofort eine Rechnung zu erstellen. Aktiviere dies nur, wenn du diese Stunden spater abrechnen mochtest."],
            "Deze uren worden alleen opgeslagen als registratie. Je kunt ze later alsnog opnemen in een factuur vanuit Registraties of Facturen.": [.english: "These hours are only saved as a registration. You can still add them to an invoice later from Registrations or Invoices.", .german: "Diese Stunden werden nur als Erfassung gespeichert. Du kannst sie spater uber Erfassungen oder Rechnungen dennoch zu einer Rechnung hinzufugen."],
            "Deze uren blijven eerst als registratie staan en worden later beschikbaar voor facturatie.": [.english: "These hours remain stored as a registration first and become available for invoicing later.", .german: "Diese Stunden bleiben zunachst als Erfassung gespeichert und stehen spater fur die Abrechnung zur Verfugung."],
            "Samenwerking": [.english: "Collaboration", .german: "Zusammenarbeit"],
            "Gebruik standaard van klant": [.english: "Use client's default", .german: "Standard des Kunden verwenden"],
            "Gebruik aangepast uurtarief": [.english: "Use custom hourly rate", .german: "Angepassten Stundensatz verwenden"],
            "Uurtarief": [.english: "Hourly rate", .german: "Stundensatz"],
            "Je kunt deze registratie later alsnog meenemen op een factuur.": [.english: "You can still include this registration on an invoice later.", .german: "Du kannst diese Erfassung später weiterhin auf eine Rechnung aufnehmen."],
            "Nieuwe registratie": [.english: "New registration", .german: "Neue Erfassung"],
            "Importeren mislukt": [.english: "Import failed", .german: "Import fehlgeschlagen"],
            "Annuleer": [.english: "Cancel", .german: "Abbrechen"],
            "Bewaar": [.english: "Save", .german: "Speichern"],
            "Company profiles": [.dutch: "Bedrijfsprofielen", .german: "Firmenprofile"],
            "Manage multiple business identities and choose which profile is active for invoices, quotes, and exports.": [.dutch: "Beheer meerdere bedrijfsidentiteiten en kies welk profiel actief is voor facturen, offertes en exports.", .german: "Verwalte mehrere Geschäftsidentitäten und wähle das aktive Profil für Rechnungen, Angebote und Exporte."],
            "Profiles": [.dutch: "Profielen", .german: "Profile"],
            "Add Profile": [.dutch: "Profiel toevoegen", .german: "Profil hinzufügen"],
            "No company profiles yet.": [.dutch: "Nog geen bedrijfsprofielen.", .german: "Noch keine Firmenprofile."],
            "No owner name": [.dutch: "Geen eigenaar", .german: "Kein Inhabername"],
            "Active": [.dutch: "Actief", .german: "Aktiv"],
            "Set Active": [.dutch: "Maak actief", .german: "Aktiv setzen"],
            "Identity": [.dutch: "Identiteit", .german: "Identität"],
            "Choose Logo": [.dutch: "Logo kiezen", .german: "Logo auswählen"],
            "Replace Logo": [.dutch: "Logo vervangen", .german: "Logo ersetzen"],
            "Remove": [.dutch: "Verwijder", .german: "Entfernen"],
            "Company name": [.dutch: "Bedrijfsnaam", .german: "Firmenname"],
            "Owner name": [.dutch: "Eigenaar", .german: "Inhabername"],
            "Contact and tax": [.dutch: "Contact en belasting", .german: "Kontakt und Steuer"],
            "VAT number": [.dutch: "Btw-nummer", .german: "USt-IdNr."],
            "KVK number": [.dutch: "KVK-nummer", .german: "Handelsregisternummer"],
            "Invoice defaults": [.dutch: "Factuurstandaarden", .german: "Rechnungsvorgaben"],
            "Invoice text": [.dutch: "Factuurtekst", .german: "Rechnungstext"],
            "Payment text": [.dutch: "Betaaltekst", .german: "Zahlungstext"],
            "Activation": [.dutch: "Activatie", .german: "Aktivierung"],
            "Tijdelijk product": [.english: "Temporary product", .german: "Temporäres Produkt"],
            "Gebruik tijdelijk product als deze factuurregel niet in je productlijst hoeft te worden opgeslagen.": [.english: "Use a temporary product when this invoice line does not need to be saved in your product list.", .german: "Verwende ein temporäres Produkt, wenn diese Rechnungszeile nicht in deiner Produktliste gespeichert werden muss."],
            "Set as active company profile": [.dutch: "Instellen als actief bedrijfsprofiel", .german: "Als aktives Firmenprofil festlegen"],
            "New Profile": [.dutch: "Nieuw profiel", .german: "Neues Profil"],
            "Edit Profile": [.dutch: "Profiel bewerken", .german: "Profil bearbeiten"],
            "Company Profile": [.dutch: "Bedrijfsprofiel", .german: "Firmenprofil"],
            "Rules": [.dutch: "Regels", .german: "Regeln"],
            "Add Rule": [.dutch: "Regel toevoegen", .german: "Regel hinzufügen"],
            "No collaboration rules yet.": [.dutch: "Nog geen samenwerkingsregels.", .german: "Noch keine Zusammenarbeitsregeln."],
            "General rule": [.dutch: "Algemene regel", .german: "Allgemeine Regel"],
            "Scope": [.dutch: "Bereik", .german: "Geltungsbereich"],
            "Split": [.dutch: "Verdeling", .german: "Aufteilung"],
            "Partner name": [.dutch: "Partnernaam", .german: "Partnername"],
            "Percentage": [.dutch: "Percentage", .german: "Prozentsatz"],
            "Optional notes": [.dutch: "Optionele notities", .german: "Optionale Notizen"],
            "New Collaboration Rule": [.dutch: "Nieuwe samenwerkingsregel", .german: "Neue Zusammenarbeitsregel"],
            "Edit Collaboration Rule": [.dutch: "Samenwerkingsregel bewerken", .german: "Zusammenarbeitsregel bearbeiten"],
            "Mileage": [.dutch: "Kilometers", .german: "Kilometer"],
            "Delete Mileage Entry": [.dutch: "Kilometerregistratie verwijderen", .german: "Kilometereintrag löschen"],
            "This trip log will be removed permanently.": [.dutch: "Deze ritregistratie wordt definitief verwijderd.", .german: "Dieser Fahrteintrag wird dauerhaft entfernt."],
            "Delete Registration": [.dutch: "Registratie verwijderen", .german: "Erfassung löschen"],
            "Unable to Delete Registration": [.dutch: "Registratie verwijderen mislukt", .german: "Erfassung kann nicht gelöscht werden"],
            "This registration will be removed permanently.": [.dutch: "Deze registratie wordt definitief verwijderd.", .german: "Diese Erfassung wird dauerhaft entfernt."],
            "This registration is already linked to an invoice and cannot be deleted.": [.dutch: "Deze registratie is al gekoppeld aan een factuur en kan niet worden verwijderd.", .german: "Diese Erfassung ist bereits mit einer Rechnung verknüpft und kann nicht gelöscht werden."],
            "This month": [.dutch: "Deze maand", .german: "Dieser Monat"],
            "Previous week": [.dutch: "Vorige week", .german: "Letzte Woche"],
            "Previous month": [.dutch: "Vorige maand", .german: "Letzter Monat"],
            "Trips": [.dutch: "Ritten", .german: "Fahrten"],
            "Distance tracked": [.dutch: "Afstand geregistreerd", .german: "Erfasste Strecke"],
            "Travel Cost": [.dutch: "Reiskosten", .german: "Fahrtkosten"],
            "Reimbursable amount": [.dutch: "Te vergoeden bedrag", .german: "Erstattungsbetrag"],
            "Invoice Cost": [.dutch: "Factuurkosten", .german: "Rechnungskosten"],
            "Marked for billing": [.dutch: "Gemarkeerd voor facturatie", .german: "Für Abrechnung markiert"],
            "Selected period": [.dutch: "Geselecteerde periode", .german: "Ausgewählter Zeitraum"],
            "Search trips": [.dutch: "Ritten zoeken", .german: "Fahrten suchen"],
            "Matching trips": [.dutch: "Overeenkomende ritten", .german: "Passende Fahrten"],
            "Filtered distance": [.dutch: "Gefilterde afstand", .german: "Gefilterte Strecke"],
            "Filtered amount": [.dutch: "Gefilterd bedrag", .german: "Gefilterter Betrag"],
            "Invoice Km": [.dutch: "Factuur km", .german: "Rechnungs-km"],
            "Ready to bill": [.dutch: "Klaar voor facturatie", .german: "Bereit zur Abrechnung"],
            "No mileage entries found for the selected filters.": [.dutch: "Geen kilometerregistraties gevonden voor de geselecteerde filters.", .german: "Keine Kilometereinträge für die ausgewählten Filter gefunden."],
            "Log Trip": [.dutch: "Rit registreren", .german: "Fahrt erfassen"],
            "No client": [.dutch: "Geen klant", .german: "Kein Kunde"],
            "Invoice not linked": [.dutch: "Factuur niet gekoppeld", .german: "Rechnung nicht verknüpft"],
            "Trip": [.dutch: "Rit", .german: "Fahrt"],
            "Date": [.dutch: "Datum", .german: "Datum"],
            "Start location": [.dutch: "Startlocatie", .german: "Startort"],
            "End location": [.dutch: "Eindlocatie", .german: "Zielort"],
            "Purpose": [.dutch: "Doel", .german: "Zweck"],
            "Distance": [.dutch: "Afstand", .german: "Strecke"],
            "Kilometers": [.dutch: "Kilometers", .german: "Kilometer"],
            "Rate per kilometer": [.dutch: "Tarief per kilometer", .german: "Satz pro Kilometer"],
            "Total travel cost": [.dutch: "Totale reiskosten", .german: "Gesamte Fahrtkosten"],
            "Billing": [.dutch: "Facturatie", .german: "Abrechnung"],
            "Include on invoice": [.dutch: "Meenemen op factuur", .german: "Auf Rechnung aufnehmen"],
            "Linked invoice": [.dutch: "Gekoppelde factuur", .german: "Verknüpfte Rechnung"],
            "No linked invoice": [.dutch: "Geen gekoppelde factuur", .german: "Keine verknüpfte Rechnung"],
            "Travel costs can be linked to an invoice later.": [.dutch: "Reiskosten kunnen later aan een factuur worden gekoppeld.", .german: "Fahrtkosten können später mit einer Rechnung verknüpft werden."],
            "New Mileage": [.dutch: "Nieuwe rit", .german: "Neue Fahrt"],
            "Edit Mileage": [.dutch: "Rit bewerken", .german: "Fahrt bearbeiten"],
            "Receipts": [.dutch: "Bonnen", .german: "Belege"],
            "Delete Receipt": [.dutch: "Bon verwijderen", .german: "Beleg löschen"],
            "The stored receipt image and its metadata will be removed.": [.dutch: "De opgeslagen bonafbeelding en metadata worden verwijderd.", .german: "Das gespeicherte Belegbild und die Metadaten werden entfernt."],
            "Receipt summary": [.dutch: "Bonnenoverzicht", .german: "Belegübersicht"],
            "Shown in current filters": [.dutch: "Getoond in huidige filters", .german: "In aktuellen Filtern angezeigt"],
            "Amount": [.dutch: "Bedrag", .german: "Betrag"],
            "Gross spend tracked": [.dutch: "Bruto uitgaven geregistreerd", .german: "Erfasste Bruttoausgaben"],
            "Recoverable tax": [.dutch: "Terug te vorderen belasting", .german: "Erstattbare Steuer"],
            "Linked": [.dutch: "Gekoppeld", .german: "Verknüpft"],
            "Attached to work or invoices": [.dutch: "Gekoppeld aan werk of facturen", .german: "Mit Arbeit oder Rechnungen verknüpft"],
            "Filters": [.dutch: "Filters", .german: "Filter"],
            "Search supplier, notes, invoice": [.dutch: "Zoek leverancier, notities, factuur", .german: "Lieferant, Notizen, Rechnung suchen"],
            "All Categories": [.dutch: "Alle categorieën", .german: "Alle Kategorien"],
            "Stored receipts": [.dutch: "Opgeslagen bonnen", .german: "Gespeicherte Belege"],
            "No receipts match the current filters.": [.dutch: "Geen bonnen gevonden voor de huidige filters.", .german: "Keine Belege passen zu den aktuellen Filtern."],
            "Add Receipt": [.dutch: "Bon toevoegen", .german: "Beleg hinzufügen"],
            "Receipt image": [.dutch: "Bonafbeelding", .german: "Belegbild"],
            "Choose from Photos": [.dutch: "Kies uit foto's", .german: "Aus Fotos wählen"],
            "Replace from Photos": [.dutch: "Vervang uit foto's", .german: "Aus Fotos ersetzen"],
            "Capture Photo": [.dutch: "Foto maken", .german: "Foto aufnehmen"],
            "Retake Photo": [.dutch: "Foto opnieuw maken", .german: "Foto erneut aufnehmen"],
            "Supplier name": [.dutch: "Leverancier", .german: "Lieferant"],
            "VAT amount": [.dutch: "Btw-bedrag", .german: "MwSt.-Betrag"],
            "Category": [.dutch: "Categorie", .german: "Kategorie"],
            "Links": [.dutch: "Koppelingen", .german: "Verknüpfungen"],
            "No linked client": [.dutch: "Geen gekoppelde klant", .german: "Kein verknüpfter Kunde"],
            "Registration": [.dutch: "Registratie", .german: "Erfassung"],
            "No linked registration": [.dutch: "Geen gekoppelde registratie", .german: "Keine verknüpfte Erfassung"],
            "Link either a registration or an invoice. Selecting one clears the other.": [.dutch: "Koppel een registratie of een factuur. Als je één kiest wordt de andere gewist.", .german: "Verknüpfe entweder eine Erfassung oder eine Rechnung. Eine Auswahl löscht die andere."],
            "Add expense context": [.dutch: "Voeg kostencontext toe", .german: "Ausgabenkontext hinzufügen"],
            "New Receipt": [.dutch: "Nieuwe bon", .german: "Neuer Beleg"],
            "Edit Receipt": [.dutch: "Bon bewerken", .german: "Beleg bearbeiten"],
            "Receipt": [.dutch: "Bon", .german: "Beleg"],
            "Add a receipt image to store proof safely on-device.": [.dutch: "Voeg een bonafbeelding toe om bewijs veilig op het apparaat te bewaren.", .german: "Füge ein Belegbild hinzu, um den Nachweis sicher auf dem Gerät zu speichern."],
            "Search quotes": [.dutch: "Offertes zoeken", .german: "Angebote suchen"],
            "No quotes match the current filters.": [.dutch: "Geen offertes gevonden voor de huidige filters.", .german: "Keine Angebote passen zu den aktuellen Filtern."],
            "Expires": [.dutch: "Verloopt", .german: "Läuft ab"],
            "Accepted": [.dutch: "Geaccepteerd", .german: "Angenommen"],
            "Rejected": [.dutch: "Afgewezen", .german: "Abgelehnt"],
            "Expired": [.dutch: "Verlopen", .german: "Abgelaufen"],
            "Quote": [.dutch: "Offerte", .german: "Angebot"],
            "Select client": [.dutch: "Kies een klant", .german: "Kunde auswählen"],
            "Quote date": [.dutch: "Offertedatum", .german: "Angebotsdatum"],
            "Expiry date": [.dutch: "Vervaldatum", .german: "Ablaufdatum"],
            "Status": [.dutch: "Status", .german: "Status"],
            "Use product or service": [.dutch: "Gebruik product of dienst", .german: "Produkt oder Dienst nutzen"],
            "Qty": [.dutch: "Aantal", .german: "Menge"],
            "Unit price": [.dutch: "Stukprijs", .german: "Einzelpreis"],
            "VAT %": [.dutch: "Btw %", .german: "MwSt. %"],
            "Remove line": [.dutch: "Regel verwijderen", .german: "Zeile entfernen"],
            "Add line": [.dutch: "Regel toevoegen", .german: "Zeile hinzufügen"],
            "New Quote": [.dutch: "Nieuwe offerte", .german: "Neues Angebot"],
            "Edit Quote": [.dutch: "Offerte bewerken", .german: "Angebot bearbeiten"],
            "Unable to Save Quote": [.dutch: "Offerte opslaan mislukt", .german: "Angebot konnte nicht gespeichert werden"],
            "Overview": [.dutch: "Overzicht", .german: "Übersicht"],
            "Quote number": [.dutch: "Offertenummer", .german: "Angebotsnummer"],
            "Converted invoice": [.dutch: "Omgezette factuur", .german: "Umgewandelte Rechnung"],
            "Not converted": [.dutch: "Niet omgezet", .german: "Nicht umgewandelt"],
            "Capture Signature": [.dutch: "Handtekening vastleggen", .german: "Unterschrift erfassen"],
            "Actions": [.dutch: "Acties", .german: "Aktionen"],
            "Convert to Invoice": [.dutch: "Omzetten naar factuur", .german: "In Rechnung umwandeln"],
            "Only accepted quotes can be converted.": [.dutch: "Alleen geaccepteerde offertes kunnen worden omgezet.", .german: "Nur angenommene Angebote können umgewandelt werden."],
            "This quote has already been converted.": [.dutch: "Deze offerte is al omgezet.", .german: "Dieses Angebot wurde bereits umgewandelt."],
            "Export": [.dutch: "Export", .german: "Export"],
            "Share PDF": [.dutch: "Deel PDF", .german: "PDF teilen"],
            "Share DOCX": [.dutch: "Deel DOCX", .german: "DOCX teilen"],
            "Quote Signature": [.dutch: "Offertehandtekening", .german: "Angebotsunterschrift"],
            "Convert Quote to Invoice": [.dutch: "Offerte omzetten naar factuur", .german: "Angebot in Rechnung umwandeln"],
            "Convert": [.dutch: "Omzetten", .german: "Umwandeln"],
            "Create an editable invoice draft from this accepted quote?": [.dutch: "Een bewerkbaar factuurconcept maken van deze geaccepteerde offerte?", .german: "Einen bearbeitbaren Rechnungsentwurf aus diesem angenommenen Angebot erstellen?"],
            "Quote Conversion": [.dutch: "Offerte omzetten", .german: "Angebotsumwandlung"],
            "Export Complete": [.dutch: "Export voltooid", .german: "Export abgeschlossen"],
            "Attachment": [.dutch: "Bijlage", .german: "Anhang"],
            "File": [.dutch: "Bestand", .german: "Datei"],
            "Size": [.dutch: "Grootte", .german: "Größe"],
            "Recipient": [.dutch: "Ontvanger", .german: "Empfänger"],
            "Subject": [.dutch: "Onderwerp", .german: "Betreff"],
            "Message": [.dutch: "Bericht", .german: "Nachricht"],
            "Mail Unavailable": [.dutch: "Mail niet beschikbaar", .german: "Mail nicht verfügbar"],
            "Mail is not configured on this device. You can still share the PDF attachment manually.": [.dutch: "Mail is niet ingesteld op dit apparaat. Je kunt de PDF-bijlage nog handmatig delen.", .german: "Mail ist auf diesem Gerät nicht eingerichtet. Du kannst den PDF-Anhang weiterhin manuell teilen."],
            "Share PDF Instead": [.dutch: "Deel PDF in plaats daarvan", .german: "Stattdessen PDF teilen"],
            "Send Invoice": [.dutch: "Factuur verzenden", .german: "Rechnung senden"],
            "Close": [.dutch: "Sluit", .german: "Schließen"],
            "Send": [.dutch: "Verzend", .german: "Senden"],
            "Done": [.dutch: "Klaar", .german: "Fertig"],
            "Unable to Save Invoice": [.dutch: "Factuur opslaan mislukt", .german: "Rechnung konnte nicht gespeichert werden"],
            "Week Revenue": [.dutch: "Weekomzet", .german: "Wochenumsatz"],
            "Invoices this week": [.dutch: "Facturen deze week", .german: "Rechnungen diese Woche"],
            "Month Revenue": [.dutch: "Maandomzet", .german: "Monatsumsatz"],
            "Invoices this month": [.dutch: "Facturen deze maand", .german: "Rechnungen diesen Monat"],
            "Draft, sent, overdue": [.dutch: "Concept, verzonden, te laat", .german: "Entwurf, gesendet, überfällig"],
            "Completed invoices": [.dutch: "Afgeronde facturen", .german: "Abgeschlossene Rechnungen"],
            "Needs attention": [.dutch: "Heeft aandacht nodig", .german: "Benötigt Aufmerksamkeit"],
            "Expected In": [.dutch: "Verwacht binnen", .german: "Erwartet"],
            "Open invoice value": [.dutch: "Waarde open facturen", .german: "Wert offener Rechnungen"],
            "Open Quotes": [.dutch: "Open offertes", .german: "Angebote öffnen"],
            "Templates": [.dutch: "Templates", .german: "Vorlagen"],
            "Saved repeat billing setups": [.dutch: "Opgeslagen herhaalfacturen", .german: "Gespeicherte Wiederholungsabrechnungen"],
            "Due Now": [.dutch: "Nu verschuldigd", .german: "Jetzt fällig"],
            "Templates ready to generate": [.dutch: "Templates klaar om te genereren", .german: "Vorlagen bereit zur Erstellung"],
            "No upcoming cycle": [.dutch: "Geen volgende cyclus", .german: "Kein nächster Zyklus"],
            "Scheduled": [.dutch: "Gepland", .german: "Geplant"],
            "cycle(s) due": [.dutch: "cyclus(sen) verschuldigd", .german: "Zyklus/Zyklen fällig"],
            "uninvoiced registrations are ready to be added to this draft.": [.dutch: "niet-gefactureerde registraties staan klaar om aan dit concept toe te voegen.", .german: "nicht abgerechnete Erfassungen können diesem Entwurf hinzugefügt werden."],
            "This invoice is being prepared from quote": [.dutch: "Deze factuur wordt voorbereid vanuit offerte", .german: "Diese Rechnung wird aus Angebot vorbereitet"],
            "You can edit the lines before saving the draft invoice.": [.dutch: "Je kunt de regels bewerken voordat je het factuurconcept opslaat.", .german: "Du kannst die Zeilen bearbeiten, bevor du den Rechnungsentwurf speicherst."],
            "Selecteer een bestaande klant of maak hieronder direct een nieuwe aan.": [.english: "Select an existing client or create a new one below.", .german: "Wähle einen bestehenden Kunden oder erstelle unten direkt einen neuen."],
            "Voeg factuurregels toe": [.english: "Add invoice lines", .german: "Rechnungszeilen hinzufügen"],
            "Selecteer werk en genereer regels": [.english: "Select work and generate lines", .german: "Arbeit auswählen und Zeilen erstellen"],
            "Handmatige modus laat je zelf regels toevoegen zonder registraties.": [.english: "Manual mode lets you add lines yourself without registrations.", .german: "Im manuellen Modus kannst du Zeilen ohne Erfassungen selbst hinzufügen."],
            "registraties beschikbaar in deze periode. Gebruik 'Factuur op uren en producten', 'Factuur op uren', 'Factuur op producten' of genereer regels uit registraties.": [.english: "registrations available in this period. Use 'Invoice by hours and products', 'Invoice by hours', 'Invoice by products', or generate lines from registrations.", .german: "Erfassungen in diesem Zeitraum verfügbar. Nutze 'Rechnung nach Stunden und Produkten', 'Rechnung nach Stunden', 'Rechnung nach Produkten' oder erstelle Zeilen aus Erfassungen."],
            "Controleer en sla op": [.english: "Check and save", .german: "Prüfen und speichern"],
            "Controleer subtotaal, btw en vervaldatum en sla daarna het concept op.": [.english: "Check subtotal, VAT, and due date, then save the draft.", .german: "Prüfe Zwischensumme, MwSt. und Fälligkeitsdatum und speichere dann den Entwurf."],
            "De preview wordt automatisch bijgewerkt zodra je regels toevoegt.": [.english: "The preview updates automatically once you add lines.", .german: "Die Vorschau aktualisiert sich automatisch, sobald du Zeilen hinzufügst."],
            "Tip: bestaat de klant nog niet, tik dan op 'Nieuwe klant' en ga meteen verder.": [.english: "Tip: if the client does not exist yet, tap 'New client' and continue right away.", .german: "Tipp: Falls der Kunde noch nicht existiert, tippe auf 'Neuer Kunde' und fahre direkt fort."],
            "Actief bedrijf": [.english: "Active company", .german: "Aktives Unternehmen"],
            "Klant ontbreekt": [.english: "Client missing", .german: "Kunde fehlt"],
            "Klant gekozen": [.english: "Client selected", .german: "Kunde ausgewählt"],
            "Handmatig concept": [.english: "Manual draft", .german: "Manueller Entwurf"],
            "Op basis van registraties": [.english: "Based on registrations", .german: "Basierend auf Erfassungen"],
            "Klaar om op te slaan": [.english: "Ready to save", .german: "Bereit zum Speichern"],
            "Concept nog niet compleet": [.english: "Draft not complete yet", .german: "Entwurf noch nicht vollständig"],
            "Huidig tarief": [.english: "Current rate", .german: "Aktueller Satz"],
            "uur": [.english: "hour", .german: "Stunde"],
            "Er staat nog geen standaard uurtarief op deze klant. Zonder tarief blijft urenfacturatie op € 0,00 staan.": [.english: "This client does not have a default hourly rate yet. Without a rate, hourly invoicing stays at €0.00.", .german: "Dieser Kunde hat noch keinen Standard-Stundensatz. Ohne Satz bleibt die Stundenabrechnung bei 0,00 €."],
            "Een deel van de gekozen registraties heeft nog geen uurtarief of productprijs. Zet hier eerst een tarief op de klant, of bewerk de registratie met een aangepast uurtarief.": [.english: "Some selected registrations do not have an hourly rate or product price yet. Set a client rate here first, or edit the registration with a custom hourly rate.", .german: "Einige ausgewählte Erfassungen haben noch keinen Stundensatz oder Produktpreis. Lege zuerst einen Kundensatz fest oder bearbeite die Erfassung mit einem eigenen Stundensatz."],
            "Hiermee maak je direct factuurregels op basis van gelogde uren en het uurtarief per registratie.": [.english: "This creates invoice lines directly from logged hours and the hourly rate per registration.", .german: "Damit werden Rechnungszeilen direkt aus erfassten Stunden und dem Stundensatz pro Erfassung erstellt."],
            "Regel toevoegen": [.english: "Add line", .german: "Zeile hinzufügen"],
            "In handmatige modus worden registraties niet automatisch meegenomen.": [.english: "In manual mode, registrations are not included automatically.", .german: "Im manuellen Modus werden Erfassungen nicht automatisch übernommen."],
            "Geen registraties beschikbaar in de gekozen periode.": [.english: "No registrations available in the selected period.", .german: "Keine Erfassungen im ausgewählten Zeitraum verfügbar."],
            "Geselecteerde registraties zonder tarief worden nu als € 0,00 berekend. Stel eerst een klanttarief of aangepast uurtarief in.": [.english: "Selected registrations without a rate are currently calculated as €0.00. Set a client rate or custom hourly rate first.", .german: "Ausgewählte Erfassungen ohne Satz werden aktuell mit 0,00 € berechnet. Lege zuerst einen Kundensatz oder eigenen Stundensatz fest."],
            "Partner share": [.dutch: "Partnerdeel", .german: "Partneranteil"],
            "Invoice number": [.dutch: "Factuurnummer", .german: "Rechnungsnummer"],
            "Quote reference": [.dutch: "Offerteverwijzing", .german: "Angebotsreferenz"],
            "Invoice date": [.dutch: "Factuurdatum", .german: "Rechnungsdatum"],
            "Due date": [.dutch: "Vervaldatum", .german: "Fälligkeitsdatum"],
            "No company profile": [.dutch: "Geen bedrijfsprofiel", .german: "Kein Firmenprofil"],
            "Paid date": [.dutch: "Betaaldatum", .german: "Zahlungsdatum"],
            "Not paid": [.dutch: "Niet betaald", .german: "Nicht bezahlt"],
            "Email status": [.dutch: "E-mailstatus", .german: "E-Mail-Status"],
            "Email sent": [.dutch: "E-mail verzonden", .german: "E-Mail gesendet"],
            "Not sent": [.dutch: "Niet verzonden", .german: "Nicht gesendet"],
            "Payment Actions": [.dutch: "Betaalacties", .german: "Zahlungsaktionen"],
            "Preview Next Reminder": [.dutch: "Volgende herinnering bekijken", .german: "Nächste Erinnerung anzeigen"],
            "Create Reminder Manually": [.dutch: "Herinnering handmatig maken", .german: "Erinnerung manuell erstellen"],
            "No reminders created yet.": [.dutch: "Nog geen herinneringen gemaakt.", .german: "Noch keine Erinnerungen erstellt."],
            "Annual Summary": [.dutch: "Jaaroverzicht", .german: "Jahresübersicht"],
            "Year selection": [.dutch: "Jaarselectie", .german: "Jahresauswahl"],
            "Year": [.dutch: "Jaar", .german: "Jahr"],
            "performance": [.dutch: "prestaties", .german: "Leistung"],
            "Invoice total for the year": [.dutch: "Factuurtotaal voor het jaar", .german: "Rechnungssumme des Jahres"],
            "VAT Charged": [.dutch: "Btw berekend", .german: "Berechnete MwSt."],
            "VAT across issued invoices": [.dutch: "Btw over uitgegeven facturen", .german: "MwSt. auf ausgestellte Rechnungen"],
            "Paid invoice total": [.dutch: "Totaal betaalde facturen", .german: "Summe bezahlter Rechnungen"],
            "Unpaid": [.dutch: "Onbetaald", .german: "Unbezahlt"],
            "Open invoice total": [.dutch: "Totaal open facturen", .german: "Summe offener Rechnungen"],
            "Tracked work hours": [.dutch: "Geregistreerde werkuren", .german: "Erfasste Arbeitsstunden"],
            "Delivered": [.dutch: "Geleverd", .german: "Geliefert"],
            "Products and services quantity": [.dutch: "Aantal producten en diensten", .german: "Menge Produkte und Dienstleistungen"],
            "Top clients by revenue": [.dutch: "Topklanten op omzet", .german: "Top-Kunden nach Umsatz"],
            "No client revenue has been recorded for this year.": [.dutch: "Er is nog geen klantomzet geregistreerd voor dit jaar.", .german: "Für dieses Jahr wurde noch kein Kundenumsatz erfasst."],
            "invoices": [.dutch: "facturen", .german: "Rechnungen"],
            "Monthly revenue breakdown": [.dutch: "Maandelijkse omzetverdeling", .german: "Monatliche Umsatzaufschlüsselung"],
            "Native chart support can be added later. This list keeps the monthly summary lightweight and export-ready.": [.dutch: "Grafiekondersteuning kan later worden toegevoegd. Deze lijst houdt het maandoverzicht licht en klaar voor export.", .german: "Diagrammunterstützung kann später ergänzt werden. Diese Liste hält die Monatsübersicht leicht und exportbereit."],
            "Quarterly VAT": [.dutch: "Btw per kwartaal", .german: "Quartals-MwSt."],
            "Quarter selection": [.dutch: "Kwartaalselectie", .german: "Quartalsauswahl"],
            "Quarter": [.dutch: "Kwartaal", .german: "Quartal"],
            "Revenue Ex VAT": [.dutch: "Omzet excl. btw", .german: "Umsatz exkl. MwSt."],
            "Taxable revenue in quarter": [.dutch: "Belastbare omzet in kwartaal", .german: "Steuerpflichtiger Umsatz im Quartal"],
            "Output VAT on invoices": [.dutch: "Af te dragen btw op facturen", .german: "Umsatzsteuer auf Rechnungen"],
            "Dated in selected quarter": [.dutch: "Gedateerd in geselecteerd kwartaal", .german: "Im ausgewählten Quartal datiert"],
            "Gross paid invoice total": [.dutch: "Bruto totaal betaalde facturen", .german: "Bruttosumme bezahlter Rechnungen"],
            "Gross open invoice total": [.dutch: "Bruto totaal open facturen", .german: "Bruttosumme offener Rechnungen"],
            "No invoices were issued in the selected quarter.": [.dutch: "Er zijn geen facturen uitgegeven in het geselecteerde kwartaal.", .german: "Im ausgewählten Quartal wurden keine Rechnungen ausgestellt."],
            "Ex VAT": [.dutch: "Excl. btw", .german: "Exkl. MwSt."],
            "Included invoices": [.dutch: "Opgenomen facturen", .german: "Enthaltene Rechnungen"],
            "No invoice data available for this period.": [.dutch: "Geen factuurgegevens beschikbaar voor deze periode.", .german: "Für diesen Zeitraum sind keine Rechnungsdaten verfügbar."],
            "No overdue invoices": [.dutch: "Geen achterstallige facturen", .german: "Keine überfälligen Rechnungen"],
            "Payment reminders will appear here when unpaid invoices pass their due date.": [.dutch: "Betalingsherinneringen verschijnen hier zodra onbetaalde facturen voorbij de vervaldatum zijn.", .german: "Zahlungserinnerungen erscheinen hier, wenn unbezahlte Rechnungen ihr Fälligkeitsdatum überschreiten."],
            "days": [.dutch: "dagen", .german: "Tage"],
            "Due": [.dutch: "Vervalt", .german: "Fällig"],
            "Last reminder": [.dutch: "Laatste herinnering", .german: "Letzte Erinnerung"],
            "on": [.dutch: "op", .german: "am"],
            "Open Invoice": [.dutch: "Open factuur", .german: "Rechnung öffnen"],
            "Manual Level": [.dutch: "Handmatig niveau", .german: "Manuelle Stufe"],
            "Reminder preview": [.dutch: "Herinneringsvoorbeeld", .german: "Erinnerungsvorschau"],
            "Invoice": [.dutch: "Factuur", .german: "Rechnung"],
            "Amount due": [.dutch: "Openstaand bedrag", .german: "Fälliger Betrag"],
            "Reminder level": [.dutch: "Herinneringsniveau", .german: "Erinnerungsstufe"],
            "Reminder": [.dutch: "Herinnering", .german: "Erinnerung"],
            "OK": [.dutch: "OK", .german: "OK"],
            "PDF": [.dutch: "PDF", .german: "PDF"],
            "DOCX": [.dutch: "DOCX", .german: "DOCX"],
            "Save Draft": [.dutch: "Concept opslaan", .german: "Entwurf speichern"],
            "Save & Sent": [.dutch: "Opslaan en verzonden", .german: "Speichern und gesendet"],
            "Data tools": [.dutch: "Datatools", .german: "Datentools"],
            "Note": [.dutch: "Notitie", .german: "Notiz"],
            "Kortingen": [.english: "Discounts", .german: "Rabatte"],
            "Netto inkomen": [.english: "Net income", .german: "Nettoeinkommen"],
            "Import clients or products from CSV, preview rows before saving, and export backups or reporting files.": [.dutch: "Importeer klanten of producten uit CSV, bekijk rijen vooraf en exporteer back-ups of rapportbestanden.", .german: "Importiere Kunden oder Produkte aus CSV, prüfe Zeilen vor dem Speichern und exportiere Backups oder Berichtsdateien."],
            "Data Tools": [.dutch: "Datatools", .german: "Datentools"],
            "Import CSV": [.dutch: "CSV importeren", .german: "CSV importieren"],
            "Import type": [.dutch: "Importtype", .german: "Importtyp"],
            "Choose CSV File": [.dutch: "CSV-bestand kiezen", .german: "CSV-Datei wählen"],
            "Preview": [.dutch: "Voorbeeld", .german: "Vorschau"],
            "Import Valid Rows": [.dutch: "Geldige rijen importeren", .german: "Gültige Zeilen importieren"],
            "Export App Backup": [.dutch: "App-back-up exporteren", .german: "App-Backup exportieren"],
            "Export Registrations CSV": [.dutch: "Registraties CSV exporteren", .german: "Erfassungen als CSV exportieren"],
            "Export Invoices CSV": [.dutch: "Facturen CSV exporteren", .german: "Rechnungen als CSV exportieren"],
            "Ready": [.dutch: "Klaar", .german: "Bereit"],
            "Automate repeated billing with reusable templates and duplicate-safe draft generation.": [.dutch: "Automatiseer herhaalde facturatie met herbruikbare templates en conceptgeneratie zonder duplicaten.", .german: "Automatisiere wiederkehrende Abrechnung mit wiederverwendbaren Vorlagen und duplikatsicherer Entwurfserstellung."],
            "New Template": [.dutch: "Nieuwe template", .german: "Neue Vorlage"],
            "Due now": [.dutch: "Nu verschuldigd", .german: "Jetzt fällig"],
            "Drafts created": [.dutch: "Concepten gemaakt", .german: "Entwürfe erstellt"],
            "Generate Due Drafts": [.dutch: "Verschuldigde concepten maken", .german: "Fällige Entwürfe erstellen"],
            "No recurring invoice templates yet.": [.dutch: "Nog geen terugkerende factuurtemplates.", .german: "Noch keine wiederkehrenden Rechnungsvorlagen."],
            "Paused": [.dutch: "Gepauzeerd", .german: "Pausiert"],
            "due": [.dutch: "verschuldigd", .german: "fällig"],
            "Next planned invoice": [.dutch: "Volgende geplande factuur", .german: "Nächste geplante Rechnung"],
            "Recurring": [.dutch: "Terugkerend", .german: "Wiederkehrend"],
            "Template": [.dutch: "Template", .german: "Vorlage"],
            "Template name": [.dutch: "Templatenaam", .german: "Vorlagenname"],
            "Select a client": [.dutch: "Kies een klant", .german: "Kunden auswählen"],
            "Frequency": [.dutch: "Frequentie", .german: "Häufigkeit"],
            "Template is active": [.dutch: "Template is actief", .german: "Vorlage ist aktiv"],
            "Schedule": [.dutch: "Planning", .german: "Zeitplan"],
            "Start date": [.dutch: "Startdatum", .german: "Startdatum"],
            "Use end date": [.dutch: "Einddatum gebruiken", .german: "Enddatum verwenden"],
            "End date": [.dutch: "Einddatum", .german: "Enddatum"],
            "Payment term (days)": [.dutch: "Betaaltermijn (dagen)", .german: "Zahlungsfrist (Tage)"],
            "Add Line": [.dutch: "Regel toevoegen", .german: "Zeile hinzufügen"],
            "Add at least one recurring line.": [.dutch: "Voeg minimaal één terugkerende regel toe.", .german: "Füge mindestens eine wiederkehrende Zeile hinzu."],
            "Invoice notes": [.dutch: "Factuurnotities", .german: "Rechnungsnotizen"],
            "Edit Template": [.dutch: "Template bewerken", .german: "Vorlage bearbeiten"],
            "Remove Line": [.dutch: "Regel verwijderen", .german: "Zeile entfernen"],
            "Signature": [.dutch: "Handtekening", .german: "Unterschrift"],
            "Clear": [.dutch: "Wissen", .german: "Leeren"],
            "stroke": [.dutch: "lijn", .german: "Strich"],
            "strokes": [.dutch: "lijnen", .german: "Striche"],
            "Signer": [.dutch: "Ondertekenaar", .german: "Unterzeichner"],
            "Signed": [.dutch: "Ondertekend", .german: "Unterzeichnet"],
            "Customer signature": [.dutch: "Klanthandtekening", .german: "Kundenunterschrift"],
            "No signature captured yet.": [.dutch: "Nog geen handtekening vastgelegd.", .german: "Noch keine Unterschrift erfasst."],
            "Saved for later confirmation and export use.": [.dutch: "Opgeslagen voor latere bevestiging en export.", .german: "Für spätere Bestätigung und Export gespeichert."],
            "Update Signature": [.dutch: "Handtekening bijwerken", .german: "Unterschrift aktualisieren"],
            "Signer name": [.dutch: "Naam ondertekenaar", .german: "Name des Unterzeichners"],
            "Date signed": [.dutch: "Datum ondertekening", .german: "Unterzeichnungsdatum"],
            "Optional note": [.dutch: "Optionele notitie", .german: "Optionale Notiz"],
            "Sign here": [.dutch: "Teken hier", .german: "Hier unterschreiben"],
            "Generations": [.dutch: "Generaties", .german: "Erstellungen"],
            "No draft invoices generated yet.": [.dutch: "Nog geen conceptfacturen gegenereerd.", .german: "Noch keine Rechnungsentwürfe erstellt."],
            "Cycle": [.dutch: "Cyclus", .german: "Zyklus"],
            "Generated": [.dutch: "Gegenereerd", .german: "Erstellt"],
            "Generate Now": [.dutch: "Nu genereren", .german: "Jetzt erstellen"],
            "No end date": [.dutch: "Geen einddatum", .german: "Kein Enddatum"],
            "No invoice cycles were due for this template.": [.dutch: "Er waren geen factuurcycli verschuldigd voor deze template.", .german: "Für diese Vorlage waren keine Rechnungszyklen fällig."],
            "Work Mode": [.dutch: "Werkmodus", .german: "Arbeitsmodus"],
            "Choose which workflow Factureclick should prioritize across navigation, dashboard, and business tools.": [.dutch: "Kies welke workflow Factureclick prioriteit geeft in navigatie, dashboard en zakelijke tools.", .german: "Wähle, welchen Workflow Factureclick in Navigation, Dashboard und Geschäftstools priorisieren soll."],
            "Enabled Modules": [.dutch: "Ingeschakelde modules", .german: "Aktivierte Module"],
            "Hide modules that are not relevant for this business workflow. No data is deleted when you turn a module off.": [.dutch: "Verberg modules die niet relevant zijn voor deze workflow. Er wordt geen data verwijderd als je een module uitzet.", .german: "Blende Module aus, die für diesen Workflow nicht relevant sind. Beim Ausschalten werden keine Daten gelöscht."],
            "Choose exactly which modules are available in Custom mode. No data is deleted when you turn a module off.": [.dutch: "Kies precies welke modules beschikbaar zijn in Aangepast. Er wordt geen data verwijderd als je een module uitzet.", .german: "Wähle genau, welche Module im benutzerdefinierten Modus verfügbar sind. Beim Ausschalten werden keine Daten gelöscht."],
            "Choose your work mode": [.dutch: "Kies je werkmodus", .german: "Wähle deinen Arbeitsmodus"],
            "Factureclick can prioritize the workflows you actually use. You can change this later in Settings.": [.dutch: "Factureclick kan de workflows prioriteren die je echt gebruikt. Je kunt dit later wijzigen in Instellingen.", .german: "Factureclick kann die Workflows priorisieren, die du tatsächlich nutzt. Du kannst dies später in den Einstellungen ändern."],
            "Continue": [.dutch: "Doorgaan", .german: "Weiter"],
            "Quote / Business": [.dutch: "Offerte / zakelijk", .german: "Angebot / Geschäft"],
            "All": [.dutch: "Alles", .german: "Alles"],
            "Custom": [.dutch: "Aangepast", .german: "Benutzerdefiniert"],
            "Focus on agenda planning, work registrations, time tracking, and invoice creation from completed work.": [.dutch: "Focus op agendaplanning, werkregistraties, urenregistratie en facturen maken vanuit uitgevoerd werk.", .german: "Fokus auf Terminplanung, Arbeitserfassung, Zeiterfassung und Rechnungserstellung aus erledigter Arbeit."],
            "Focus on proposals, client-facing business workflows, recurring invoices, reminders, and signatures.": [.dutch: "Focus op offertes, klantgerichte zakelijke workflows, terugkerende facturen, herinneringen en handtekeningen.", .german: "Fokus auf Angebote, kundenorientierte Workflows, wiederkehrende Rechnungen, Erinnerungen und Unterschriften."],
            "Enable every workflow and tool in one complete setup.": [.dutch: "Schakel elke workflow en tool in één complete setup in.", .german: "Aktiviere jeden Workflow und jedes Tool in einer vollständigen Einrichtung."],
            "Choose exactly which modules, tabs, and business tools should be available.": [.dutch: "Kies precies welke modules, tabs en zakelijke tools beschikbaar moeten zijn.", .german: "Wähle genau, welche Module, Tabs und Geschäftstools verfügbar sein sollen."],
            "Custom modules": [.dutch: "Aangepaste modules", .german: "Benutzerdefinierte Module"],
            "Choose which features should be visible in the app. You can change this later in Settings.": [.dutch: "Kies welke functies zichtbaar moeten zijn in de app. Je kunt dit later wijzigen in Instellingen.", .german: "Wähle, welche Funktionen in der App sichtbar sein sollen. Du kannst dies später in den Einstellungen ändern."],
            "Shows the Agenda tab and planning tools.": [.dutch: "Toont de Agenda-tab en planningstools.", .german: "Zeigt den Agenda-Tab und Planungstools."],
            "Shows the Registrations tab and work-entry workflow.": [.dutch: "Toont de Registraties-tab en werkregistratieflow.", .german: "Zeigt den Erfassungen-Tab und den Arbeitserfassungsablauf."],
            "Enables time tracking inside registration workflows.": [.dutch: "Schakelt urenregistratie binnen registraties in.", .german: "Aktiviert Zeiterfassung innerhalb der Erfassungsabläufe."],
            "Enables quotes and proposal workflows.": [.dutch: "Schakelt offertes en voorstelworkflows in.", .german: "Aktiviert Angebote und Angebotsabläufe."],
            "Enables invoice creation, history, and exports.": [.dutch: "Schakelt facturen maken, historie en exports in.", .german: "Aktiviert Rechnungserstellung, Verlauf und Exporte."],
            "Enables mileage tracking and invoice-linked trips.": [.dutch: "Schakelt kilometerregistratie en aan facturen gekoppelde ritten in.", .german: "Aktiviert Kilometererfassung und rechnungsverknüpfte Fahrten."],
            "Enables receipt storage and expense evidence.": [.dutch: "Schakelt bonnenopslag en betaalbewijzen in.", .german: "Aktiviert Belegablage und Ausgabennachweise."],
            "Enables overdue invoice reminders.": [.dutch: "Schakelt herinneringen voor achterstallige facturen in.", .german: "Aktiviert Erinnerungen für überfällige Rechnungen."],
            "Enables recurring invoice templates.": [.dutch: "Schakelt terugkerende factuurtemplates in.", .german: "Aktiviert Vorlagen für wiederkehrende Rechnungen."],
            "Enables customer signatures on invoices and quotes.": [.dutch: "Schakelt klantondertekeningen op facturen en offertes in.", .german: "Aktiviert Kundenunterschriften auf Rechnungen und Angeboten."],
            "Enables quarterly VAT reporting.": [.dutch: "Schakelt kwartaal-btw-overzichten in.", .german: "Aktiviert vierteljährliche MwSt.-Berichte."],
            "Enables annual revenue summaries.": [.dutch: "Schakelt jaaromzetoverzichten in.", .german: "Aktiviert Jahresumsatzübersichten."],
            "Enables multiple company profiles and export branding.": [.dutch: "Schakelt meerdere bedrijfsprofielen en exportbranding in.", .german: "Aktiviert mehrere Firmenprofile und Export-Branding."],
            "Work Registrations": [.dutch: "Werkregistraties", .german: "Arbeitserfassungen"],
            "Time Tracking": [.dutch: "Urenregistratie", .german: "Zeiterfassung"],
            "Mileage Tracking": [.dutch: "Kilometerregistratie", .german: "Kilometererfassung"],
            "Payment Reminders": [.dutch: "Betalingsherinneringen", .german: "Zahlungserinnerungen"],
            "Recurring Invoices": [.dutch: "Terugkerende facturen", .german: "Wiederkehrende Rechnungen"],
            "Customer Signatures": [.dutch: "Klanthandtekeningen", .german: "Kundenunterschriften"],
            "VAT Overview": [.dutch: "Btw-overzicht", .german: "MwSt.-Übersicht"],
            "Annual Revenue Summary": [.dutch: "Jaaromzetoverzicht", .german: "Jahresumsatzübersicht"],
            "Multiple Company Profiles": [.dutch: "Meerdere bedrijfsprofielen", .german: "Mehrere Firmenprofile"],
            "Invoice by period": [.dutch: "Factuur per periode", .german: "Rechnung nach Zeitraum"],
            "Confirm": [.dutch: "Bevestig", .german: "Bestätigen"],
            "Invoice Workflow": [.dutch: "Factuurworkflow", .german: "Rechnungsworkflow"],
            "Generate invoices by period": [.dutch: "Facturen per periode genereren", .german: "Rechnungen nach Zeitraum erstellen"],
            "Mode": [.dutch: "Modus", .german: "Modus"],
            "Week": [.dutch: "Week", .german: "Woche"],
            "Month": [.dutch: "Maand", .german: "Monat"],
            "All clients": [.dutch: "Alle klanten", .german: "Alle Kunden"],
            "Group lines": [.dutch: "Regels groeperen", .german: "Zeilen gruppieren"],
            "Prepare review": [.dutch: "Controle voorbereiden", .german: "Prüfung vorbereiten"],
            "Review before confirming": [.dutch: "Controleer voor bevestigen", .german: "Vor Bestätigung prüfen"],
            "No uninvoiced registrations found for that period.": [.dutch: "Geen niet-gefactureerde registraties gevonden voor die periode.", .german: "Keine nicht abgerechneten Erfassungen für diesen Zeitraum gefunden."],
            "registrations": [.dutch: "registraties", .german: "Erfassungen"],
            "Invoice Signature": [.dutch: "Factuurhandtekening", .german: "Rechnungsunterschrift"],
            "Payment Details": [.dutch: "Betaalgegevens", .german: "Zahlungsdetails"],
            "Mark as Sent": [.dutch: "Markeer als verzonden", .german: "Als gesendet markieren"],
            "Mark as Paid": [.dutch: "Markeer als betaald", .german: "Als bezahlt markieren"],
            "Mark as Unpaid": [.dutch: "Markeer als onbetaald", .german: "Als unbezahlt markieren"],
            "From": [.dutch: "Van", .german: "Von"],
            "To": [.dutch: "Tot", .german: "Bis"],
            "Quotes and estimates": [.dutch: "Offertes en schattingen", .german: "Angebote und Kostenvoranschläge"],
            "Prepare proposals before they become invoices.": [.dutch: "Maak voorstellen voordat ze facturen worden.", .german: "Bereite Angebote vor, bevor daraus Rechnungen werden."],
            "No quotes created yet.": [.dutch: "Nog geen offertes aangemaakt.", .german: "Noch keine Angebote erstellt."],
            "Quarterly VAT overview": [.dutch: "Btw-overzicht per kwartaal", .german: "Quartalsübersicht MwSt."],
            "Review taxable revenue, VAT charged, and paid versus unpaid invoice totals per quarter.": [.dutch: "Bekijk belastbare omzet, berekende btw en betaalde versus openstaande facturen per kwartaal.", .german: "Prüfe steuerpflichtigen Umsatz, berechnete MwSt. und bezahlte gegenüber offenen Rechnungen pro Quartal."],
            "Revenue by day": [.dutch: "Omzet per dag", .german: "Umsatz pro Tag"],
            "Daily revenue": [.dutch: "Dagomzet", .german: "Tagesumsatz"],
            "Average per day": [.dutch: "Gemiddelde per dag", .german: "Durchschnitt pro Tag"],
            "Highest": [.dutch: "Hoogste", .german: "Höchste"],
            "No invoices dated in this period.": [.dutch: "Geen facturen gevonden in deze periode.", .german: "Keine Rechnungen in diesem Zeitraum gefunden."],
            "Payment reminders": [.dutch: "Betalingsherinneringen", .german: "Zahlungserinnerungen"],
            "Track overdue invoices and prepare reminder messages before you follow up.": [.dutch: "Volg achterstallige facturen en bereid herinneringen voor.", .german: "Verfolge überfällige Rechnungen und bereite Erinnerungen vor."],
            "All sent invoices are still within their payment term.": [.dutch: "Alle verzonden facturen vallen nog binnen de betaaltermijn.", .german: "Alle gesendeten Rechnungen liegen noch innerhalb der Zahlungsfrist."],
            "days overdue": [.dutch: "dagen te laat", .german: "Tage überfällig"],
            "Recurring invoices": [.dutch: "Terugkerende facturen", .german: "Wiederkehrende Rechnungen"],
            "Save repeat billing templates and generate draft invoices for each due cycle.": [.dutch: "Bewaar herhaalfacturen en genereer conceptfacturen per cyclus.", .german: "Speichere wiederkehrende Vorlagen und erstelle Entwurfsrechnungen je Fälligkeit."],
            "No recurring templates configured yet.": [.dutch: "Nog geen terugkerende templates ingesteld.", .german: "Noch keine wiederkehrenden Vorlagen eingerichtet."],
            "Apply Suggestions": [.dutch: "Suggesties toepassen", .german: "Vorschläge anwenden"],
            "Keep Current Draft": [.dutch: "Huidig concept behouden", .german: "Aktuellen Entwurf behalten"],
            "Quote conversion draft": [.dutch: "Concept uit offerte", .german: "Entwurf aus Angebot"],
            "Factuur maken in 3 stappen": [.english: "Create invoice in 3 steps", .german: "Rechnung in 3 Schritten erstellen"],
            "Kies eerst de klant, bepaal daarna hoe je de factuur wilt opbouwen en sla het concept op zodra het totaal klopt.": [.english: "Choose the client first, then decide how to build the invoice and save the draft once the total is correct.", .german: "Wähle zuerst den Kunden, lege dann den Rechnungsaufbau fest und speichere den Entwurf, sobald die Summe stimmt."],
            "Factuur opbouwen": [.english: "Build invoice", .german: "Rechnung erstellen"],
            "Manier van factureren": [.english: "Invoicing method", .german: "Abrechnungsmethode"],
            "Klant": [.english: "Client", .german: "Kunde"],
            "Kies een klant": [.english: "Choose a client", .german: "Kunden auswählen"],
            "Standaard uurtarief klant": [.english: "Client default hourly rate", .german: "Standard-Stundensatz des Kunden"],
            "Bijvoorbeeld 85": [.english: "For example 85", .german: "Zum Beispiel 85"],
            "Bewaar uurtarief voor klant": [.english: "Save hourly rate for client", .german: "Stundensatz für Kunden speichern"],
            "Factuurgegevens": [.english: "Invoice details", .german: "Rechnungsdetails"],
            "Factuurdatum": [.english: "Invoice date", .german: "Rechnungsdatum"],
            "Vervaldatum": [.english: "Due date", .german: "Fälligkeitsdatum"],
            "Notities op factuur": [.english: "Invoice notes", .german: "Rechnungsnotizen"],
            "Periode voor registraties": [.english: "Registration period", .german: "Erfassungszeitraum"],
            "Van": [.english: "From", .german: "Von"],
            "Tot": [.english: "To", .german: "Bis"],
            "Registraties groeperen": [.english: "Group registrations", .german: "Erfassungen gruppieren"],
            "Acties": [.english: "Actions", .german: "Aktionen"],
            "Nieuwe klant": [.english: "New client", .german: "Neuer Kunde"],
            "Factuur per periode": [.english: "Invoice by period", .german: "Rechnung nach Zeitraum"],
            "Factuur op uren en producten": [.english: "Invoice by hours and products", .german: "Rechnung nach Stunden und Produkten"],
            "Factuur op uren": [.english: "Invoice by hours", .german: "Rechnung nach Stunden"],
            "Factuur op producten": [.english: "Invoice by products", .german: "Rechnung nach Produkten"],
            "Genereer regels uit registraties": [.english: "Generate lines from registrations", .german: "Zeilen aus Erfassungen erstellen"],
            "Hiermee combineer je uurregels voor werkzaamheden met aparte productregels voor materialen en aantallen. Dit is de aanbevolen modus voor gemengde facturen.": [.english: "This combines hourly lines for work with separate product lines for materials and quantities. This is the recommended mode for mixed invoices.", .german: "Damit kombinierst du Stundenzeilen für Arbeiten mit separaten Produktzeilen für Materialien und Mengen. Dies ist der empfohlene Modus für gemischte Rechnungen."],
            "Registraties": [.english: "Registrations", .german: "Erfassungen"],
            "geselecteerd": [.english: "selected", .german: "ausgewählt"],
            "Alles": [.english: "All", .german: "Alle"],
            "Leeg": [.english: "Clear", .german: "Leeren"],
            "Factuurregels": [.english: "Invoice lines", .german: "Rechnungszeilen"],
            "Concept opslaan": [.english: "Save draft", .german: "Entwurf speichern"],
            "Voeg zelf regels toe of genereer ze uit de geselecteerde registraties.": [.english: "Add lines manually or generate them from selected registrations.", .german: "Füge Zeilen manuell hinzu oder erstelle sie aus ausgewählten Erfassungen."],
            "Btw-overzicht": [.english: "VAT breakdown", .german: "MwSt.-Übersicht"],
            "All invoices": [.dutch: "Alle facturen", .german: "Alle Rechnungen"],
            "No invoices match the current filters.": [.dutch: "Geen facturen gevonden voor de huidige filters.", .german: "Keine Rechnungen passen zu den aktuellen Filtern."],
            "Netto": [.english: "Net", .german: "Netto"],
            "Btw": [.english: "VAT", .german: "MwSt."],
            "Bruto": [.english: "Gross", .german: "Brutto"]
        ]
    }
}
