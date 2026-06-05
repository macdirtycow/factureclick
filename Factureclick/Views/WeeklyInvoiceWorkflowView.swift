//
//  WeeklyInvoiceWorkflowView.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import SwiftData
import SwiftUI

struct WeeklyInvoiceWorkflowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var appSettings: [AppSettings]

    let initialReferenceDate: Date
    let clients: [Client]
    let workEntries: [WorkEntry]
    let invoices: [Invoice]
    let collaborationRules: [CollaborationRule]

    @State private var selectedMode: InvoiceGenerationPeriodMode = .weekly
    @State private var selectedReferenceDate: Date
    @State private var customStartDate: Date
    @State private var customEndDate: Date
    @State private var selectedClientID: UUID?
    @State private var groupingMode: InvoiceGroupingMode = .product
    @State private var review: PeriodInvoiceReview?
    @State private var errorMessage: String?

    private let useCase = WeeklyInvoiceGenerationUseCase()
    private let calculationService = InvoiceFinancialCalculationService()

    init(
        initialReferenceDate: Date = .now,
        clients: [Client],
        workEntries: [WorkEntry],
        invoices: [Invoice],
        collaborationRules: [CollaborationRule]
    ) {
        self.initialReferenceDate = initialReferenceDate
        self.clients = clients
        self.workEntries = workEntries
        self.invoices = invoices
        self.collaborationRules = collaborationRules
        _selectedReferenceDate = State(initialValue: initialReferenceDate)
        _customStartDate = State(initialValue: initialReferenceDate)
        _customEndDate = State(initialValue: initialReferenceDate)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    configCard

                    if let review {
                        reviewCard(review: review)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(AppTheme.screenBackground.ignoresSafeArea())
            .navigationTitle("Invoice by period")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if let review, !review.items.isEmpty {
                        Button("Confirm") {
                            confirm(review)
                        }
                    }
                }
            }
            .alert("Invoice Workflow", isPresented: errorBinding) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var configCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Generate invoices by period")
                    .font(AppTheme.titleFont)
                    .foregroundStyle(AppTheme.primaryText)

                Picker("Mode", selection: $selectedMode) {
                    ForEach(InvoiceGenerationPeriodMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                switch selectedMode {
                case .weekly:
                    DatePicker("Week", selection: $selectedReferenceDate, displayedComponents: .date)
                case .monthly:
                    DatePicker("Month", selection: $selectedReferenceDate, displayedComponents: .date)
                case .custom:
                    DatePicker("From", selection: $customStartDate, displayedComponents: .date)
                    DatePicker("To", selection: $customEndDate, displayedComponents: .date)
                }

                Picker("Client", selection: $selectedClientID) {
                    Text("All clients").tag(nil as UUID?)
                    ForEach(clients) { client in
                        Text(client.name).tag(Optional(client.id))
                    }
                }

                Picker("Group lines", selection: $groupingMode) {
                    ForEach(InvoiceGroupingMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Button("Prepare review") {
                    review = useCase.prepareReview(
                        mode: selectedMode,
                        referenceDate: selectedReferenceDate,
                        customStartDate: selectedMode == .custom ? customStartDate : nil,
                        customEndDate: selectedMode == .custom ? customEndDate : nil,
                        clientID: selectedClientID,
                        groupingMode: groupingMode,
                        clients: clients,
                        workEntries: workEntries,
                        existingInvoices: invoices,
                        collaborationRules: collaborationRules,
                        invoiceNumberPrefix: appSettings.first?.invoiceNumberPrefix ?? "",
                        invoiceNumberSequencePadding: appSettings.first?.invoiceNumberSequencePadding ?? 3,
                        defaultVATRate: appSettings.first?.defaultVATRate ?? 21
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accentColor)
            }
        }
    }

    private func reviewCard(review: PeriodInvoiceReview) -> some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Review before confirming")
                    .font(AppTheme.sectionTitleFont)
                    .foregroundStyle(AppTheme.primaryText)

                Text("\(AppFormatters.mediumDateFormatter.string(from: review.periodStart)) - \(AppFormatters.mediumDateFormatter.string(from: review.periodEnd))")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.secondaryText)

                if review.items.isEmpty {
                    Text("No uninvoiced registrations found for that period.")
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                } else {
                    ForEach(review.items) { item in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.client.name)
                                        .font(AppTheme.bodyFont.weight(.semibold))
                                        .foregroundStyle(AppTheme.primaryText)

                                    Text("\(item.registrationCount) registrations")
                                        .font(AppTheme.captionFont)
                                        .foregroundStyle(AppTheme.secondaryText)
                                }

                                Spacer()

                                Text(item.invoiceNumber)
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }

                            ForEach(item.lineDrafts, id: \.id) { line in
                                HStack {
                                    Text(line.description)
                                        .font(AppTheme.captionFont)
                                        .foregroundStyle(AppTheme.secondaryText)
                                    Spacer()
                                    Text(calculationService.calculation(for: line).grossAmount.formatted(.currency(code: Locale.current.currency?.identifier ?? "EUR")))
                                        .font(AppTheme.captionFont)
                                        .foregroundStyle(AppTheme.secondaryText)
                                }
                            }

                            HStack {
                                Spacer()
                                Text(item.totals.total.formatted(.currency(code: Locale.current.currency?.identifier ?? "EUR")))
                                    .font(AppTheme.bodyFont.weight(.semibold))
                                    .foregroundStyle(AppTheme.primaryText)
                            }
                        }

                        if item.id != review.items.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private func confirm(_ review: PeriodInvoiceReview) {
        do {
            try useCase.confirm(
                review: review,
                collaborationRules: collaborationRules,
                context: modelContext
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }
}
