//
//  ReminderPreviewView.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import SwiftData
import SwiftUI

struct ReminderPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var appSettings: [AppSettings]

    let invoice: Invoice
    let onSave: (PaymentReminderDraft, Bool) throws -> Void

    @State private var draft: PaymentReminderDraft
    @State private var errorMessage: String?

    private let reminderService = PaymentReminderService()

    init(
        invoice: Invoice,
        initialDraft: PaymentReminderDraft,
        onSave: @escaping (PaymentReminderDraft, Bool) throws -> Void
    ) {
        self.invoice = invoice
        self.onSave = onSave
        _draft = State(initialValue: initialDraft)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SectionCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(localization.phrase("Reminder preview"))
                                .font(AppTheme.titleFont)
                                .foregroundStyle(AppTheme.primaryText)

                            HStack {
                                reminderLevelBadge(for: draft.level)
                                ReminderBadge(
                                    title: invoice.status == .paid ? localization.phrase("Paid") : localization.phrase("Unpaid"),
                                    systemImage: invoice.status == .paid ? "checkmark.circle" : "clock",
                                    tint: invoice.status == .paid ? .green : .orange
                                )
                            }

                            summaryRow(localization.phrase("Client"), draft.clientName)
                            summaryRow(localization.phrase("Invoice"), draft.invoiceNumber)
                            summaryRow(localization.phrase("Amount due"), draft.amountDue.formatted(.currency(code: Locale.current.currency?.identifier ?? "EUR")))
                            summaryRow(localization.phrase("Due date"), draft.dueDate.formatted(date: .abbreviated, time: .omitted))
                        }
                    }

                    SectionCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Picker(localization.phrase("Reminder level"), selection: $draft.level) {
                                ForEach(InvoiceReminderLevel.allCases) { level in
                                    Text(localization.phrase(level.displayName)).tag(level)
                                }
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: draft.level) { _, newLevel in
                                let regeneratedDraft = reminderService.makeDraft(
                                    for: invoice,
                                    level: newLevel,
                                    localeIdentifier: appSettings.first?.preferredLocaleIdentifier
                                )
                                draft.subject = regeneratedDraft.subject
                                draft.messageBody = regeneratedDraft.messageBody
                                draft = PaymentReminderDraft(
                                    id: draft.id,
                                    invoiceID: draft.invoiceID,
                                    existingReminderID: draft.existingReminderID,
                                    level: draft.level,
                                    subject: regeneratedDraft.subject,
                                    messageBody: regeneratedDraft.messageBody,
                                    clientName: draft.clientName,
                                    invoiceNumber: draft.invoiceNumber,
                                    amountDue: draft.amountDue,
                                    dueDate: regeneratedDraft.dueDate
                                )
                            }

                            TextField(localization.phrase("Subject"), text: $draft.subject)
                                .textFieldStyle(.roundedBorder)

                            TextEditor(text: $draft.messageBody)
                                .frame(minHeight: 220)
                                .padding(12)
                                .background(AppTheme.elevatedBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(AppTheme.screenBackground.ignoresSafeArea())
            .navigationTitle(localization.phrase("Reminder"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(localization.phrase("Close")) {
                        dismiss()
                    }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button(localization.phrase("Save Draft")) {
                        saveReminder(markAsSent: false)
                    }

                    Button(localization.phrase("Save & Sent")) {
                        saveReminder(markAsSent: true)
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert(localization.text(.unableToSaveReminder), isPresented: errorBinding) {
                Button(localization.phrase("OK"), role: .cancel) { }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func saveReminder(markAsSent: Bool) {
        do {
            try onSave(draft, markAsSent)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @ViewBuilder
    private func summaryRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(AppTheme.secondaryText)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(AppTheme.primaryText)
        }
        .font(AppTheme.bodyFont)
    }

    private func reminderLevelBadge(for level: InvoiceReminderLevel) -> some View {
        ReminderBadge(
            title: localization.phrase(level.displayName),
            systemImage: level == .friendly ? "hand.wave" : level == .second ? "bell.badge" : "exclamationmark.bubble",
            tint: level == .friendly ? .blue : level == .second ? .orange : .red
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
