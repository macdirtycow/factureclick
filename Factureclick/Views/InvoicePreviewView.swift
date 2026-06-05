//
//  InvoicePreviewView.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import MessageUI
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct InvoicePreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CompanyProfile.name) private var companyProfiles: [CompanyProfile]
    @Query(sort: \Invoice.date, order: .reverse) private var invoices: [Invoice]
    @Query private var appSettings: [AppSettings]
    @Query private var moduleConfigurations: [ModuleVisibilityConfiguration]

    let invoice: Invoice
    let collaborationRule: CollaborationRule?

    private let repository = InvoiceRepository()
    private let calculationService = InvoiceFinancialCalculationService()
    private let collaborationRevenueService = CollaborationRevenueService()
    private let emailPreparationService = InvoiceEmailPreparationService()

    @State private var exportMessage: String?
    @State private var exportErrorMessage: String?
    @State private var emailStatusMessage: String?
    @State private var emailErrorMessage: String?
    @State private var sharedFile: ExportedInvoiceFile?
    @State private var isPresentingExportAlert = false
    @State private var isPresentingPaymentActions = false
    @State private var isImportingAttachment = false
    @State private var isPresentingSignatureCapture = false
    @State private var preparedEmail: PreparedInvoiceEmail?
    @State private var attachmentImportError: String?
    @State private var reminderDraft: PaymentReminderDraft?
    @State private var reminderErrorMessage: String?
    @State private var selectedInvoiceTemplateStyle: DocumentTemplateStyle?
    @State private var isPresentingDeleteConfirmation = false
    @State private var deleteErrorMessage: String?

    private let attachmentStorageService = AttachmentStorageService()
    private let reminderService = PaymentReminderService()
    private let signatureService = SignaturePersistenceService()
    private let workModeService = WorkModeConfigurationService()

    private var exportSourceInvoice: Invoice {
        invoices.first(where: { $0.id == invoice.id }) ?? invoice
    }

    var body: some View {
        let normalizedStatus = repository.normalizedStatus(for: invoice)
        let totals = calculationService.makeTotals(lines: previewLines, collaborationRule: collaborationRule)
        let collaborationBreakdown = collaborationRevenueService.makeBreakdown(grossAmount: totals.netSubtotal, rule: collaborationRule)
        configuredView(
            for: normalizedStatus,
            totals: totals,
            collaborationBreakdown: collaborationBreakdown
        )
    }

    private var previewLines: [InvoiceLineDraft] {
        exportSourceInvoice.lines.map {
            InvoiceLineDraft(
                id: $0.id,
                description: $0.description,
                quantity: $0.quantity,
                unitPrice: $0.unitPrice,
                vatRate: $0.vatRate,
                linkedWorkEntryIDs: $0.linkedWorkEntry.map { [$0.id] } ?? []
            )
        }
    }

    private func configuredView(
        for normalizedStatus: InvoiceStatus,
        totals: InvoiceDraftTotals,
        collaborationBreakdown: CollaborationRevenueBreakdown
    ) -> some View {
        applyPresentationModifiers(
            to: mainList(
                normalizedStatus: normalizedStatus,
                totals: totals,
                collaborationBreakdown: collaborationBreakdown
            )
        )
    }

    private func mainList(
        normalizedStatus: InvoiceStatus,
        totals: InvoiceDraftTotals,
        collaborationBreakdown: CollaborationRevenueBreakdown
    ) -> some View {
        List {
            overviewSection(normalizedStatus: normalizedStatus)
            notesSection
            statusSection(normalizedStatus: normalizedStatus)
            if !invoice.isCreditInvoice {
                paymentRemindersSection
            }
            linesSection
            totalsSection(totals: totals, collaborationBreakdown: collaborationBreakdown)
                .listRowBackground(AppTheme.cardBackground)
            if signaturesEnabled {
                signatureSection
            }
            linkedMileageSection
                .listRowBackground(AppTheme.cardBackground)
            exportSection
            attachmentsSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.screenBackground.ignoresSafeArea())
        .navigationTitle(invoice.invoiceNumber)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    isPresentingDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
    }

    private func applyPresentationModifiers<Content: View>(to view: Content) -> some View {
        view
            .alert(localization.text(.exportPDF), isPresented: $isPresentingExportAlert) {
                Button(localization.phrase("OK"), role: .cancel) {
                    exportMessage = nil
                }
            } message: {
                Text(exportMessage ?? "")
            }
            .alert(localization.text(.exportFailed), isPresented: exportErrorAlertBinding) {
                Button(localization.phrase("OK"), role: .cancel) { }
            } message: {
                Text(exportErrorMessage ?? "")
            }
            .sheet(item: $sharedFile) { sharedFile in
                ActivityShareSheet(items: [sharedFile.url])
            }
            .sheet(item: $reminderDraft) { draft in
                ReminderPreviewView(invoice: invoice, initialDraft: draft) { updatedDraft, markAsSent in
                    try saveReminder(updatedDraft, markAsSent: markAsSent)
                }
            }
            .sheet(item: $preparedEmail) { preparedEmail in
                NavigationStack {
                    InvoiceEmailComposerView(
                        draft: preparedEmail.draft,
                        attachment: preparedEmail.attachment,
                        canSendMail: MFMailComposeViewController.canSendMail(),
                        onInitiate: { draft in
                            try emailPreparationService.markEmailInitiated(
                                invoice: invoice,
                                recipientEmail: draft.recipientEmail,
                                subject: draft.subject,
                                in: modelContext
                            )
                        },
                        onMailResult: { draft, result, error in
                            handleMailResult(result, error: error, draft: draft)
                        }
                    )
                }
            }
            .sheet(isPresented: $isPresentingSignatureCapture) {
                NavigationStack {
                    SignatureCaptureView(title: localization.phrase("Invoice Signature"), existingSignature: invoice.customerSignature) { draft in
                        try signatureService.upsertSignature(draft, for: invoice, in: modelContext)
                    }
                }
            }
            .confirmationDialog(localization.phrase("Payment Details"), isPresented: $isPresentingPaymentActions, titleVisibility: .visible) {
                Button(localization.phrase("Mark as Sent")) {
                    markAsSent()
                }
                Button(localization.phrase("Mark as Paid")) {
                    markAsPaid()
                }
                if invoice.paidDate != nil {
                    Button(localization.phrase("Mark as Unpaid")) {
                        clearPaidDate()
                    }
                }
                Button(localization.phrase("Cancel"), role: .cancel) { }
            }
            .fileImporter(isPresented: $isImportingAttachment, allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
                switch result {
                case .success(let urls):
                    importAttachments(urls)
                case .failure(let error):
                    attachmentImportError = error.localizedDescription
                }
            }
            .alert(localization.text(.attachmentImportFailed), isPresented: attachmentErrorBinding) {
                Button(localization.phrase("OK"), role: .cancel) { }
            } message: {
                Text(attachmentImportError ?? "")
            }
            .alert(localization.text(.unableToSaveReminder), isPresented: reminderErrorBinding) {
                Button(localization.phrase("OK"), role: .cancel) { }
            } message: {
                Text(reminderErrorMessage ?? "")
            }
            .alert(localization.text(.emailReady), isPresented: emailStatusBinding) {
                Button(localization.phrase("OK"), role: .cancel) { }
            } message: {
                Text(emailStatusMessage ?? "")
            }
            .alert(localization.text(.emailFailed), isPresented: emailErrorBinding) {
                Button(localization.phrase("OK"), role: .cancel) { }
            } message: {
                Text(emailErrorMessage ?? "")
            }
            .alert(deleteTitle, isPresented: $isPresentingDeleteConfirmation) {
                Button(localization.phrase("Delete"), role: .destructive) {
                    deleteInvoice()
                }
                Button(localization.phrase("Cancel"), role: .cancel) { }
            } message: {
                Text(deleteMessage)
            }
            .alert(deleteErrorTitle, isPresented: deleteErrorBinding) {
                Button(localization.phrase("OK"), role: .cancel) { }
            } message: {
                Text(deleteErrorMessage ?? "")
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
        }
    }

    private func currency(_ value: Double) -> String {
        value.formatted(.currency(code: Locale.current.currency?.identifier ?? "EUR"))
    }

    private var reminderHistory: [InvoiceReminder] {
        invoice.reminders.sorted { lhs, rhs in
            if lhs.createdAt != rhs.createdAt {
                return lhs.createdAt > rhs.createdAt
            }
            return lhs.id.uuidString > rhs.id.uuidString
        }
    }

    private var creditedSourceInvoice: Invoice? {
        guard let creditedInvoiceID = invoice.creditedInvoiceID else { return nil }
        return invoices.first { $0.id == creditedInvoiceID }
    }

    private func totalsSection(
        totals: InvoiceDraftTotals,
        collaborationBreakdown: CollaborationRevenueBreakdown
    ) -> some View {
        Section(localization.text(.totals)) {
            detailRow(localization.text(.subtotal), currency(totals.subtotal))
            detailRow(localization.text(.extraCharges), currency(totals.extraCharges))
            detailRow(localization.text(.travelCosts), currency(totals.travelCosts))
            detailRow(localization.text(.materialCosts), currency(totals.materialCosts))
            detailRow(localization.text(.manualAdjustments), currency(totals.manualAdjustments))
            detailRow(localization.text(.gross), currency(totals.gross))
            detailRow(localization.text(.discounts), currency(-totals.discounts))
            detailRow(localization.text(.netSubtotal), currency(totals.netSubtotal))
            detailRow(localization.text(.vat), currency(totals.vat))
            detailRow(localization.text(.total), currency(totals.total))

            if collaborationBreakdown.partnerName != nil {
                collaborationTotalsRows(collaborationBreakdown)
            }
        }
    }

    @ViewBuilder
    private func collaborationTotalsRows(_ collaborationBreakdown: CollaborationRevenueBreakdown) -> some View {
        if let partnerName = collaborationBreakdown.partnerName {
            detailRow(localization.text(.grossAmount), currency(collaborationBreakdown.grossAmount))
            detailRow("\(localization.phrase("Partner share")) (\(partnerName))", currency(collaborationBreakdown.partnerShare))
            detailRow(localization.text(.youKeep), currency(collaborationBreakdown.userNetAmount))
        }
    }

    private func overviewSection(normalizedStatus: InvoiceStatus) -> some View {
        Section(localization.phrase("Overview")) {
            detailRow(localization.phrase("Documenttype"), localization.phrase(invoice.documentType.displayName))
            detailRow(localization.phrase("Invoice number"), invoice.invoiceNumber)
            detailRow(localization.phrase("Client"), invoice.client.name)
            detailRow(localization.phrase("Quote reference"), invoice.sourceQuote?.quoteNumber ?? localization.phrase("None"))
            if invoice.isCreditInvoice {
                if let creditedSourceInvoice {
                    NavigationLink {
                        InvoicePreviewView(invoice: creditedSourceInvoice, collaborationRule: collaborationRule)
                    } label: {
                        HStack {
                            Text(localization.phrase("Credit op factuur"))
                                .foregroundStyle(AppTheme.secondaryText)
                            Spacer()
                            Text(creditedSourceInvoice.invoiceNumber)
                                .foregroundStyle(AppTheme.primaryText)
                        }
                    }
                } else {
                    detailRow(localization.phrase("Credit op factuur"), invoice.creditedInvoiceNumber.isEmpty ? localization.phrase("None") : invoice.creditedInvoiceNumber)
                }
            }
            detailRow(localization.phrase("Invoice date"), invoice.date.formatted(date: .abbreviated, time: .omitted))
            detailRow(localization.phrase("Due date"), invoice.dueDate.formatted(date: .abbreviated, time: .omitted))
            detailRow(localization.phrase("Company"), resolvedCompanyProfile?.name ?? localization.phrase("No company profile"))
            detailRow(localization.phrase("Status"), localization.phrase(normalizedStatus.displayName))
            detailRow(localization.phrase("Paid date"), invoice.paidDate?.formatted(date: .abbreviated, time: .omitted) ?? localization.phrase("Not paid"))
            detailRow(localization.phrase("Email status"), localization.phrase(invoice.emailDeliveryStatus.displayName))
            detailRow(localization.phrase("Email sent"), invoice.emailSentAt?.formatted(date: .abbreviated, time: .shortened) ?? localization.phrase("Not sent"))
        }
        .listRowBackground(AppTheme.cardBackground)
    }

    @ViewBuilder
    private var notesSection: some View {
        let invoiceNotes = invoice.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let defaultInvoiceText = resolvedCompanyProfile?.defaultInvoiceText.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if !invoiceNotes.isEmpty || !defaultInvoiceText.isEmpty {
            Section(localization.phrase("Notes")) {
                if !invoiceNotes.isEmpty {
                    Text(invoiceNotes)
                        .foregroundStyle(AppTheme.primaryText)
                }

                if !defaultInvoiceText.isEmpty {
                    if !invoiceNotes.isEmpty {
                        Divider()
                    }

                    Text(defaultInvoiceText)
                        .foregroundStyle(AppTheme.primaryText)
                }
            }
            .listRowBackground(AppTheme.cardBackground)
        }
    }

    private func statusSection(normalizedStatus: InvoiceStatus) -> some View {
        Section(localization.phrase("Status")) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    FilterChip(title: localization.phrase("Draft"), isSelected: normalizedStatus == .draft) {
                        updateInvoiceStatus(.draft)
                    }
                    FilterChip(title: localization.phrase("Sent"), isSelected: normalizedStatus == .sent) {
                        markAsSent()
                    }
                    FilterChip(title: localization.phrase("Paid"), isSelected: normalizedStatus == .paid) {
                        markAsPaid()
                    }
                    FilterChip(title: localization.phrase("Overdue"), isSelected: normalizedStatus == .overdue) { }
                }
            }

            Button(localization.phrase("Payment Actions")) {
                isPresentingPaymentActions = true
            }
        }
        .listRowBackground(AppTheme.cardBackground)
    }

    private var paymentRemindersSection: some View {
        Section(localization.phrase("Payment reminders")) {
            if repository.normalizedStatus(for: invoice) != .paid {
                Button(localization.phrase("Preview Next Reminder")) {
                    reminderDraft = reminderService.makeDraft(
                        for: invoice,
                        localeIdentifier: appSettings.first?.preferredLocaleIdentifier
                    )
                }

                Menu(localization.phrase("Create Reminder Manually")) {
                    ForEach(InvoiceReminderLevel.allCases) { level in
                        Button(localization.phrase(level.displayName)) {
                            reminderDraft = reminderService.makeDraft(
                                for: invoice,
                                level: level,
                                localeIdentifier: appSettings.first?.preferredLocaleIdentifier
                            )
                        }
                    }
                }
            }

            if reminderHistory.isEmpty {
                Text(localization.phrase("No reminders created yet."))
                    .foregroundStyle(AppTheme.secondaryText)
            } else {
                ForEach(reminderHistory) { reminder in
                    reminderRow(reminder)
                }
            }
        }
        .listRowBackground(AppTheme.cardBackground)
    }

    private var linesSection: some View {
        Section(localization.phrase("Lines")) {
            ForEach(invoice.lines) { line in
                VStack(alignment: .leading, spacing: 4) {
                    Text(line.description)
                        .font(AppTheme.bodyFont.weight(.semibold))
                    Text("\(line.quantity.formatted(.number.precision(.fractionLength(0...2)))) × \(line.unitPrice.formatted(.currency(code: Locale.current.currency?.identifier ?? "EUR")))")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
        .listRowBackground(AppTheme.cardBackground)
    }

    private var signatureSection: some View {
        Section {
            SignaturePreviewCard(
                signature: invoice.customerSignature,
                addActionTitle: localization.phrase("Capture Signature"),
                onAddOrEdit: {
                    isPresentingSignatureCapture = true
                },
                onDelete: invoice.customerSignature == nil ? nil : {
                    try? signatureService.deleteSignature(for: invoice, in: modelContext)
                }
            )
        }
        .listRowBackground(AppTheme.cardBackground)
    }

    private var exportSection: some View {
        Section(localization.text(.exportAndShare)) {
            Picker(localization.phrase("Document version"), selection: invoiceTemplateSelectionBinding) {
                ForEach(DocumentTemplateStyle.allCases) { style in
                    Text(localization.phrase(style.title)).tag(style)
                }
            }
            .pickerStyle(.menu)

            Text(localization.phrase(invoiceExportTemplateStyle.subtitle))
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.secondaryText)

            Button(localization.text(.sendByEmail)) {
                prepareInvoiceEmail()
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(localization.phrase("PDF"))
                    .font(AppTheme.captionFont.weight(.semibold))
                    .foregroundStyle(AppTheme.secondaryText)

                Button(localization.text(.exportPDF)) {
                    exportPDF(shouldShare: true)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(localization.phrase("DOCX"))
                    .font(AppTheme.captionFont.weight(.semibold))
                    .foregroundStyle(AppTheme.secondaryText)

                Button(localization.text(.exportDOCX)) {
                    exportDOCX(shouldShare: true)
                }
            }
        }
        .listRowBackground(AppTheme.cardBackground)
    }

    private var attachmentsSection: some View {
        Section(localization.text(.attachments)) {
            Button(localization.text(.addAttachment)) {
                isImportingAttachment = true
            }

            if invoice.attachments.isEmpty {
                Text(localization.text(.noAttachments))
                    .foregroundStyle(AppTheme.secondaryText)
            } else {
                AttachmentPreviewList(
                    attachments: invoice.attachments.sorted { $0.createdAt > $1.createdAt },
                    onShare: { attachment in
                        sharedFile = ExportedInvoiceFile(
                            url: URL(fileURLWithPath: attachment.localPath),
                            createdAt: attachment.createdAt,
                            fileSize: attachment.fileSize
                        )
                    },
                    onDelete: { attachment in
                        deleteAttachment(attachment)
                    }
                )
            }
        }
        .listRowBackground(AppTheme.cardBackground)
    }

    private var linkedMileageSection: some View {
        Section(localization.text(.linkedMileage)) {
            if sortedMileageEntries.isEmpty {
                Text(localization.text(.noMileageLinked))
                    .foregroundStyle(AppTheme.secondaryText)
            } else {
                ForEach(sortedMileageEntries) { entry in
                    mileageEntryRow(entry)
                }
            }
        }
    }

    private func exportPDF(shouldShare: Bool) {
        do {
            let exportedFile = try InvoicePDFExportService(
                localeIdentifier: exportLocaleIdentifier,
                templateStyle: invoiceExportTemplateStyle
            ).export(
                invoice: exportSourceInvoice,
                companyProfile: resolvedCompanyProfile,
                collaborationRule: collaborationRule
            )

            if shouldShare {
                presentShareSheet(for: exportedFile)
            } else {
                showExportSuccess(for: exportedFile)
            }
        } catch {
            exportErrorMessage = error.localizedDescription
        }
    }

    private func exportDOCX(shouldShare: Bool) {
        do {
            let exportedFile = try InvoiceDOCXExportService(
                localeIdentifier: exportLocaleIdentifier,
                templateStyle: invoiceExportTemplateStyle
            ).export(
                invoice: exportSourceInvoice,
                companyProfile: resolvedCompanyProfile,
                collaborationRule: collaborationRule
            )

            if shouldShare {
                presentShareSheet(for: exportedFile)
            } else {
                showExportSuccess(for: exportedFile)
            }
        } catch {
            exportErrorMessage = error.localizedDescription
        }
    }

    private func prepareInvoiceEmail() {
        do {
            preparedEmail = try emailPreparationService.prepareEmail(
                for: exportSourceInvoice,
                companyProfile: resolvedCompanyProfile,
                collaborationRule: collaborationRule,
                appSettings: appSettings.first,
                localeIdentifier: exportLocaleIdentifier,
                templateStyle: invoiceExportTemplateStyle
            )
            if !MFMailComposeViewController.canSendMail() {
                emailStatusMessage = localization.mailNotConfigured()
            }
        } catch {
            emailErrorMessage = error.localizedDescription
        }
    }

    private func mileageEntryRow(_ entry: MileageEntry) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.purpose)
                    .font(AppTheme.bodyFont.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
                Spacer()
                Text(currency(entry.totalTravelCost))
                    .font(AppTheme.bodyFont.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
            }

            Text(localization.mileageRoute(from: entry.startLocation, to: entry.endLocation))
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.secondaryText)

            Text(localization.mileageMeta(kilometers: entry.numberOfKilometers.formatted(.number.precision(.fractionLength(0...2))), date: entry.date.formatted(date: .abbreviated, time: .omitted)))
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.secondaryText)
        }
    }

    private func reminderRow(_ reminder: InvoiceReminder) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                reminderLevelBadge(for: reminder.level)
                reminderStatusBadge(for: reminder.status)
                Spacer()
                Text(reminder.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Text(reminder.subject)
                .font(AppTheme.bodyFont.weight(.semibold))
                .foregroundStyle(AppTheme.primaryText)

            Text(reminder.messageBody)
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.secondaryText)

            if let sentAt = reminder.sentAt {
                    Text("\(localization.text(.sent)) \(sentAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(.green)
            } else {
                Text(localization.text(.savedAsDraft))
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .padding(.vertical, 6)
    }

    private var exportErrorAlertBinding: Binding<Bool> {
        Binding(
            get: { exportErrorMessage != nil },
            set: { if !$0 { exportErrorMessage = nil } }
        )
    }

    private func presentShareSheet(for exportedFile: ExportedInvoiceFile) {
        sharedFile = exportedFile
    }

    private func showExportSuccess(for exportedFile: ExportedInvoiceFile) {
        exportMessage = localization.savedFile(exportedFile.fileName)
        isPresentingExportAlert = true
    }

    private func updateInvoiceStatus(_ status: InvoiceStatus) {
        repository.persistStatus(status, on: invoice)
        if status == .paid && invoice.paidDate == nil {
            invoice.paidDate = .now
        }
        try? modelContext.save()
    }

    private func markAsSent() {
        repository.markAsSent(invoice)
        try? modelContext.save()
    }

    private func markAsPaid() {
        repository.markAsPaid(invoice)
        try? modelContext.save()
    }

    private func clearPaidDate() {
        invoice.paidDate = nil
        repository.markAsSent(invoice)
        try? modelContext.save()
    }

    private func handleMailResult(
        _ result: MFMailComposeResult,
        error: Error?,
        draft: InvoiceEmailDraft
    ) {
        defer {
            preparedEmail = nil
        }

        if let error {
            try? emailPreparationService.markEmailFailed(
                invoice: invoice,
                recipientEmail: draft.recipientEmail,
                subject: draft.subject,
                in: modelContext
            )
            emailErrorMessage = error.localizedDescription
            return
        }

        switch result {
        case .sent:
            try? emailPreparationService.markEmailSent(
                invoice: invoice,
                recipientEmail: draft.recipientEmail,
                subject: draft.subject,
                in: modelContext
            )
            emailStatusMessage = localization.text(.emailSent)
        case .saved, .cancelled:
            emailStatusMessage = localization.text(.emailPreparationSaved)
        case .failed:
            try? emailPreparationService.markEmailFailed(
                invoice: invoice,
                recipientEmail: draft.recipientEmail,
                subject: draft.subject,
                in: modelContext
            )
            emailErrorMessage = localization.text(.emailCouldNotBeSent)
        @unknown default:
            emailErrorMessage = localization.text(.unknownMailResult)
        }
    }

    private var resolvedCompanyProfile: CompanyProfile? {
        CompanyProfileSelectionService().resolveInvoiceProfile(
            explicitProfile: exportSourceInvoice.companyProfile,
            client: exportSourceInvoice.client,
            registrations: exportSourceInvoice.lines.compactMap(\.linkedWorkEntry),
            fallbackActiveProfile: CompanyProfileSelectionService().activeProfile(from: companyProfiles, settings: appSettings.first)
        )
    }

    private var localization: AppLocalization {
        AppLocalization(localeIdentifier: appSettings.first?.preferredLocaleIdentifier)
    }

    private var exportLocaleIdentifier: String {
        appSettings.first?.preferredLocaleIdentifier ?? Locale.current.identifier
    }

    private var invoiceExportTemplateStyle: DocumentTemplateStyle {
        selectedInvoiceTemplateStyle ?? invoiceTemplateStyle
    }

    private var invoiceTemplateStyle: DocumentTemplateStyle {
        appSettings.first?.invoiceTemplateStyle ?? .premium
    }

    private var invoiceTemplateSelectionBinding: Binding<DocumentTemplateStyle> {
        Binding(
            get: { invoiceExportTemplateStyle },
            set: { selectedInvoiceTemplateStyle = $0 }
        )
    }

    private var signaturesEnabled: Bool {
        workModeService.isModuleEnabled(
            .customerSignatures,
            settings: appSettings.first,
            moduleConfiguration: moduleConfigurations.first
        )
    }

    private var sortedMileageEntries: [MileageEntry] {
        exportSourceInvoice.mileageEntries.sorted { $0.date > $1.date }
    }

    private func importAttachments(_ urls: [URL]) {
        do {
            for url in urls {
                let stored = try attachmentStorageService.storeImportedFile(from: url)
                let attachment = Attachment(
                    fileName: stored.fileName,
                    localPath: stored.localPath,
                    contentType: stored.contentType,
                    fileSize: stored.fileSize,
                    invoice: invoice
                )
                modelContext.insert(attachment)
            }
            try modelContext.save()
        } catch {
            attachmentImportError = error.localizedDescription
        }
    }

    private func deleteAttachment(_ attachment: Attachment) {
        attachmentStorageService.deleteStoredFile(at: attachment.localPath)
        modelContext.delete(attachment)
        try? modelContext.save()
    }

    private func saveReminder(_ draft: PaymentReminderDraft, markAsSent: Bool) throws {
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
            reminderErrorMessage = error.localizedDescription
            throw error
        }
    }

    private func reminderLevelBadge(for level: InvoiceReminderLevel) -> some View {
        ReminderBadge(
            title: level.displayName,
            systemImage: level == .friendly ? "hand.wave" : level == .second ? "bell.badge" : "exclamationmark.bubble",
            tint: level == .friendly ? .blue : level == .second ? .orange : .red
        )
    }

    private func reminderStatusBadge(for status: InvoiceReminderStatus) -> some View {
        ReminderBadge(
            title: status.displayName,
            systemImage: status == .draft ? "square.and.pencil" : "paperplane",
            tint: status == .draft ? .gray : .green
        )
    }

    private var attachmentErrorBinding: Binding<Bool> {
        Binding(
            get: { attachmentImportError != nil },
            set: { if !$0 { attachmentImportError = nil } }
        )
    }

    private var reminderErrorBinding: Binding<Bool> {
        Binding(
            get: { reminderErrorMessage != nil },
            set: { if !$0 { reminderErrorMessage = nil } }
        )
    }

    private var emailStatusBinding: Binding<Bool> {
        Binding(
            get: { emailStatusMessage != nil },
            set: { if !$0 { emailStatusMessage = nil } }
        )
    }

    private var emailErrorBinding: Binding<Bool> {
        Binding(
            get: { emailErrorMessage != nil },
            set: { if !$0 { emailErrorMessage = nil } }
        )
    }

    private var deleteTitle: String {
        invoice.isCreditInvoice
            ? localization.phrase("Delete Credit Invoice")
            : localization.phrase("Delete Invoice")
    }

    private var deleteMessage: String {
        invoice.isCreditInvoice
            ? localization.phrase("This credit invoice will be removed permanently.")
            : localization.phrase("This invoice will be removed permanently. Linked reminders, attachments, and signature data will also be deleted.")
    }

    private var deleteErrorTitle: String {
        invoice.isCreditInvoice
            ? localization.phrase("Unable to Delete Credit Invoice")
            : localization.phrase("Unable to Delete Invoice")
    }

    private var deleteErrorBinding: Binding<Bool> {
        Binding(
            get: { deleteErrorMessage != nil },
            set: { if !$0 { deleteErrorMessage = nil } }
        )
    }

    private func deleteInvoice() {
        do {
            try repository.delete(invoice, from: invoices, in: modelContext)
            dismiss()
        } catch {
            deleteErrorMessage = error.localizedDescription
        }
    }
}
