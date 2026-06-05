//
//  DashboardView.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import SwiftData
import SwiftUI

struct DashboardView: View {
    @Environment(AppViewModel.self) private var appViewModel

    @Query(sort: \Invoice.date, order: .reverse) private var invoices: [Invoice]
    @Query(sort: \WorkEntry.date, order: .reverse) private var workEntries: [WorkEntry]
    @Query(sort: \Quote.date, order: .reverse) private var quotes: [Quote]
    @Query private var appSettings: [AppSettings]
    @Query private var moduleConfigurations: [ModuleVisibilityConfiguration]

    private let viewModel = DashboardViewModel()
    private let invoiceRepository = InvoiceRepository()
    private let workModeService = WorkModeConfigurationService()

    var body: some View {
        let snapshot = viewModel.makeSnapshot(invoices: invoices, workEntries: workEntries)
        let registrationWorkflowVisible = showsRegistrationWorkflow
        let invoiceSuggestion = invoiceRepository.makeSuggestedLaunchContext(
            from: workEntries,
            startDate: Calendar.current.dateInterval(of: .weekOfYear, for: .now)?.start,
            endDate: Calendar.current.date(byAdding: .day, value: 6, to: Calendar.current.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now),
            sourceTitle: localization.phrase("Dashboard quick invoice")
        )
        let weeklyPreparation = invoiceRepository.makeEndOfWeekPreparation(from: workEntries)
        let collaborationSummary = viewModel.makeWeeklyCollaborationSummary(workEntries: workEntries)
        let quickActionItems = quickActions(
            invoiceSuggestion: invoiceSuggestion,
            weeklyPreparation: weeklyPreparation
        )
        let metrics = metricItems(snapshot: snapshot)

        ScrollView {
            dashboardContent(
                snapshot: snapshot,
                registrationWorkflowVisible: registrationWorkflowVisible,
                weeklyPreparation: weeklyPreparation,
                collaborationSummary: collaborationSummary,
                quickActionItems: quickActionItems,
                metrics: metrics
            )
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    CollaborationSettingsView()
                } label: {
                    Label(localization.text(.settingsAlertTitle), systemImage: "gearshape")
                }
            }
        }
        .background(AppTheme.screenBackground.ignoresSafeArea())
        .navigationTitle(localization.phrase("Dashboard"))
        .navigationBarTitleDisplayMode(.large)
    }

    private func dashboardContent(
        snapshot: DashboardSnapshot,
        registrationWorkflowVisible: Bool,
        weeklyPreparation: WeeklyBillingPreparation,
        collaborationSummary: CollaborationRevenueSummary,
        quickActionItems: [DashboardQuickAction],
        metrics: [DashboardMetricItem]
    ) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            headerCard(snapshot: snapshot, showsRegistrationWorkflow: registrationWorkflowVisible)
            if registrationWorkflowVisible, weeklyPreparation.shouldHighlight {
                weeklyPreparationCard(preparation: weeklyPreparation)
            }
            metricsGrid(items: metrics)
            if registrationWorkflowVisible {
                RevenueSplitCard(
                    title: localization.phrase("Weekly split"),
                    summary: collaborationSummary,
                    localization: localization
                )
            }
            quickActionsSection(items: quickActionItems)
            if isModuleEnabled(.annualRevenueSummary) {
                annualSummaryCard
            }
        }
    }

    private func headerCard(snapshot: DashboardSnapshot, showsRegistrationWorkflow: Bool) -> some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 14) {
                AppLogoView(
                    title: AppBrand.displayName,
                    subtitle: modeHeadline,
                    size: 52,
                    accentColor: AppTheme.color(hex: currentSettings?.preferredAccentColorHex ?? AppAccentTheme.ocean.hex)
                )

                Text(modeHeadline)
                    .font(AppTheme.titleFont)
                    .foregroundStyle(AppTheme.primaryText)

                Text(modeSummary)
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.secondaryText)

                HStack(spacing: 10) {
                    Label("\(snapshot.openInvoicesCount) \(localization.phrase("open"))", systemImage: "tray.full")
                    if showsRegistrationWorkflow {
                        Label("\(viewModel.decimalString(for: snapshot.weeklyHours)) \(localization.phrase("h logged"))", systemImage: "clock")
                    } else {
                        Label("\(acceptedQuotesCount) \(localization.phrase("accepted quotes"))", systemImage: "checkmark.seal")
                    }
                }
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }

    private func metricsGrid(items: [DashboardMetricItem]) -> some View {
        LazyVGrid(columns: gridColumns, spacing: 16) {
            ForEach(items) { item in
                if let revenuePeriod = item.revenuePeriod {
                    NavigationLink {
                        DashboardRevenueDetailView(
                            period: revenuePeriod,
                            invoices: invoices,
                            viewModel: viewModel,
                            localization: localization
                        )
                    } label: {
                        DashboardMetricCard(
                            title: item.title,
                            value: item.value,
                            subtitle: item.subtitle,
                            systemImage: item.systemImage
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    DashboardMetricCard(
                        title: item.title,
                        value: item.value,
                        subtitle: item.subtitle,
                        systemImage: item.systemImage
                    )
                }
            }
        }
    }

    private func weeklyPreparationCard(preparation: WeeklyBillingPreparation) -> some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(localization.phrase("End-of-week billing"))
                    .font(AppTheme.titleFont)
                    .foregroundStyle(AppTheme.primaryText)

                Text(weeklyPreparationText(preparation))
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.secondaryText)

                Button(localization.phrase("Open Weekly Review")) {
                    appViewModel.openWeeklyInvoiceReview(for: preparation.weekEnd)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accentColor)
            }
        }
    }

    private func quickActionsSection(items: [DashboardQuickAction]) -> some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 18) {
                Text(localization.phrase("Quick actions"))
                    .font(AppTheme.sectionTitleFont)
                    .foregroundStyle(AppTheme.primaryText)

                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    QuickActionCard(
                        title: item.title,
                        subtitle: item.subtitle,
                        systemImage: item.systemImage,
                        action: item.action
                    )

                    if index != items.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }

    private var annualSummaryCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(localization.phrase("Annual revenue summary"))
                            .font(AppTheme.titleFont)
                            .foregroundStyle(AppTheme.primaryText)

                        Text(localization.phrase("Review yearly revenue, VAT, delivered work, and top clients in one business snapshot."))
                            .font(AppTheme.bodyFont)
                            .foregroundStyle(AppTheme.secondaryText)
                    }

                    Spacer()

                    NavigationLink(localization.phrase("Open")) {
                        AnnualRevenueSummaryView()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accentColor)
                }
            }
        }
    }

    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ]
    }

    private var currentSettings: AppSettings? {
        appSettings.first
    }

    private var currentModuleConfiguration: ModuleVisibilityConfiguration? {
        moduleConfigurations.first
    }

    private var localization: AppLocalization {
        AppLocalization(localeIdentifier: currentSettings?.preferredLocaleIdentifier)
    }

    private var currentWorkMode: WorkMode {
        currentSettings?.workMode ?? .hybrid
    }

    private var showsRegistrationWorkflow: Bool {
        isModuleEnabled(.agenda) || isModuleEnabled(.workRegistrations) || isModuleEnabled(.timeTracking)
    }

    private var acceptedQuotesCount: Int {
        quotes.filter { $0.status == .accepted }.count
    }

    private var modeHeadline: String {
        switch currentWorkMode {
        case .freelancer:
            localization.phrase("Freelancer overview")
        case .quoteBusiness:
            localization.phrase("Business overview")
        case .hybrid:
            localization.phrase("All overview")
        case .custom:
            localization.phrase("Custom overview")
        }
    }

    private var modeSummary: String {
        switch currentWorkMode {
        case .freelancer:
            localization.phrase("Track hours, registrations, uninvoiced work, and invoice progress from one focused dashboard.")
        case .quoteBusiness:
            localization.phrase("Track quotes, invoices, and client-facing business activity without operational noise.")
        case .hybrid:
            localization.phrase("Follow every workflow and business tool in one complete overview.")
        case .custom:
            localization.phrase("Follow the exact workflows and modules you enabled for this business.")
        }
    }

    private func isModuleEnabled(_ module: AppModule) -> Bool {
        workModeService.isModuleEnabled(
            module,
            settings: currentSettings,
            moduleConfiguration: currentModuleConfiguration
        )
    }

    private func weeklyPreparationText(_ preparation: WeeklyBillingPreparation) -> String {
        switch currentSettings.flatMap({ SupportedLocale(rawValue: $0.preferredLocaleIdentifier) }) ?? .english {
        case .english:
            "\(preparation.pendingEntries.count) open registrations worth \(viewModel.currencyString(for: preparation.pendingValue)) are ready for review."
        case .dutch:
            "\(preparation.pendingEntries.count) open registraties ter waarde van \(viewModel.currencyString(for: preparation.pendingValue)) staan klaar voor controle."
        case .german:
            "\(preparation.pendingEntries.count) offene Erfassungen im Wert von \(viewModel.currencyString(for: preparation.pendingValue)) sind bereit zur Prüfung."
        }
    }

    private func metricItems(snapshot: DashboardSnapshot) -> [DashboardMetricItem] {
        let monthlyRevenue = invoices.filter {
            Calendar.current.isDate($0.date, equalTo: .now, toGranularity: .month)
        }.reduce(0) { $0 + $1.totalAmount }
        let monthlyCreditAmount = invoices
            .filter { $0.isCreditInvoice }
            .filter { Calendar.current.isDate($0.date, equalTo: .now, toGranularity: .month) }
            .reduce(0) { $0 + abs($1.totalAmount) }
        let thisWeekEntries = workEntries.filter {
            Calendar.current.isDate($0.date, equalTo: .now, toGranularity: .weekOfYear)
        }
        let uninvoicedWorkCount = workEntries.filter { $0.includeInInvoice && !$0.isInvoiced }.count
        let openQuotesCount = quotes.filter { [.draft, .sent].contains($0.status) }.count

        switch currentWorkMode {
        case .freelancer:
            return [
                DashboardMetricItem(title: localization.phrase("Hours this week"), value: viewModel.decimalString(for: snapshot.weeklyHours), subtitle: localization.phrase("Tracked this week"), systemImage: "clock.badge.checkmark"),
                DashboardMetricItem(title: localization.phrase("Registrations"), value: "\(thisWeekEntries.count)", subtitle: localization.phrase("Work logs this week"), systemImage: "checklist"),
                DashboardMetricItem(title: localization.phrase("Uninvoiced work"), value: "\(uninvoicedWorkCount)", subtitle: localization.phrase("Entries still open"), systemImage: "tray.full"),
                DashboardMetricItem(title: localization.phrase("Weekly revenue"), value: viewModel.currencyString(for: snapshot.weeklyRevenue), subtitle: localization.phrase("Invoices dated this week"), systemImage: "chart.line.uptrend.xyaxis", revenuePeriod: .week),
                DashboardMetricItem(title: localization.phrase("Monthly revenue"), value: viewModel.currencyString(for: monthlyRevenue), subtitle: localization.phrase("Invoices dated this month"), systemImage: "calendar", revenuePeriod: .month),
                DashboardMetricItem(title: localization.phrase("Credited this month"), value: viewModel.currencyString(for: monthlyCreditAmount), subtitle: localization.phrase("Credit invoices issued"), systemImage: "arrow.uturn.backward.circle"),
                DashboardMetricItem(title: localization.phrase("Open invoices"), value: "\(snapshot.openInvoicesCount)", subtitle: localization.phrase("Draft and sent invoices"), systemImage: "doc.text.magnifyingglass")
            ]
        case .quoteBusiness:
            return [
                DashboardMetricItem(title: localization.phrase("Open quotes"), value: "\(openQuotesCount)", subtitle: localization.phrase("Draft and sent quotes"), systemImage: "doc.text"),
                DashboardMetricItem(title: localization.phrase("Accepted quotes"), value: "\(acceptedQuotesCount)", subtitle: localization.phrase("Ready for invoicing"), systemImage: "checkmark.seal"),
                DashboardMetricItem(title: localization.phrase("Open invoices"), value: "\(snapshot.openInvoicesCount)", subtitle: localization.phrase("Awaiting payment"), systemImage: "tray.full"),
                DashboardMetricItem(title: localization.phrase("Monthly revenue"), value: viewModel.currencyString(for: monthlyRevenue), subtitle: localization.phrase("Invoices dated this month"), systemImage: "chart.bar", revenuePeriod: .month),
                DashboardMetricItem(title: localization.phrase("Credited this month"), value: viewModel.currencyString(for: monthlyCreditAmount), subtitle: localization.phrase("Credit invoices issued"), systemImage: "arrow.uturn.backward.circle")
            ]
        case .hybrid:
            return [
                DashboardMetricItem(title: localization.phrase("Hours this week"), value: viewModel.decimalString(for: snapshot.weeklyHours), subtitle: localization.phrase("Tracked work"), systemImage: "clock.badge.checkmark"),
                DashboardMetricItem(title: localization.phrase("Open quotes"), value: "\(openQuotesCount)", subtitle: localization.phrase("Draft and sent quotes"), systemImage: "doc.text"),
                DashboardMetricItem(title: localization.phrase("Open invoices"), value: "\(snapshot.openInvoicesCount)", subtitle: localization.phrase("Draft and sent invoices"), systemImage: "doc.text.magnifyingglass"),
                DashboardMetricItem(title: localization.phrase("Weekly revenue"), value: viewModel.currencyString(for: snapshot.weeklyRevenue), subtitle: localization.phrase("Invoices dated this week"), systemImage: "chart.line.uptrend.xyaxis", revenuePeriod: .week),
                DashboardMetricItem(title: localization.phrase("Monthly revenue"), value: viewModel.currencyString(for: monthlyRevenue), subtitle: localization.phrase("Invoices dated this month"), systemImage: "calendar", revenuePeriod: .month),
                DashboardMetricItem(title: localization.phrase("Credited this month"), value: viewModel.currencyString(for: monthlyCreditAmount), subtitle: localization.phrase("Credit invoices issued"), systemImage: "arrow.uturn.backward.circle"),
                DashboardMetricItem(title: localization.phrase("Products delivered"), value: viewModel.decimalString(for: snapshot.productsDelivered), subtitle: localization.phrase("Delivered this week"), systemImage: "shippingbox.fill")
            ]
        case .custom:
            var items = [
                DashboardMetricItem(title: localization.phrase("Open invoices"), value: "\(snapshot.openInvoicesCount)", subtitle: localization.phrase("Awaiting payment"), systemImage: "tray.full"),
                DashboardMetricItem(title: localization.phrase("Monthly revenue"), value: viewModel.currencyString(for: monthlyRevenue), subtitle: localization.phrase("Invoices dated this month"), systemImage: "chart.bar", revenuePeriod: .month),
                DashboardMetricItem(title: localization.phrase("Credited this month"), value: viewModel.currencyString(for: monthlyCreditAmount), subtitle: localization.phrase("Credit invoices issued"), systemImage: "arrow.uturn.backward.circle")
            ]

            if showsRegistrationWorkflow {
                items.append(DashboardMetricItem(title: localization.phrase("Registrations"), value: "\(thisWeekEntries.count)", subtitle: localization.phrase("Work logs this week"), systemImage: "checklist"))
            }

            if isModuleEnabled(.quotes) {
                items.append(DashboardMetricItem(title: localization.phrase("Open quotes"), value: "\(openQuotesCount)", subtitle: localization.phrase("Draft and sent quotes"), systemImage: "doc.text"))
            }

            return items
        }
    }

    private func quickActions(
        invoiceSuggestion: InvoiceWorkflowLaunchContext?,
        weeklyPreparation: WeeklyBillingPreparation
    ) -> [DashboardQuickAction] {
        switch currentWorkMode {
        case .freelancer:
            return [
                DashboardQuickAction(title: localization.phrase("Add new Work Entry"), subtitle: localization.phrase("Jump into this week's registrations"), systemImage: "plus.rectangle.on.rectangle") {
                    appViewModel.openWorkEntryForm(preferAgenda: isModuleEnabled(.agenda))
                },
                DashboardQuickAction(title: localization.phrase("Create Invoice"), subtitle: invoiceSuggestion == nil ? localization.phrase("Open the billing workspace") : localization.phrase("Jump into suggested uninvoiced work"), systemImage: "doc.badge.plus") {
                    appViewModel.openInvoiceWorkflow(invoiceSuggestion)
                },
                DashboardQuickAction(title: localization.phrase("Weekly Review"), subtitle: weeklyPreparation.pendingEntries.isEmpty ? localization.phrase("Prepare Friday billing checks") : "\(weeklyPreparation.pendingEntries.count) \(localization.phrase("open registrations this week"))", systemImage: "list.bullet.clipboard") {
                    appViewModel.openWeeklyInvoiceReview(for: weeklyPreparation.weekEnd)
                },
                DashboardQuickAction(title: localization.phrase("Open Agenda"), subtitle: localization.phrase("Review this week's planning"), systemImage: "calendar.badge.clock") {
                    appViewModel.selectedTab = .agenda
                }
            ]
        case .quoteBusiness:
            return [
                DashboardQuickAction(title: localization.phrase("Open Quotes"), subtitle: localization.phrase("Review proposals and pipeline"), systemImage: "doc.text") {
                    appViewModel.selectedTab = .invoices
                },
                DashboardQuickAction(title: localization.phrase("Create Invoice"), subtitle: localization.phrase("Open the billing workspace"), systemImage: "doc.badge.plus") {
                    appViewModel.openInvoiceWorkflow(nil)
                },
                DashboardQuickAction(title: localization.phrase("Open Clients"), subtitle: localization.phrase("Manage client relationships"), systemImage: "person.2") {
                    appViewModel.selectedTab = .clients
                }
            ]
        case .hybrid:
            return [
                DashboardQuickAction(title: localization.phrase("Add new Work Entry"), subtitle: localization.phrase("Jump into this week's registrations"), systemImage: "plus.rectangle.on.rectangle") {
                    appViewModel.openWorkEntryForm(preferAgenda: isModuleEnabled(.agenda))
                },
                DashboardQuickAction(title: localization.phrase("Create Invoice"), subtitle: invoiceSuggestion == nil ? localization.phrase("Open the billing workspace") : localization.phrase("Jump into suggested uninvoiced work"), systemImage: "doc.badge.plus") {
                    appViewModel.openInvoiceWorkflow(invoiceSuggestion)
                },
                DashboardQuickAction(title: localization.phrase("Open Quotes"), subtitle: localization.phrase("Review proposals and accepted work"), systemImage: "doc.text") {
                    appViewModel.selectedTab = .invoices
                },
                DashboardQuickAction(title: localization.phrase("Open Agenda"), subtitle: localization.phrase("Review this week's planning"), systemImage: "calendar.badge.clock") {
                    if isModuleEnabled(.agenda) {
                        appViewModel.selectedTab = .agenda
                    }
                }
            ]
        case .custom:
            var actions: [DashboardQuickAction] = []

            if isModuleEnabled(.workRegistrations) || isModuleEnabled(.agenda) {
                actions.append(
                    DashboardQuickAction(title: localization.phrase("Add new Work Entry"), subtitle: localization.phrase("Jump into this week's registrations"), systemImage: "plus.rectangle.on.rectangle") {
                        appViewModel.openWorkEntryForm(preferAgenda: isModuleEnabled(.agenda))
                    }
                )
            }

            if isModuleEnabled(.invoices) {
                actions.append(
                    DashboardQuickAction(title: localization.phrase("Create Invoice"), subtitle: invoiceSuggestion == nil ? localization.phrase("Open the billing workspace") : localization.phrase("Jump into suggested uninvoiced work"), systemImage: "doc.badge.plus") {
                        appViewModel.openInvoiceWorkflow(invoiceSuggestion)
                    }
                )
            }

            if isModuleEnabled(.quotes) {
                actions.append(
                    DashboardQuickAction(title: localization.phrase("Open Quotes"), subtitle: localization.phrase("Review proposals and accepted work"), systemImage: "doc.text") {
                        appViewModel.selectedTab = .invoices
                    }
                )
            }

            if actions.isEmpty {
                actions.append(
                    DashboardQuickAction(title: localization.phrase("Open Clients"), subtitle: localization.phrase("Manage client relationships"), systemImage: "person.2") {
                        appViewModel.selectedTab = .clients
                    }
                )
            }

            return actions
        }
    }
}

private struct DashboardMetricItem: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let subtitle: String
    let systemImage: String
    var revenuePeriod: DashboardRevenuePeriod?
}

private struct DashboardQuickAction {
    let title: String
    let subtitle: String
    let systemImage: String
    let action: () -> Void
}

#Preview {
    NavigationStack {
        DashboardView()
            .environment(AppViewModel())
            .modelContainer(DashboardPreviewData.makeContainer())
    }
}
