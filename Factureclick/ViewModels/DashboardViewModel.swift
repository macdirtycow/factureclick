//
//  DashboardViewModel.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation

struct DashboardSnapshot {
    let weeklyRevenue: Double
    let weeklyCreditAmount: Double
    let weeklyHours: Double
    let productsDelivered: Double
    let openInvoicesCount: Int
    let partnerShare: Double
    let userNetRevenue: Double
}

enum DashboardRevenuePeriod {
    case week
    case month
}

enum DashboardRevenuePeriodSelection: String, CaseIterable, Identifiable {
    case current
    case previous

    var id: String { rawValue }
}

struct DashboardDailyRevenuePoint: Identifiable {
    let date: Date
    let revenue: Double
    let invoiceCount: Int
    let averageInvoiceValue: Double

    var id: Date { date }
}

struct DashboardViewModel {
    let calendar: Calendar
    let collaborationRevenueService: CollaborationRevenueService

    init(
        calendar: Calendar = .current,
        collaborationRevenueService: CollaborationRevenueService = CollaborationRevenueService()
    ) {
        self.calendar = calendar
        self.collaborationRevenueService = collaborationRevenueService
    }

    func makeSnapshot(invoices: [Invoice], workEntries: [WorkEntry], referenceDate: Date = .now) -> DashboardSnapshot {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: referenceDate) else {
            return DashboardSnapshot(weeklyRevenue: 0, weeklyCreditAmount: 0, weeklyHours: 0, productsDelivered: 0, openInvoicesCount: 0, partnerShare: 0, userNetRevenue: 0)
        }

        let weeklyInvoices = invoices.filter { weekInterval.contains($0.date) }
        let weeklyCreditAmount = weeklyInvoices
            .filter { $0.isCreditInvoice }
            .reduce(0) { $0 + abs($1.totalAmount) }
        let weeklyWorkEntries = workEntries.filter { weekInterval.contains($0.date) }

        let weeklyRevenue = weeklyInvoices.reduce(0) { $0 + $1.totalAmount }
        let weeklyHours = weeklyWorkEntries.reduce(0) { $0 + $1.hoursWorked }
        let deliveredProducts = weeklyWorkEntries
            .filter { $0.product != nil }
            .reduce(0) { $0 + $1.quantity }
        let openInvoicesCount = invoices.filter { $0.status != .paid }.count
        let collaborationSummary = collaborationRevenueService.makeSummary(for: weeklyWorkEntries)

        return DashboardSnapshot(
            weeklyRevenue: weeklyRevenue,
            weeklyCreditAmount: weeklyCreditAmount,
            weeklyHours: weeklyHours,
            productsDelivered: deliveredProducts,
            openInvoicesCount: openInvoicesCount,
            partnerShare: collaborationSummary.partnerShare,
            userNetRevenue: collaborationSummary.userNetAmount
        )
    }

    func currencyString(for value: Double) -> String {
        let formatter = AppFormatters.currencyFormatter()
        return formatter.string(from: NSNumber(value: value)) ?? "EUR 0.00"
    }

    func makeWeeklyCollaborationSummary(workEntries: [WorkEntry], referenceDate: Date = .now) -> CollaborationRevenueSummary {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: referenceDate) else {
            return CollaborationRevenueSummary(grossAmount: 0, partnerShare: 0, userNetAmount: 0, partnerSummaries: [])
        }

        let weeklyWorkEntries = workEntries.filter { weekInterval.contains($0.date) }
        return collaborationRevenueService.makeSummary(for: weeklyWorkEntries)
    }

    func decimalString(for value: Double, maximumFractionDigits: Int = 1) -> String {
        let formatter = AppFormatters.decimalFormatter(maximumFractionDigits: maximumFractionDigits)
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    func dailyRevenueSeries(
        invoices: [Invoice],
        period: DashboardRevenuePeriod,
        referenceDate: Date = .now
    ) -> [DashboardDailyRevenuePoint] {
        guard let interval = dateInterval(for: period, referenceDate: referenceDate) else {
            return []
        }

        let groupedInvoices = Dictionary(grouping: invoices.filter { interval.contains($0.date) }) {
            calendar.startOfDay(for: $0.date)
        }

        var points: [DashboardDailyRevenuePoint] = []
        var cursor = calendar.startOfDay(for: interval.start)
        let endDate = calendar.startOfDay(for: interval.end)

        while cursor < endDate {
            let dayInvoices = groupedInvoices[cursor] ?? []
            let revenue = dayInvoices.reduce(0) { $0 + $1.totalAmount }
            let invoiceCount = dayInvoices.count
            let averageInvoiceValue = invoiceCount > 0 ? revenue / Double(invoiceCount) : 0

            points.append(
                DashboardDailyRevenuePoint(
                    date: cursor,
                    revenue: revenue,
                    invoiceCount: invoiceCount,
                    averageInvoiceValue: averageInvoiceValue
                )
            )

            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: cursor) else {
                break
            }
            cursor = nextDay
        }

        return points
    }

    func dateInterval(for period: DashboardRevenuePeriod, referenceDate: Date = .now) -> DateInterval? {
        switch period {
        case .week:
            return calendar.dateInterval(of: .weekOfYear, for: referenceDate)
        case .month:
            return calendar.dateInterval(of: .month, for: referenceDate)
        }
    }

    func referenceDate(
        for period: DashboardRevenuePeriod,
        selection: DashboardRevenuePeriodSelection,
        from currentDate: Date = .now
    ) -> Date {
        guard selection == .previous else { return currentDate }

        switch period {
        case .week:
            return calendar.date(byAdding: .weekOfYear, value: -1, to: currentDate) ?? currentDate
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: currentDate) ?? currentDate
        }
    }
}
