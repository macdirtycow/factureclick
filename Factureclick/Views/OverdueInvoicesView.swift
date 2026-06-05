//
//  OverdueInvoicesView.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import SwiftData
import SwiftUI

struct OverdueInvoicesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var appSettings: [AppSettings]

    let invoices: [Invoice]
    let collaborationRules: [CollaborationRule]

    @State private var previewDraft: PaymentReminderDraft?
    @State private var errorMessage: String?

    private let overdueService = OverdueInvoiceService()
    private let reminderService = PaymentReminderService()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if overdueSummaries.isEmpty {
                    SectionCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(localization.phrase("No overdue invoices"))
                                .font(AppTheme.titleFont)
                                .foregroundStyle(AppTheme.primaryText)
                            Text(localization.phrase("Payment reminders will appear here when unpaid invoices pass their due date."))
                                .font(AppTheme.bodyFont)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                } else {
                    ForEach(overdueSummaries) { summary in
                        SectionCard {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(summary.invoice.invoiceNumber)
                                            .font(AppTheme.sectionTitleFont)
                                            .foregroundStyle(AppTheme.primaryText)
                                        Text(summary.invoice.client.name)
                                            .font(AppTheme.bodyFont)
                                            .foregroundStyle(AppTheme.secondaryText)
                                    }

                                    Spacer()

                                    Text(summary.invoice.totalAmount.formatted(.currency(code: Locale.current.currency?.identifier ?? "EUR")))
                                        .font(AppTheme.sectionTitleFont)
                                        .foregroundStyle(AppTheme.primaryText)
                                }

                                HStack {
                                    ReminderBadge(title: localization.phrase("Overdue"), systemImage: "exclamationmark.triangle", tint: .red)
                                    ReminderBadge(title: "\(summary.daysOverdue) \(localization.phrase("days"))", systemImage: "calendar", tint: .orange)
                                    if let lastReminder = summary.lastReminder {
                                        reminderStatusBadge(for: lastReminder.status)
                                    }
                                }

                                Text("\(localization.phrase("Due")) \(summary.invoice.dueDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(AppTheme.bodyFont)
                                    .foregroundStyle(AppTheme.secondaryText)

                                if let lastReminder = summary.lastReminder {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(localization.phrase("Last reminder"))
                                            .font(AppTheme.captionFont)
                                            .foregroundStyle(AppTheme.secondaryText)
                                        Text("\(localization.phrase(lastReminder.level.displayName)) \(localization.phrase("on")) \(lastReminder.createdAt.formatted(date: .abbreviated, time: .shortened))")
                                            .font(AppTheme.bodyFont.weight(.semibold))
                                            .foregroundStyle(AppTheme.primaryText)
                                    }
                                }

                                HStack {
                                    NavigationLink(localization.phrase("Open Invoice")) {
                                        InvoicePreviewView(
                                            invoice: summary.invoice,
                                            collaborationRule: collaborationRules.first(where: { $0.client?.id == summary.invoice.client.id })
                                        )
                                    }
                                    .buttonStyle(.bordered)

                                    Button(localization.phrase("Preview Next Reminder")) {
                                        previewDraft = reminderService.makeDraft(
                                            for: summary.invoice,
                                            localeIdentifier: appSettings.first?.preferredLocaleIdentifier
                                        )
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(AppTheme.accentColor)

                                    Menu(localization.phrase("Manual Level")) {
                                        ForEach(InvoiceReminderLevel.allCases) { level in
                                            Button(localization.phrase(level.displayName)) {
                                                previewDraft = reminderService.makeDraft(
                                                    for: summary.invoice,
                                                    level: level,
                                                    localeIdentifier: appSettings.first?.preferredLocaleIdentifier
                                                )
                                            }
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(AppTheme.screenBackground.ignoresSafeArea())
        .navigationTitle(localization.phrase("Payment reminders"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $previewDraft) { draft in
            if let invoice = invoices.first(where: { $0.id == draft.invoiceID }) {
                ReminderPreviewView(invoice: invoice, initialDraft: draft) { updatedDraft, markAsSent in
                    try saveReminder(updatedDraft, for: invoice, markAsSent: markAsSent)
                }
            }
        }
        .alert(localization.text(.unableToSaveReminder), isPresented: errorBinding) {
            Button(localization.phrase("OK"), role: .cancel) { }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var overdueSummaries: [OverdueInvoiceSummary] {
        overdueService.overdueInvoices(from: invoices)
    }

    private func saveReminder(_ draft: PaymentReminderDraft, for invoice: Invoice, markAsSent: Bool) throws {
        let reminder = reminderService.createReminder(
            from: draft,
            for: invoice,
            sentAt: markAsSent ? .now : nil
        )
        if draft.existingReminderID == nil {
            modelContext.insert(reminder)
        }
        do {
            try modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    private func reminderStatusBadge(for status: InvoiceReminderStatus) -> some View {
        ReminderBadge(
            title: localization.phrase(status.displayName),
            systemImage: status == .draft ? "square.and.pencil" : "paperplane",
            tint: status == .draft ? .gray : .green
        )
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private var localization: AppLocalization {
        AppLocalization(localeIdentifier: appSettings.first?.preferredLocaleIdentifier)
    }
}
