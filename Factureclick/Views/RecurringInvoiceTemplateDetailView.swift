//
//  RecurringInvoiceTemplateDetailView.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import SwiftData
import SwiftUI

struct RecurringInvoiceTemplateDetailView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Invoice.date, order: .reverse) private var invoices: [Invoice]
    @Query private var appSettings: [AppSettings]
    @Query(sort: \CompanyProfile.createdAt, order: .reverse) private var companyProfiles: [CompanyProfile]

    let template: RecurringInvoiceTemplate

    @State private var editTemplate: RecurringInvoiceTemplate?
    @State private var resultMessage: String?

    private let recurringService = RecurringInvoiceService()

    var body: some View {
        List {
            Section(localization.phrase("Overview")) {
                detailRow(localization.phrase("Template"), template.title)
                detailRow(localization.phrase("Client"), template.client.name)
                detailRow(localization.phrase("Frequency"), localization.phrase(template.frequency.displayName))
                detailRow(localization.phrase("Start date"), template.startDate.formatted(date: .abbreviated, time: .omitted))
                detailRow(localization.phrase("End date"), template.endDate?.formatted(date: .abbreviated, time: .omitted) ?? localization.phrase("No end date"))
                detailRow(localization.phrase("Payment term"), "\(template.paymentTermDays) \(localization.phrase("days"))")
                detailRow(localization.phrase("Status"), template.isActive ? localization.phrase("Active") : localization.phrase("Paused"))
                detailRow(localization.phrase("Next planned invoice"), recurringService.nextPlannedInvoiceDate(for: template)?.formatted(date: .abbreviated, time: .omitted) ?? localization.phrase("No upcoming cycle"))
            }
            .listRowBackground(AppTheme.cardBackground)

            Section(localization.phrase("Lines")) {
                ForEach(template.lines.sorted { $0.sortOrder < $1.sortOrder }) { line in
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

            Section(localization.phrase("Generations")) {
                if template.generations.isEmpty {
                    Text(localization.phrase("No draft invoices generated yet."))
                        .foregroundStyle(AppTheme.secondaryText)
                } else {
                    ForEach(template.generations.sorted { $0.cycleDate > $1.cycleDate }) { generation in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(generation.generatedInvoiceNumber)
                                .font(AppTheme.bodyFont.weight(.semibold))
                            Text("\(localization.phrase("Cycle")) \(generation.cycleDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(AppTheme.captionFont)
                                .foregroundStyle(AppTheme.secondaryText)
                            Text("\(localization.phrase("Generated")) \(generation.generatedAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(AppTheme.captionFont)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                }
            }
            .listRowBackground(AppTheme.cardBackground)

            if !template.notes.isEmpty {
                Section(localization.phrase("Notes")) {
                    Text(template.notes)
                }
                .listRowBackground(AppTheme.cardBackground)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.screenBackground.ignoresSafeArea())
        .navigationTitle(template.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(localization.phrase("Generate Now")) {
                    generateDueDrafts()
                }

                Button(localization.phrase("Edit")) {
                    editTemplate = template
                }
            }
        }
        .sheet(item: $editTemplate) { template in
            NavigationStack {
                RecurringInvoiceTemplateFormView(template: template)
            }
        }
        .alert(localization.phrase("Recurring invoices"), isPresented: resultBinding) {
            Button(localization.phrase("OK"), role: .cancel) { }
        } message: {
            Text(resultMessage ?? "")
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

    private func generateDueDrafts() {
        do {
            let result = try recurringService.generateDraftInvoices(
                from: [template],
                existingInvoices: invoices,
                invoiceNumberPrefix: appSettings.first?.invoiceNumberPrefix ?? "",
                invoiceNumberSequencePadding: appSettings.first?.invoiceNumberSequencePadding ?? 3,
                activeCompanyProfile: CompanyProfileSelectionService().activeProfile(from: companyProfiles, settings: appSettings.first),
                in: modelContext
            )
            resultMessage = result.createdInvoices.isEmpty
                ? localization.phrase("No invoice cycles were due for this template.")
                : "Created \(result.createdInvoices.count) draft invoice\(result.createdInvoices.count == 1 ? "" : "s")."
        } catch {
            resultMessage = error.localizedDescription
        }
    }

    private var resultBinding: Binding<Bool> {
        Binding(get: { resultMessage != nil }, set: { if !$0 { resultMessage = nil } })
    }

    private var localization: AppLocalization {
        AppLocalization(localeIdentifier: appSettings.first?.preferredLocaleIdentifier)
    }
}
