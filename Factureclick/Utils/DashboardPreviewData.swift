//
//  DashboardPreviewData.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation
import SwiftData

enum DashboardPreviewData {
    static func makeContainer() -> ModelContainer {
        let container = ModelContainerFactory.makeShared(isStoredInMemoryOnly: true)
        let context = container.mainContext
        let calendar = Calendar.current
        let now = Date()
        let appSettings = AppSettings(
            preferredLocaleIdentifier: SupportedLocale.english.rawValue,
            appearancePreference: .system,
            workMode: .hybrid,
            invoiceNumberPrefix: "TB",
            defaultPaymentTermDays: 14,
            defaultVATRate: 21,
            preferredAccentColorHex: "#1F6FE5",
            hasCompletedWorkModeOnboarding: true
        )
        let moduleConfiguration = WorkModeConfigurationService().makeConfiguration(for: .hybrid)
        let companyProfile = CompanyProfile(
            name: "Factureclick Studio",
            ownerName: "Leopold Janssen",
            kvkNumber: "12345678",
            vatNumber: "NL123456789B01",
            iban: "NL91ABNA0417164300",
            email: "hello@factureclick.app",
            phone: "+31 20 123 4567",
            address: "Herengracht 21, Amsterdam",
            logoData: nil,
            defaultInvoiceText: "Thank you for choosing Factureclick Studio. We appreciate your trust.",
            defaultPaymentText: "Please transfer the amount within 14 days and mention the invoice number.",
            isPayPalPaymentEnabled: true,
            paypalPaymentURL: "https://paypal.me/factureclick/2380",
            showSEPAPaymentQRCode: true,
            accentColor: "#1F6FE5"
        )
        appSettings.activeCompanyProfileID = companyProfile.id

        let client = Client(
            name: "Studio Noord",
            contactPerson: "Mila Peters",
            email: "mila@studionoord.nl",
            phone: "+31 6 00000000",
            address: "Keizersgracht 120, Amsterdam",
            paymentTermDays: 14,
            defaultHourlyRate: 95,
            notes: "Prefers invoices grouped by service type.",
            companyProfile: companyProfile
        )

        let product = Product(
            name: "Installation",
            description: "On-site installation work",
            price: 95,
            vatRate: 21,
            unitType: .hour
        )

        let partnerRule = CollaborationRule(
            client: client,
            percentage: 15,
            partnerName: "North Partner",
            notes: "Shared installation partnership"
        )

        let invoice = Invoice(
            invoiceNumber: "2026-014",
            client: client,
            date: now,
            dueDate: calendar.date(byAdding: .day, value: 14, to: now) ?? now,
            status: .sent,
            notes: "On-site installation and support summary for this period.",
            totalAmount: 2380,
            vatAmount: 413,
            createdAt: now,
            companyProfile: companyProfile
        )

        let paidInvoice = Invoice(
            invoiceNumber: "2026-013",
            client: client,
            date: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
            dueDate: calendar.date(byAdding: .day, value: 12, to: now) ?? now,
            status: .paid,
            totalAmount: 1460,
            vatAmount: 253,
            createdAt: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
            companyProfile: companyProfile
        )

        let invoiceLine = InvoiceLine(
            description: "Installation work",
            quantity: 8,
            unitPrice: 95,
            vatRate: 21,
            invoice: invoice
        )

        let paidInvoiceLine = InvoiceLine(
            description: "Maintenance support",
            quantity: 4,
            unitPrice: 85,
            vatRate: 21,
            invoice: paidInvoice
        )

        let quote = Quote(
            quoteNumber: "Q-2026-001",
            client: client,
            date: now,
            expiryDate: calendar.date(byAdding: .day, value: 14, to: now) ?? now,
            status: .sent,
            subtotalAmount: 760,
            vatAmount: 159.6,
            totalAmount: 919.6,
            notes: "Estimate for installation and support.",
            companyProfile: companyProfile
        )

        let quoteLine = QuoteLine(
            description: "Installation package",
            quantity: 8,
            unitPrice: 95,
            vatRate: 21,
            quote: quote,
            linkedProduct: product
        )

        invoice.lines = [invoiceLine]
        paidInvoice.lines = [paidInvoiceLine]
        quote.lines = [quoteLine]

        let workEntryOne = WorkEntry(
            date: now,
            client: client,
            hoursWorked: 6.5,
            hourlyRateOverride: 102,
            product: product,
            quantity: 4,
            notes: "Installation and handover",
            includeInInvoice: true,
            isInvoiced: false,
            collaborationRule: partnerRule,
            companyProfile: companyProfile
        )

        let workEntryTwo = WorkEntry(
            date: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
            client: client,
            hoursWorked: 5,
            hourlyRateOverride: nil,
            product: product,
            quantity: 3,
            notes: "Follow-up adjustments",
            includeInInvoice: true,
            isInvoiced: true,
            companyProfile: companyProfile
        )

        let workEntryThree = WorkEntry(
            date: calendar.date(byAdding: .day, value: -3, to: now) ?? now,
            client: client,
            hoursWorked: 2.5,
            hourlyRateOverride: 88,
            product: nil,
            quantity: 1,
            notes: "Travel and planning",
            includeInInvoice: false,
            isInvoiced: false,
            companyProfile: companyProfile
        )

        let mileageEntry = MileageEntry(
            date: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
            client: client,
            startLocation: "Amsterdam",
            endLocation: "Rotterdam",
            purpose: "Site visit",
            numberOfKilometers: 78,
            reimbursementRatePerKilometer: 0.23,
            totalTravelCost: 17.94,
            includeOnInvoice: true,
            invoice: invoice
        )

        let receipt = Receipt(
            date: calendar.date(byAdding: .day, value: -4, to: now) ?? now,
            supplierName: "NS Business Card",
            amount: 24.75,
            vatAmount: 4.29,
            category: .travel,
            linkedClient: client,
            linkedInvoice: invoice,
            notes: "Train ticket for client visit.",
            fileName: "sample-receipt.jpg",
            localPath: "",
            contentType: "public.jpeg",
            fileSize: 0,
            importSource: .photoLibrary
        )

        let signature = CustomerSignature(
            signerName: "Mila Peters",
            dateSigned: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
            note: "Approved after on-site review.",
            imageFileName: "preview-signature.png",
            imageLocalPath: "",
            strokeFileName: nil,
            strokeLocalPath: nil,
            fileSize: 0,
            strokeCount: 2,
            pointCount: 12,
            quote: quote
        )
        quote.customerSignature = signature

        context.insert(appSettings)
        context.insert(moduleConfiguration)
        context.insert(companyProfile)
        context.insert(client)
        context.insert(product)
        context.insert(partnerRule)
        context.insert(invoice)
        context.insert(paidInvoice)
        context.insert(quote)
        context.insert(workEntryOne)
        context.insert(workEntryTwo)
        context.insert(workEntryThree)
        context.insert(mileageEntry)
        context.insert(receipt)
        context.insert(signature)

        return container
    }
}
