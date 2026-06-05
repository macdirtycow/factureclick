//
//  AppViewModel.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation
import Observation

@Observable
final class AppViewModel {
    var selectedTab: AppTab = .dashboard
    var shouldPresentWorkEntryForm = false
    var pendingInvoiceWorkflow: InvoiceWorkflowLaunchContext?
    var pendingInvoiceWorkflowRequestID = UUID()
    var pendingQuoteConversion: QuoteInvoiceDraftContext?
    var pendingWeeklyReviewDate: Date?

    func openWorkEntryForm(preferAgenda: Bool) {
        selectedTab = preferAgenda ? .agenda : .registrations
        DispatchQueue.main.async { [weak self] in
            self?.shouldPresentWorkEntryForm = true
        }
    }

    func openInvoiceWorkflow(_ context: InvoiceWorkflowLaunchContext? = nil) {
        pendingInvoiceWorkflow = context
        pendingInvoiceWorkflowRequestID = UUID()
        selectedTab = .invoices
    }

    func consumeInvoiceWorkflow() -> InvoiceWorkflowLaunchContext? {
        let context = pendingInvoiceWorkflow
        pendingInvoiceWorkflow = nil
        return context
    }

    func openQuoteConversionWorkflow(_ context: QuoteInvoiceDraftContext) {
        pendingQuoteConversion = context
        selectedTab = .invoices
    }

    func consumeQuoteConversionWorkflow() -> QuoteInvoiceDraftContext? {
        let context = pendingQuoteConversion
        pendingQuoteConversion = nil
        return context
    }

    func openWeeklyInvoiceReview(for referenceDate: Date = .now) {
        pendingWeeklyReviewDate = referenceDate
        selectedTab = .invoices
    }

    func consumeWeeklyInvoiceReviewDate() -> Date? {
        let date = pendingWeeklyReviewDate
        pendingWeeklyReviewDate = nil
        return date
    }
}
