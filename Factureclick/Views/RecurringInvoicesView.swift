//
//  RecurringInvoicesView.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import SwiftData
import SwiftUI

struct RecurringInvoicesView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \RecurringInvoiceTemplate.createdAt, order: .reverse) private var templates: [RecurringInvoiceTemplate]
    @Query(sort: \Invoice.date, order: .reverse) private var invoices: [Invoice]
    @Query private var appSettings: [AppSettings]
    @Query(sort: \CompanyProfile.createdAt, order: .reverse) private var companyProfiles: [CompanyProfile]

    @State private var createTemplate = false
    @State private var resultMessage: String?

    private let recurringService = RecurringInvoiceService()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionCard {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(localization.phrase("Recurring invoices"))
                                    .font(AppTheme.titleFont)
                                    .foregroundStyle(AppTheme.primaryText)
                                Text(localization.phrase("Automate repeated billing with reusable templates and duplicate-safe draft generation."))
                                    .font(AppTheme.bodyFont)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }

                            Spacer()

                            Button(localization.phrase("New Template")) {
                                createTemplate = true
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(AppTheme.accentColor)
                        }

                        HStack {
                            metricView(title: localization.phrase("Templates"), value: "\(templates.count)")
                            metricView(title: localization.phrase("Due now"), value: "\(dueTemplateCount)")
                            metricView(title: localization.phrase("Drafts created"), value: "\(generatedInvoiceCount)")
                        }

                        Button(localization.phrase("Generate Due Drafts")) {
                            generateDueDrafts()
                        }
                        .buttonStyle(.bordered)
                        .disabled(dueTemplateCount == 0)
                    }
                }

                if summaries.isEmpty {
                    SectionCard {
                        Text(localization.phrase("No recurring invoice templates yet."))
                            .font(AppTheme.bodyFont)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                } else {
                    ForEach(summaries) { summary in
                        NavigationLink {
                            RecurringInvoiceTemplateDetailView(template: summary.template)
                        } label: {
                            SectionCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(summary.template.title)
                                                .font(AppTheme.sectionTitleFont)
                                                .foregroundStyle(AppTheme.primaryText)
                                            Text(summary.template.client.name)
                                                .font(AppTheme.bodyFont)
                                                .foregroundStyle(AppTheme.secondaryText)
                                        }

                                        Spacer()

                                        ReminderBadge(
                                            title: localization.phrase(summary.template.frequency.displayName),
                                            systemImage: "arrow.clockwise",
                                            tint: AppTheme.accentColor
                                        )
                                    }

                                    HStack {
                                        ReminderBadge(
                                            title: summary.template.isActive ? localization.phrase("Active") : localization.phrase("Paused"),
                                            systemImage: summary.template.isActive ? "checkmark.circle" : "pause.circle",
                                            tint: summary.template.isActive ? .green : .gray
                                        )
                                        if !summary.dueCycleDates.isEmpty {
                                            ReminderBadge(
                                                title: "\(summary.dueCycleDates.count) \(localization.phrase("due"))",
                                                systemImage: "calendar.badge.exclamationmark",
                                                tint: .orange
                                            )
                                        }
                                    }

                                    Text("\(localization.phrase("Next planned invoice")): \(summary.nextPlannedDate?.formatted(date: .abbreviated, time: .omitted) ?? localization.phrase("No upcoming cycle"))")
                                        .font(AppTheme.bodyFont)
                                        .foregroundStyle(AppTheme.secondaryText)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(AppTheme.screenBackground.ignoresSafeArea())
        .navigationTitle(localization.phrase("Recurring"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $createTemplate) {
            NavigationStack {
                RecurringInvoiceTemplateFormView()
            }
        }
        .alert(localization.phrase("Recurring invoices"), isPresented: resultBinding) {
            Button(localization.phrase("OK"), role: .cancel) { }
        } message: {
            Text(resultMessage ?? "")
        }
    }

    private var summaries: [RecurringInvoiceTemplateSummary] {
        recurringService.summaries(from: templates)
    }

    private var dueTemplateCount: Int {
        summaries.filter { !$0.dueCycleDates.isEmpty }.count
    }

    private var generatedInvoiceCount: Int {
        templates.reduce(0) { $0 + $1.generations.count }
    }

    private func generateDueDrafts() {
        do {
            let result = try recurringService.generateDraftInvoices(
                from: templates,
                existingInvoices: invoices,
                invoiceNumberPrefix: appSettings.first?.invoiceNumberPrefix ?? "",
                invoiceNumberSequencePadding: appSettings.first?.invoiceNumberSequencePadding ?? 3,
                activeCompanyProfile: CompanyProfileSelectionService().activeProfile(from: companyProfiles, settings: appSettings.first),
                in: modelContext
            )
            resultMessage = result.createdInvoices.isEmpty
                ? "No invoice cycles were due."
                : "Created \(result.createdInvoices.count) draft invoice\(result.createdInvoices.count == 1 ? "" : "s")."
        } catch {
            resultMessage = error.localizedDescription
        }
    }

    private func metricView(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(AppTheme.sectionTitleFont)
                .foregroundStyle(AppTheme.primaryText)
            Text(title)
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var resultBinding: Binding<Bool> {
        Binding(get: { resultMessage != nil }, set: { if !$0 { resultMessage = nil } })
    }

    private var localization: AppLocalization {
        AppLocalization(localeIdentifier: appSettings.first?.preferredLocaleIdentifier)
    }
}
