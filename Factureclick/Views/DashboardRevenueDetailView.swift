//
//  DashboardRevenueDetailView.swift
//  Factureclick
//
//  Created by Codex on 24/04/2026.
//

import Charts
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

    var body: some View {
        let points = viewModel.dailyRevenueSeries(invoices: invoices, period: period)

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
                        Picker(localizedMetricTitle, selection: $selectedMetric) {
                            ForEach(DashboardRevenueDetailMetric.allCases) { metric in
                                Text(metricLabel(metric)).tag(metric)
                            }
                        }
                        .pickerStyle(.segmented)

                        if points.contains(where: hasData) {
                            Chart(points) { point in
                                BarMark(
                                    x: .value("Date", point.date, unit: .day),
                                    y: .value(metricValueLabel, chartValue(for: point))
                                )
                                .foregroundStyle(AppTheme.accentColor.gradient)
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            }
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day)) { _ in
                                    AxisGridLine()
                                    AxisTick()
                                    AxisValueLabel(format: axisDateFormat)
                                }
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading)
                            }
                            .frame(height: 240)
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
        switch period {
        case .week:
            localization.phrase("This week")
        case .month:
            localization.phrase("This month")
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

    private var axisDateFormat: Date.FormatStyle {
        switch period {
        case .week:
            Date.FormatStyle.dateTime.weekday(.narrow)
        case .month:
            Date.FormatStyle.dateTime.day()
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
}

