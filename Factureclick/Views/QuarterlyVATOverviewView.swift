//
//  QuarterlyVATOverviewView.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import SwiftData
import SwiftUI

struct QuarterlyVATOverviewView: View {
    @Query(sort: \Invoice.date, order: .reverse) private var invoices: [Invoice]
    @Query(sort: \CollaborationRule.partnerName) private var collaborationRules: [CollaborationRule]
    @Query private var appSettings: [AppSettings]

    @State private var viewModel = QuarterlyVATOverviewViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                selectorCard
                summaryCard
                clientBreakdownCard
                invoicesCard
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(AppTheme.screenBackground.ignoresSafeArea())
        .navigationTitle(localization.phrase("Quarterly VAT"))
        .navigationBarTitleDisplayMode(.inline)
        .task(id: refreshToken) {
            viewModel.refresh(with: invoices)
        }
        .onChange(of: viewModel.selectedYear) { _, _ in
            viewModel.refresh(with: invoices)
        }
        .onChange(of: viewModel.selectedQuarter) { _, _ in
            viewModel.refresh(with: invoices)
        }
    }

    private var selectorCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(localization.phrase("Quarter selection"))
                    .font(AppTheme.titleFont)
                    .foregroundStyle(AppTheme.primaryText)

                Picker(localization.phrase("Year"), selection: selectedYearBinding) {
                    ForEach(viewModel.availableYears, id: \.self) { year in
                        Text(plainYear(year)).tag(year)
                    }
                }
                .pickerStyle(.menu)

                Picker(localization.phrase("Quarter"), selection: selectedQuarterBinding) {
                    ForEach(1...4, id: \.self) { quarter in
                        Text("Q\(quarter)").tag(quarter)
                    }
                }
                .pickerStyle(.segmented)

                Text(periodLabel)
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }

    private var summaryCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(viewModel.overview.quarter.title)
                    .font(AppTheme.sectionTitleFont)
                    .foregroundStyle(AppTheme.primaryText)

                LazyVGrid(columns: gridColumns, spacing: 16) {
                    DashboardMetricCard(
                        title: localization.phrase("Revenue Ex VAT"),
                        value: currency(viewModel.overview.totalRevenueExcludingVAT),
                        subtitle: localization.phrase("Taxable revenue in quarter"),
                        systemImage: "chart.bar"
                    )
                    DashboardMetricCard(
                        title: localization.phrase("VAT Charged"),
                        value: currency(viewModel.overview.totalVATCharged),
                        subtitle: localization.phrase("Output VAT on invoices"),
                        systemImage: "percent"
                    )
                    DashboardMetricCard(
                        title: localization.phrase("Invoices"),
                        value: "\(viewModel.overview.totalInvoicesInPeriod)",
                        subtitle: localization.phrase("Dated in selected quarter"),
                        systemImage: "doc.text"
                    )
                    DashboardMetricCard(
                        title: localization.phrase("Paid"),
                        value: currency(viewModel.overview.paidTotalIncludingVAT),
                        subtitle: localization.phrase("Gross paid invoice total"),
                        systemImage: "checkmark.circle"
                    )
                    DashboardMetricCard(
                        title: localization.phrase("Unpaid"),
                        value: currency(viewModel.overview.unpaidTotalIncludingVAT),
                        subtitle: localization.phrase("Gross open invoice total"),
                        systemImage: "clock"
                    )
                }
            }
        }
    }

    private var clientBreakdownCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(localization.phrase("By client"))
                    .font(AppTheme.sectionTitleFont)
                    .foregroundStyle(AppTheme.primaryText)

                if viewModel.overview.clientBreakdown.isEmpty {
                    Text(localization.phrase("No invoices were issued in the selected quarter."))
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                } else {
                    ForEach(Array(viewModel.overview.clientBreakdown.enumerated()), id: \.element.id) { index, item in
                        VStack(alignment: .leading, spacing: 10) {
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

                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(currency(item.totalIncludingVAT))
                                        .font(AppTheme.bodyFont.weight(.semibold))
                                        .foregroundStyle(AppTheme.primaryText)
                                    Text("\(localization.text(.vat)) \(currency(item.vatCharged))")
                                        .font(AppTheme.captionFont)
                                        .foregroundStyle(AppTheme.secondaryText)
                                }
                            }

                            HStack {
                                breakdownPill(title: localization.phrase("Ex VAT"), value: currency(item.netRevenueExcludingVAT))
                                breakdownPill(title: localization.phrase("Paid"), value: currency(item.paidTotalIncludingVAT))
                                breakdownPill(title: localization.phrase("Unpaid"), value: currency(item.unpaidTotalIncludingVAT))
                            }
                        }

                        if index < viewModel.overview.clientBreakdown.count - 1 {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private var invoicesCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(localization.phrase("Included invoices"))
                    .font(AppTheme.sectionTitleFont)
                    .foregroundStyle(AppTheme.primaryText)

                if viewModel.overview.invoiceBreakdown.isEmpty {
                    Text(localization.phrase("No invoice data available for this period."))
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                } else {
                    ForEach(Array(viewModel.overview.invoiceBreakdown.enumerated()), id: \.element.id) { index, item in
                        NavigationLink {
                            InvoicePreviewView(
                                invoice: item.invoice,
                                collaborationRule: collaborationRules.first(where: { $0.client?.id == item.invoice.client.id })
                            )
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.invoice.invoiceNumber)
                                        .font(AppTheme.bodyFont.weight(.semibold))
                                        .foregroundStyle(AppTheme.primaryText)
                                    Text(item.invoice.client.name)
                                        .font(AppTheme.captionFont)
                                        .foregroundStyle(AppTheme.secondaryText)
                                    Text(item.invoice.date.formatted(date: .abbreviated, time: .omitted))
                                        .font(AppTheme.captionFont)
                                        .foregroundStyle(AppTheme.secondaryText)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(currency(item.totalIncludingVAT))
                                        .font(AppTheme.bodyFont.weight(.semibold))
                                        .foregroundStyle(AppTheme.primaryText)
                                    Text("\(localization.phrase("Ex VAT")) \(currency(item.netRevenueExcludingVAT))")
                                        .font(AppTheme.captionFont)
                                        .foregroundStyle(AppTheme.secondaryText)
                                    Text(item.isPaid ? localization.phrase("Paid") : localization.phrase("Unpaid"))
                                        .font(AppTheme.captionFont.weight(.semibold))
                                        .foregroundStyle(item.isPaid ? .green : .orange)
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        if index < viewModel.overview.invoiceBreakdown.count - 1 {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private func breakdownPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.secondaryText)
            Text(value)
                .font(AppTheme.bodyFont.weight(.semibold))
                .foregroundStyle(AppTheme.primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppTheme.elevatedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var selectedYearBinding: Binding<Int> { Binding(get: { viewModel.selectedYear }, set: { viewModel.selectedYear = $0 }) }
    private var selectedQuarterBinding: Binding<Int> { Binding(get: { viewModel.selectedQuarter }, set: { viewModel.selectedQuarter = $0 }) }

    private func plainYear(_ year: Int) -> String {
        String(year)
    }

    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ]
    }

    private var periodLabel: String {
        let lowerBound = viewModel.overview.dateRange.lowerBound.formatted(date: .abbreviated, time: .omitted)
        let upperBound = viewModel.overview.dateRange.upperBound.formatted(date: .abbreviated, time: .omitted)
        return "\(lowerBound) to \(upperBound)"
    }

    private var refreshToken: String {
        invoices.map {
            "\($0.id.uuidString)-\($0.date.timeIntervalSince1970)-\($0.totalAmount)-\($0.vatAmount)-\($0.statusRawValue)-\($0.paidDate?.timeIntervalSince1970 ?? 0)"
        }
        .joined(separator: "|")
    }

    private func currency(_ value: Double) -> String {
        AppFormatters.currencyFormatter().string(from: NSNumber(value: value)) ?? "EUR 0.00"
    }

    private var localization: AppLocalization {
        AppLocalization(localeIdentifier: appSettings.first?.preferredLocaleIdentifier)
    }
}
