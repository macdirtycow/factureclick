//
//  WorkModeConfiguration.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import Foundation
import SwiftData

enum WorkMode: String, CaseIterable, Codable, Identifiable {
    case freelancer
    case quoteBusiness
    case hybrid
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .freelancer:
            "Freelancer"
        case .quoteBusiness:
            "Quote / Business"
        case .hybrid:
            "All"
        case .custom:
            "Custom"
        }
    }

    var summary: String {
        switch self {
        case .freelancer:
            "Focus on agenda planning, work registrations, time tracking, and invoice creation from completed work."
        case .quoteBusiness:
            "Focus on proposals, client-facing business workflows, recurring invoices, reminders, and signatures."
        case .hybrid:
            "Enable every workflow and tool in one complete setup."
        case .custom:
            "Choose exactly which modules, tabs, and business tools should be available."
        }
    }
}

enum AppModule: String, CaseIterable, Codable, Identifiable {
    case agenda
    case workRegistrations
    case timeTracking
    case quotes
    case invoices
    case mileageTracking
    case receipts
    case paymentReminders
    case recurringInvoices
    case customerSignatures
    case vatOverview
    case annualRevenueSummary
    case multipleCompanyProfiles

    var id: String { rawValue }

    var title: String {
        switch self {
        case .agenda:
            "Agenda"
        case .workRegistrations:
            "Work Registrations"
        case .timeTracking:
            "Time Tracking"
        case .quotes:
            "Quotes"
        case .invoices:
            "Invoices"
        case .mileageTracking:
            "Mileage Tracking"
        case .receipts:
            "Receipts"
        case .paymentReminders:
            "Payment Reminders"
        case .recurringInvoices:
            "Recurring Invoices"
        case .customerSignatures:
            "Customer Signatures"
        case .vatOverview:
            "VAT Overview"
        case .annualRevenueSummary:
            "Annual Revenue Summary"
        case .multipleCompanyProfiles:
            "Multiple Company Profiles"
        }
    }
}

@Model
final class ModuleVisibilityConfiguration {
    var agendaEnabled: Bool
    var workRegistrationsEnabled: Bool
    var timeTrackingEnabled: Bool
    var quotesEnabled: Bool
    var invoicesEnabled: Bool
    var mileageTrackingEnabled: Bool
    var receiptsEnabled: Bool
    var paymentRemindersEnabled: Bool
    var recurringInvoicesEnabled: Bool
    var customerSignaturesEnabled: Bool
    var vatOverviewEnabled: Bool
    var annualRevenueSummaryEnabled: Bool
    var multipleCompanyProfilesEnabled: Bool
    var updatedAt: Date
    var createdAt: Date

    init(
        agendaEnabled: Bool = true,
        workRegistrationsEnabled: Bool = true,
        timeTrackingEnabled: Bool = true,
        quotesEnabled: Bool = true,
        invoicesEnabled: Bool = true,
        mileageTrackingEnabled: Bool = true,
        receiptsEnabled: Bool = true,
        paymentRemindersEnabled: Bool = true,
        recurringInvoicesEnabled: Bool = true,
        customerSignaturesEnabled: Bool = true,
        vatOverviewEnabled: Bool = true,
        annualRevenueSummaryEnabled: Bool = true,
        multipleCompanyProfilesEnabled: Bool = true,
        updatedAt: Date = .now,
        createdAt: Date = .now
    ) {
        self.agendaEnabled = agendaEnabled
        self.workRegistrationsEnabled = workRegistrationsEnabled
        self.timeTrackingEnabled = timeTrackingEnabled
        self.quotesEnabled = quotesEnabled
        self.invoicesEnabled = invoicesEnabled
        self.mileageTrackingEnabled = mileageTrackingEnabled
        self.receiptsEnabled = receiptsEnabled
        self.paymentRemindersEnabled = paymentRemindersEnabled
        self.recurringInvoicesEnabled = recurringInvoicesEnabled
        self.customerSignaturesEnabled = customerSignaturesEnabled
        self.vatOverviewEnabled = vatOverviewEnabled
        self.annualRevenueSummaryEnabled = annualRevenueSummaryEnabled
        self.multipleCompanyProfilesEnabled = multipleCompanyProfilesEnabled
        self.updatedAt = updatedAt
        self.createdAt = createdAt
    }

    func isEnabled(_ module: AppModule) -> Bool {
        switch module {
        case .agenda:
            agendaEnabled
        case .workRegistrations:
            workRegistrationsEnabled
        case .timeTracking:
            timeTrackingEnabled
        case .quotes:
            quotesEnabled
        case .invoices:
            invoicesEnabled
        case .mileageTracking:
            mileageTrackingEnabled
        case .receipts:
            receiptsEnabled
        case .paymentReminders:
            paymentRemindersEnabled
        case .recurringInvoices:
            recurringInvoicesEnabled
        case .customerSignatures:
            customerSignaturesEnabled
        case .vatOverview:
            vatOverviewEnabled
        case .annualRevenueSummary:
            annualRevenueSummaryEnabled
        case .multipleCompanyProfiles:
            multipleCompanyProfilesEnabled
        }
    }

    func setEnabled(_ isEnabled: Bool, for module: AppModule) {
        switch module {
        case .agenda:
            agendaEnabled = isEnabled
        case .workRegistrations:
            workRegistrationsEnabled = isEnabled
        case .timeTracking:
            timeTrackingEnabled = isEnabled
        case .quotes:
            quotesEnabled = isEnabled
        case .invoices:
            invoicesEnabled = isEnabled
        case .mileageTracking:
            mileageTrackingEnabled = isEnabled
        case .receipts:
            receiptsEnabled = isEnabled
        case .paymentReminders:
            paymentRemindersEnabled = isEnabled
        case .recurringInvoices:
            recurringInvoicesEnabled = isEnabled
        case .customerSignatures:
            customerSignaturesEnabled = isEnabled
        case .vatOverview:
            vatOverviewEnabled = isEnabled
        case .annualRevenueSummary:
            annualRevenueSummaryEnabled = isEnabled
        case .multipleCompanyProfiles:
            multipleCompanyProfilesEnabled = isEnabled
        }

        updatedAt = .now
    }
}
