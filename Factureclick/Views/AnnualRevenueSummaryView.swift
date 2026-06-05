//
//  AnnualRevenueSummaryView.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import SwiftData
import SwiftUI

struct AnnualRevenueSummaryView: View {
    @Query(sort: \Invoice.date, order: .reverse) private var invoices: [Invoice]
    @Query(sort: \WorkEntry.date, order: .reverse) private var workEntries: [WorkEntry]
    @Query private var appSettings: [AppSettings]

    @State private var viewModel = AnnualRevenueSummaryViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                selectorCard
                summaryCard
                topClientsCard
                monthlyBreakdownCard
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(AppTheme.screenBackground.ignoresSafeArea())
        .navigationTitle(localization.phrase("Annual Summary"))
        .navigationBarTitleDisplayMode(.inline)
        .task(id: refreshToken) {
            viewModel.refresh(invoices: invoices, workEntries: workEntries)
        }
        .onChange(of: viewModel.selectedYear) { _, _ in
            viewModel.refresh(invoices: invoices, workEntries: workEntries)
        }
    }

    private var selectorCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(localization.phrase("Year selection"))
                    .font(AppTheme.titleFont)
                    .foregroundStyle(AppTheme.primaryText)

                Picker(localization.phrase("Year"), selection: selectedYearBinding) {
                    ForEach(viewModel.availableYears, id: \.self) { year in
                        Text(plainYear(year)).tag(year)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }

    private var summaryCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("\(plainYear(viewModel.snapshot.year)) \(localization.phrase("performance"))")
                    .font(AppTheme.sectionTitleFont)
                    .foregroundStyle(AppTheme.primaryText)

                LazyVGrid(columns: gridColumns, spacing: 16) {
                    metric(title: localization.phrase("Revenue"), value: currency(viewModel.snapshot.totalRevenue), subtitle: localization.phrase("Invoice total for the year"), systemImage: "chart.line.uptrend.xyaxis")
                    metric(title: localization.phrase("Credited"), value: currency(viewModel.snapshot.totalCreditedAmount), subtitle: localization.phrase("Credit invoices issued"), systemImage: "arrow.uturn.backward.circle")
                    metric(title: localization.phrase("VAT Charged"), value: currency(viewModel.snapshot.totalVATCharged), subtitle: localization.phrase("VAT across issued invoices"), systemImage: "percent")
                    metric(title: localization.phrase("Paid"), value: currency(viewModel.snapshot.totalPaidInvoices), subtitle: localization.phrase("Paid invoice total"), systemImage: "checkmark.circle")
                    metric(title: localization.phrase("Unpaid"), value: currency(viewModel.snapshot.totalUnpaidInvoices), subtitle: localization.phrase("Open invoice total"), systemImage: "clock")
                    metric(title: localization.phrase("Hours"), value: decimal(viewModel.snapshot.totalHoursWorked), subtitle: localization.phrase("Tracked work hours"), systemImage: "clock.badge.checkmark")
                    metric(title: localization.phrase("Delivered"), value: decimal(viewModel.snapshot.totalProductsServicesDelivered), subtitle: localization.phrase("Products and services quantity"), systemImage: "shippingbox")
                }
            }
        }
    }

    private var topClientsCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(localization.phrase("Top clients by revenue"))
                    .font(AppTheme.sectionTitleFont)
                    .foregroundStyle(AppTheme.primaryText)

                if viewModel.snapshot.topClients.isEmpty {
                    Text(localization.phrase("No client revenue has been recorded for this year."))
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                } else {
                    ForEach(Array(viewModel.snapshot.topClients.enumerated()), id: \.element.id) { index, item in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.client.name)
                                    .font(AppTheme.bodyFont.weight(.semibold))
                                    .foregroundStyle(AppTheme.primaryText)
                                Text("\(item.invoiceCount) \(localization.phrase("invoices"))")
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }

                            Spacer()

                            Text(currency(item.revenue))
                                .font(AppTheme.bodyFont.weight(.semibold))
                                .foregroundStyle(AppTheme.primaryText)
                        }

                        if index < viewModel.snapshot.topClients.count - 1 {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private var monthlyBreakdownCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(localization.phrase("Monthly revenue breakdown"))
                    .font(AppTheme.sectionTitleFont)
                    .foregroundStyle(AppTheme.primaryText)

                Text(localization.phrase("Native chart support can be added later. This list keeps the monthly summary lightweight and export-ready."))
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.secondaryText)

                ForEach(Array(viewModel.snapshot.monthlyBreakdown.enumerated()), id: \.element.id) { index, item in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.monthName)
                                .font(AppTheme.bodyFont.weight(.semibold))
                                .foregroundStyle(AppTheme.primaryText)
                            Text("\(item.invoiceCount) \(localization.phrase("invoices"))")
                                .font(AppTheme.captionFont)
                                .foregroundStyle(AppTheme.secondaryText)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text(currency(item.revenue))
                                .font(AppTheme.bodyFont.weight(.semibold))
                                .foregroundStyle(AppTheme.primaryText)
                            Text("\(localization.text(.vat)) \(currency(item.vatCharged))")
                                .font(AppTheme.captionFont)
                                .foregroundStyle(AppTheme.secondaryText)
                            if item.creditedAmount > 0 {
                                Text("\(localization.phrase("Credited")) \(currency(item.creditedAmount))")
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                        }
                    }

                    if index < viewModel.snapshot.monthlyBreakdown.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }

    private func metric(title: String, value: String, subtitle: String, systemImage: String) -> some View {
        DashboardMetricCard(
            title: title,
            value: value,
            subtitle: subtitle,
            systemImage: systemImage
        )
    }

    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ]
    }

    private var selectedYearBinding: Binding<Int> {
        Binding(get: { viewModel.selectedYear }, set: { viewModel.selectedYear = $0 })
    }

    private var refreshToken: String {
        let invoiceToken = invoices.map {
            "\($0.id.uuidString)-\($0.date.timeIntervalSince1970)-\($0.totalAmount)-\($0.vatAmount)-\($0.statusRawValue)"
        }
        .joined(separator: "|")

        let workEntryToken = workEntries.map {
            "\($0.id.uuidString)-\($0.date.timeIntervalSince1970)-\($0.hoursWorked)-\($0.quantity)"
        }
        .joined(separator: "|")

        return "\(invoiceToken)#\(workEntryToken)"
    }

    private func currency(_ value: Double) -> String {
        AppFormatters.currencyFormatter().string(from: NSNumber(value: value)) ?? "EUR 0.00"
    }

    private func decimal(_ value: Double) -> String {
        AppFormatters.decimalFormatter(maximumFractionDigits: 1).string(from: NSNumber(value: value)) ?? "0"
    }

    private func plainYear(_ year: Int) -> String {
        String(year)
    }

    private var localization: AppLocalization {
        AppLocalization(localeIdentifier: appSettings.first?.preferredLocaleIdentifier)
    }
}
