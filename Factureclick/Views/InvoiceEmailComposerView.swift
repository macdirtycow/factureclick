//
//  InvoiceEmailComposerView.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import MessageUI
import SwiftData
import SwiftUI

struct InvoiceEmailComposerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var appSettings: [AppSettings]

    let draft: InvoiceEmailDraft
    let attachment: ExportedInvoiceFile
    let canSendMail: Bool
    let onInitiate: (InvoiceEmailDraft) throws -> Void
    let onMailResult: (InvoiceEmailDraft, MFMailComposeResult, Error?) -> Void

    @State private var recipientEmail: String
    @State private var subject: String
    @State private var bodyText: String
    @State private var mailPayload: MailComposePayload?
    @State private var errorMessage: String?
    @State private var isPresentingFallbackShare = false

    init(
        draft: InvoiceEmailDraft,
        attachment: ExportedInvoiceFile,
        canSendMail: Bool,
        onInitiate: @escaping (InvoiceEmailDraft) throws -> Void,
        onMailResult: @escaping (InvoiceEmailDraft, MFMailComposeResult, Error?) -> Void
    ) {
        self.draft = draft
        self.attachment = attachment
        self.canSendMail = canSendMail
        self.onInitiate = onInitiate
        self.onMailResult = onMailResult
        _recipientEmail = State(initialValue: draft.recipientEmail)
        _subject = State(initialValue: draft.subject)
        _bodyText = State(initialValue: draft.body)
    }

    var body: some View {
        Form {
            Section(localization.phrase("Attachment")) {
                detailRow(localization.phrase("File"), attachment.fileName)
                detailRow(localization.phrase("Size"), ByteCountFormatter.string(fromByteCount: attachment.fileSize, countStyle: .file))
            }

            Section(localization.text(.email)) {
                TextField(localization.phrase("Recipient"), text: $recipientEmail)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                TextField(localization.phrase("Subject"), text: $subject)
                TextField(localization.phrase("Message"), text: $bodyText, axis: .vertical)
                    .lineLimit(8, reservesSpace: true)
            }

            if !canSendMail {
                Section(localization.phrase("Mail Unavailable")) {
                    Text(localization.phrase("Mail is not configured on this device. You can still share the PDF attachment manually."))
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.secondaryText)

                    Button(localization.phrase("Share PDF Instead")) {
                        isPresentingFallbackShare = true
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.screenBackground.ignoresSafeArea())
        .navigationTitle(localization.phrase("Send Invoice"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isPresentingFallbackShare) {
            ActivityShareSheet(items: [attachment.url])
        }
        .sheet(isPresented: mailComposeBinding) {
            if let payload = mailPayload {
                MailComposeView(payload: payload) { result, error in
                    onMailResult(currentDraft, result, error)
                }
            }
        }
        .alert(localization.text(.email), isPresented: errorBinding) {
            Button(localization.phrase("OK"), role: .cancel) { }
        } message: {
            Text(errorMessage ?? "")
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(localization.phrase("Close")) {
                    dismiss()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(canSendMail ? localization.phrase("Send") : localization.phrase("Done")) {
                    if canSendMail {
                        send()
                    } else {
                        dismiss()
                    }
                }
                .disabled(canSendMail && !canInitiateSend)
            }
        }
    }

    private var currentDraft: InvoiceEmailDraft {
        InvoiceEmailDraft(
            recipientEmail: recipientEmail.trimmingCharacters(in: .whitespacesAndNewlines),
            subject: subject.trimmingCharacters(in: .whitespacesAndNewlines),
            body: bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    private var canInitiateSend: Bool {
        !currentDraft.recipientEmail.isEmpty && !currentDraft.subject.isEmpty
    }

    private func send() {
        do {
            try onInitiate(currentDraft)
            let attachmentData = try Data(contentsOf: attachment.url)
            mailPayload = MailComposePayload(
                recipients: [currentDraft.recipientEmail],
                subject: currentDraft.subject,
                body: currentDraft.body,
                isHTML: false,
                attachments: [
                    MailComposeAttachment(
                        data: attachmentData,
                        mimeType: "application/pdf",
                        fileName: attachment.fileName
                    )
                ]
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @ViewBuilder
    private func detailRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(AppTheme.secondaryText)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(AppTheme.primaryText)
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private var mailComposeBinding: Binding<Bool> {
        Binding(
            get: { mailPayload != nil },
            set: { if !$0 { mailPayload = nil } }
        )
    }

    private var localization: AppLocalization {
        AppLocalization(localeIdentifier: appSettings.first?.preferredLocaleIdentifier)
    }
}
