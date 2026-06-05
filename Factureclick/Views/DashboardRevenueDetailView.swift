//
//  DashboardRevenueDetailView.swift
//  Factureclick
//
//  Created by Codex on 24/04/2026.
//

import SwiftUI

private enum DashboardRevenueDetailMetric: String, CaseIterable, Identifiable {
    case revenue
    case invoiceCount
    case averagePerDay

    var id: String { rawValue }
}

struct DashboardRevenueDetailView: View {
    let period: DashboardRevenuePeriod
    let invoices: [Invoice]
    let viewModel: DashboardViewModel
    let localization: AppLocalization

    @State private var selectedMetric: DashboardRevenueDetailMetric = .revenue
    @State private var selectedPeriod: DashboardRevenuePeriodSelection = .current

    var body: some View {
        let referenceDate = viewModel.referenceDate(for: period, selection: selectedPeriod)
        let points = viewModel.dailyRevenueSeries(invoices: invoices, period: period, referenceDate: referenceDate)

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(title)
                            .font(AppTheme.titleFont)
                            .foregroundStyle(AppTheme.primaryText)

                        Text(subtitle)
                            .font(AppTheme.bodyFont)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }

                SectionCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Picker(localization.phrase("Period"), selection: $selectedPeriod) {
                            ForEach(DashboardRevenuePeriodSelection.allCases) { option in
                                Text(periodSelectionLabel(option)).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)

                        Picker(localizedMetricTitle, selection: $selectedMetric) {
                            ForEach(DashboardRevenueDetailMetric.allCases) { metric in
                                Text(metricLabel(metric)).tag(metric)
                            }
                        }
                        .pickerStyle(.segmented)

                        if points.contains(where: hasData) {
                            compactBarChart(points: points)
                        } else {
                            Text(localization.phrase("No invoices dated in this period."))
                                .font(AppTheme.bodyFont)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                }

                SectionCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(localizedMetricTitle)
                            .font(AppTheme.sectionTitleFont)
                            .foregroundStyle(AppTheme.primaryText)

                        ForEach(points) { point in
                            HStack {
                                Text(point.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(AppTheme.bodyFont)
                                    .foregroundStyle(AppTheme.primaryText)

                                Spacer()

                                Text(formattedValue(for: point))
                                    .font(AppTheme.bodyFont.weight(.semibold))
                                    .foregroundStyle(AppTheme.primaryText)
                            }

                            if point.id != points.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(AppTheme.screenBackground.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var title: String {
        switch period {
        case .week:
            localization.phrase("Weekly revenue")
        case .month:
            localization.phrase("Monthly revenue")
        }
    }

    private var subtitle: String {
        switch (period, selectedPeriod) {
        case (.week, .current):
            localization.phrase("This week")
        case (.week, .previous):
            localization.phrase("Previous week")
        case (.month, .current):
            localization.phrase("This month")
        case (.month, .previous):
            localization.phrase("Previous month")
        }
    }

    private var localizedMetricTitle: String {
        metricLabel(selectedMetric)
    }

    private var metricValueLabel: String {
        switch selectedMetric {
        case .revenue:
            localization.phrase("Revenue")
        case .invoiceCount:
            localization.phrase("Invoices")
        case .averagePerDay:
            localization.phrase("Average per day")
        }
    }

    private func metricLabel(_ metric: DashboardRevenueDetailMetric) -> String {
        switch metric {
        case .revenue:
            localization.phrase("Revenue")
        case .invoiceCount:
            localization.phrase("Invoices")
        case .averagePerDay:
            localization.phrase("Average per day")
        }
    }

    private func periodSelectionLabel(_ option: DashboardRevenuePeriodSelection) -> String {
        switch (period, option) {
        case (.week, .current):
            localization.phrase("This Week")
        case (.week, .previous):
            localization.phrase("Previous Week")
        case (.month, .current):
            localization.phrase("This Month")
        case (.month, .previous):
            localization.phrase("Previous Month")
        }
    }

    private func chartValue(for point: DashboardDailyRevenuePoint) -> Double {
        switch selectedMetric {
        case .revenue:
            point.revenue
        case .invoiceCount:
            Double(point.invoiceCount)
        case .averagePerDay:
            point.averageInvoiceValue
        }
    }

    private func formattedValue(for point: DashboardDailyRevenuePoint) -> String {
        switch selectedMetric {
        case .revenue:
            viewModel.currencyString(for: point.revenue)
        case .invoiceCount:
            String(point.invoiceCount)
        case .averagePerDay:
            viewModel.currencyString(for: point.averageInvoiceValue)
        }
    }

    private func hasData(_ point: DashboardDailyRevenuePoint) -> Bool {
        switch selectedMetric {
        case .revenue:
            point.revenue != 0
        case .invoiceCount:
            point.invoiceCount != 0
        case .averagePerDay:
            point.averageInvoiceValue != 0
        }
    }

    private func compactBarChart(points: [DashboardDailyRevenuePoint]) -> some View {
        let maxValue = points.map(chartValue(for:)).max() ?? 0

        return VStack(alignment: .leading, spacing: 12) {
            GeometryReader { geometry in
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(Array(points.enumerated()), id: \.element.id) { index, point in
                        let value = chartValue(for: point)
                        let ratio = maxValue > 0 ? value / maxValue : 0

                        VStack(spacing: 8) {
                            Spacer(minLength: 0)

                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(AppTheme.accentColor.gradient)
                                .frame(height: max(8, ratio * max(geometry.size.height - 28, 60)))

                            Text(axisLabel(for: point.date, index: index, total: points.count))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(AppTheme.secondaryText)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    }
                }
            }
            .frame(height: 220)

            HStack {
                Text(localization.phrase("Highest"))
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.secondaryText)

                Spacer()

                Text(formattedChartScaleValue(maxValue))
                    .font(AppTheme.captionFont.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
            }
        }
    }

    private func axisLabel(for date: Date, index: Int, total: Int) -> String {
        switch period {
        case .week:
            if shouldShowWeekAxisLabel(index: index, total: total) {
                return date.formatted(.dateTime.weekday(.short))
            }
            return ""
        case .month:
            if shouldShowMonthAxisLabel(index: index, total: total) {
                return date.formatted(.dateTime.day())
            }
            return ""
        }
    }

    private func shouldShowMonthAxisLabel(index: Int, total: Int) -> Bool {
        if index == 0 || index == total - 1 {
            return true
        }

        let day = index + 1
        let anchorDays: Set<Int>

        switch total {
        case 0...8:
            anchorDays = [1, 3, 5, 7]
        case 9...16:
            anchorDays = [1, 5, 9, 13]
        case 17...24:
            anchorDays = [1, 7, 13, 19]
        default:
            anchorDays = [1, 7, 14, 21, 28]
        }

        return anchorDays.contains(day)
    }

    private func shouldShowWeekAxisLabel(index: Int, total: Int) -> Bool {
        if total <= 4 {
            return true
        }

        if index == 0 || index == total - 1 {
            return true
        }

        let anchorIndexes: Set<Int> = [2, 4]
        return anchorIndexes.contains(index)
    }

    private func formattedChartScaleValue(_ value: Double) -> String {
        switch selectedMetric {
        case .revenue, .averagePerDay:
            viewModel.currencyString(for: value)
        case .invoiceCount:
            String(Int(value.rounded()))
        }
    }
}
