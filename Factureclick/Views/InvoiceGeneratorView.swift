//
//  InvoiceGeneratorView.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import SwiftData
import SwiftUI

struct InvoiceGeneratorView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Client.name) private var clients: [Client]
    @Query(sort: \Product.name) private var products: [Product]
    @Query(sort: \WorkEntry.date, order: .reverse) private var workEntries: [WorkEntry]
    @Query(sort: \Invoice.date, order: .reverse) private var invoices: [Invoice]
    @Query(sort: \Quote.date, order: .reverse) private var quotes: [Quote]
    @Query(sort: \RecurringInvoiceTemplate.createdAt, order: .reverse) private var recurringTemplates: [RecurringInvoiceTemplate]
    @Query private var collaborationRules: [CollaborationRule]
    @Query private var appSettings: [AppSettings]
    @Query private var moduleConfigurations: [ModuleVisibilityConfiguration]
    @Query(sort: \CompanyProfile.createdAt, order: .reverse) private var companyProfiles: [CompanyProfile]

    @State private var viewModel = InvoiceGenerationViewModel()
    @State private var historyViewModel = InvoiceHistoryViewModel()
    @State private var saveErrorMessage: String?
    @State private var isPresentingPeriodWorkflow = false
    @State private var isPresentingClientForm = false
    @State private var clientHourlyRateText = ""
    @State private var periodWorkflowReferenceDate = Date()
    @State private var workflowBannerTitle: String?
    @State private var hasPreparedScreen = false
    @State private var recentlySavedInvoices: [Invoice] = []

    private let repository = InvoiceRepository()
    private let overdueInvoiceService = OverdueInvoiceService()
    private let workModeService = WorkModeConfigurationService()

    var body: some View {
        guard hasPreparedScreen else {
            return AnyView(loadingView)
        }

        return AnyView(
            invoiceScreen(
                selectedClient: currentSelectedClient,
                availableEntries: viewModel.availableRegistrations(from: workEntries),
                collaborationRule: collaborationRules.first(where: { $0.client?.id == currentSelectedClient?.id }),
                totals: viewModel.totals(collaborationRule: collaborationRules.first(where: { $0.client?.id == currentSelectedClient?.id })),
                suggestedLaunchContext: repository.makeSuggestedLaunchContext(
                    from: workEntries,
                    preferredClientID: viewModel.selectedClientID,
                    startDate: viewModel.startDate,
                    endDate: viewModel.endDate
                )
            )
        )
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text(localization.phrase("Loading invoices"))
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.screenBackground.ignoresSafeArea())
        .navigationTitle(localization.phrase("Invoices"))
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            guard !hasPreparedScreen else { return }
            handleAppear()
            hasPreparedScreen = true
        }
    }

    private func invoiceScreen(
        selectedClient: Client?,
        availableEntries: [WorkEntry],
        collaborationRule: CollaborationRule?,
        totals: InvoiceDraftTotals,
        suggestedLaunchContext: InvoiceWorkflowLaunchContext?
    ) -> some View {
        let content = AnyView(
            mainContent(
                selectedClient: selectedClient,
                availableEntries: availableEntries,
                collaborationRule: collaborationRule,
                totals: totals,
                suggestedLaunchContext: suggestedLaunchContext
            )
        )

        let baseView = baseInvoiceScreen(content: content)
        let workflowObservedView = applyWorkflowObservers(
            to: baseView,
            selectedClient: selectedClient,
            availableEntries: availableEntries
        )
        return applyHistoryObservers(to: workflowObservedView)
    }

    private func baseInvoiceScreen(content: AnyView) -> some View {
        ScrollView {
            content
        }
        .background(AppTheme.screenBackground.ignoresSafeArea())
        .navigationTitle(localization.phrase("Invoices"))
        .navigationBarTitleDisplayMode(.large)
    }

    private func applyWorkflowObservers<Content: View>(
        to view: Content,
        selectedClient: Client?,
        availableEntries: [WorkEntry]
    ) -> some View {
        view
            .onChange(of: settingsDefaultsFingerprint) { _, _ in
                viewModel.apply(settings: appSettings.first)
                if viewModel.mode != .manual {
                    viewModel.generateAutomaticLines(from: availableEntries)
                }
            }
            .onChange(of: pendingWorkflowFingerprint) { _, _ in
                applyPendingWorkflowIfNeeded()
            }
            .onChange(of: pendingQuoteConversionFingerprint) { _, _ in
                applyPendingQuoteConversionIfNeeded()
            }
            .onChange(of: pendingWeeklyReviewFingerprint) { _, _ in
                applyPendingWeeklyReviewIfNeeded()
            }
            .onChange(of: viewModel.selectedClientID) { _, _ in
                viewModel.updateDueDate(for: selectedClient)
                viewModel.syncSelection(with: availableEntries)
                clientHourlyRateText = selectedClient.map { formatHourlyRate($0.defaultHourlyRate) } ?? ""
                if viewModel.mode != .manual {
                    viewModel.generateAutomaticLines(from: availableEntries)
                }
            }
            .onChange(of: viewModel.invoiceDate) { _, _ in
                viewModel.updateDueDate(for: selectedClient)
            }
            .onChange(of: viewModel.startDate) { _, _ in
                viewModel.syncSelection(with: availableEntries)
                if viewModel.mode != .manual {
                    viewModel.generateAutomaticLines(from: availableEntries)
                }
            }
            .onChange(of: viewModel.endDate) { _, _ in
                viewModel.syncSelection(with: availableEntries)
                if viewModel.mode != .manual {
                    viewModel.generateAutomaticLines(from: availableEntries)
                }
            }
            .onChange(of: viewModel.groupingMode) { _, _ in
                if viewModel.mode != .manual {
                    viewModel.generateAutomaticLines(from: availableEntries)
                }
            }
    }

    private func applyHistoryObservers<Content: View>(to view: Content) -> some View {
        view
            .alert(localization.phrase("Unable to Save Invoice"), isPresented: saveErrorBinding) {
                Button(localization.phrase("OK"), role: .cancel) { }
            } message: {
                Text(saveErrorMessage ?? "")
            }
            .onChange(of: historyViewModel.searchText) { _, _ in
                refreshInvoiceHistory()
            }
            .onChange(of: historyViewModel.selectedClientID) { _, _ in
                refreshInvoiceHistory()
            }
            .onChange(of: historyViewModel.selectedStatus) { _, _ in
                refreshInvoiceHistory()
            }
            .onChange(of: historyViewModel.startDate) { _, _ in
                refreshInvoiceHistory()
            }
            .onChange(of: historyViewModel.endDate) { _, _ in
                refreshInvoiceHistory()
            }
            .onChange(of: invoiceHistoryFingerprint) { _, _ in
                refreshInvoiceHistory()
            }
            .sheet(isPresented: $isPresentingPeriodWorkflow) {
                WeeklyInvoiceWorkflowView(
                    initialReferenceDate: periodWorkflowReferenceDate,
                    clients: clients,
                    workEntries: workEntries,
                    invoices: invoices,
                    collaborationRules: collaborationRules
                )
            }
            .sheet(isPresented: $isPresentingClientForm) {
                NavigationStack {
                    ClientFormView { client in
                        viewModel.selectedClientID = client.id
                        viewModel.updateDueDate(for: client)
                    }
                }
            }
    }

    private func mainContent(
        selectedClient: Client?,
        availableEntries: [WorkEntry],
        collaborationRule: CollaborationRule?,
        totals: InvoiceDraftTotals,
        suggestedLaunchContext: InvoiceWorkflowLaunchContext?
    ) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            if isModuleEnabled(.quotes) {
                quotesOverviewCard
            }
            invoiceHistoryOverviewCard
            if let sourceQuoteNumber = viewModel.sourceQuoteNumber {
                quoteConversionBanner(quoteNumber: sourceQuoteNumber)
            }
            if let suggestedLaunchContext {
                workflowSuggestionCard(context: suggestedLaunchContext)
            }
            if isModuleEnabled(.vatOverview) {
                quarterlyVATCard
            }
            if isModuleEnabled(.recurringInvoices) {
                recurringInvoicesCard
            }
            if isModuleEnabled(.paymentReminders) {
                paymentRemindersCard
            }
            invoiceBuilderGuideCard(selectedClient: selectedClient, availableEntries: availableEntries)
            builderConfigurationCard(selectedClient: selectedClient)
            registrationsSelectionCard(entries: availableEntries)
            invoiceLinesCard
            invoiceTotalsCard(totals: totals, collaborationRule: collaborationRule)
            savedInvoicesCard
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
    }

    private var invoiceHistoryOverviewCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(localization.phrase("Invoice history"))
                    .font(AppTheme.titleFont)
                    .foregroundStyle(AppTheme.primaryText)

                TextField(localization.phrase("Search by invoice number or client"), text: invoiceSearchBinding)
                    .textFieldStyle(.roundedBorder)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        FilterChip(title: localization.phrase("All Clients"), isSelected: historyViewModel.selectedClientID == nil) {
                            historyViewModel.selectedClientID = nil
                        }

                        ForEach(clients) { client in
                            FilterChip(title: client.name, isSelected: historyViewModel.selectedClientID == client.id) {
                                historyViewModel.selectedClientID = client.id
                            }
                        }
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(InvoiceHistoryStatusFilter.allCases) { filter in
                            FilterChip(title: localization.phrase(filter.title), isSelected: historyViewModel.selectedStatus == filter) {
                                historyViewModel.selectedStatus = filter
                            }
                        }
                    }
                }

                HStack(spacing: 12) {
                    DatePicker(localization.phrase("From"), selection: invoiceHistoryStartDateBinding, displayedComponents: .date)
                    DatePicker(localization.phrase("To"), selection: invoiceHistoryEndDateBinding, displayedComponents: .date)
                }

                LazyVGrid(columns: gridColumns, spacing: 16) {
                    DashboardMetricCard(
                        title: localization.phrase("Week Revenue"),
                        value: currency(historyViewModel.overview.weeklyRevenue),
                        subtitle: localization.phrase("Invoices this week"),
                        systemImage: "calendar"
                    )
                    DashboardMetricCard(
                        title: localization.phrase("Month Revenue"),
                        value: currency(historyViewModel.overview.monthlyRevenue),
                        subtitle: localization.phrase("Invoices this month"),
                        systemImage: "calendar.badge.clock"
                    )
                    DashboardMetricCard(
                        title: localization.phrase("Open"),
                        value: "\(historyViewModel.overview.openInvoiceCount)",
                        subtitle: localization.phrase("Draft, sent, overdue"),
                        systemImage: "tray.full"
                    )
                    DashboardMetricCard(
                        title: localization.phrase("Paid"),
                        value: "\(historyViewModel.overview.paidInvoiceCount)",
                        subtitle: localization.phrase("Completed invoices"),
                        systemImage: "checkmark.seal"
                    )
                    DashboardMetricCard(
                        title: localization.phrase("Overdue"),
                        value: "\(historyViewModel.overview.overdueInvoiceCount)",
                        subtitle: localization.phrase("Needs attention"),
                        systemImage: "exclamationmark.triangle"
                    )
                    DashboardMetricCard(
                        title: localization.phrase("Expected In"),
                        value: currency(historyViewModel.overview.expectedIncomingAmount),
                        subtitle: localization.phrase("Open invoice value"),
                        systemImage: "eurosign.arrow.circlepath"
                    )
                }
            }
        }
    }

    private var quotesOverviewCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(localization.phrase("Quotes and estimates"))
                            .font(AppTheme.titleFont)
                            .foregroundStyle(AppTheme.primaryText)

                        Text(localization.phrase("Prepare proposals before they become invoices."))
                            .font(AppTheme.bodyFont)
                            .foregroundStyle(AppTheme.secondaryText)
                    }

                    Spacer()

                    NavigationLink(localization.phrase("Open Quotes")) {
                        QuoteListView()
                    }
                    .buttonStyle(.borderedProminent)
                }

                if quotes.isEmpty {
                    Text(localization.phrase("No quotes created yet."))
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                } else {
                    ForEach(quotes.prefix(3)) { quote in
                        NavigationLink {
                            QuoteDetailView(quote: quote)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(quote.quoteNumber)
                                        .font(AppTheme.bodyFont.weight(.semibold))
                                        .foregroundStyle(AppTheme.primaryText)
                                    Text(quote.client.name)
                                        .font(AppTheme.captionFont)
                                        .foregroundStyle(AppTheme.secondaryText)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 4) {
                                    QuoteStatusChip(status: QuoteRepository().normalizedStatus(for: quote))
                                    Text(currency(quote.totalAmount))
                                        .font(AppTheme.captionFont)
                                        .foregroundStyle(AppTheme.secondaryText)
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        if quote.id != quotes.prefix(3).last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private var quarterlyVATCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(localization.phrase("Quarterly VAT overview"))
                            .font(AppTheme.titleFont)
                            .foregroundStyle(AppTheme.primaryText)

                        Text(localization.phrase("Review taxable revenue, VAT charged, and paid versus unpaid invoice totals per quarter."))
                            .font(AppTheme.bodyFont)
                            .foregroundStyle(AppTheme.secondaryText)
                    }

                    Spacer()

                    NavigationLink(localization.phrase("Open")) {
                        QuarterlyVATOverviewView()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accentColor)
                }
            }
        }
    }

    private var paymentRemindersCard: some View {
        let overdueSummaries = overdueInvoiceService.overdueInvoices(from: invoices)

        return SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(localization.phrase("Payment reminders"))
                            .font(AppTheme.titleFont)
                            .foregroundStyle(AppTheme.primaryText)

                        Text(localization.phrase("Track overdue invoices and prepare reminder messages before you follow up."))
                            .font(AppTheme.bodyFont)
                            .foregroundStyle(AppTheme.secondaryText)
                    }

                    Spacer()

                    NavigationLink(localization.phrase("Open")) {
                        OverdueInvoicesView(
                            invoices: invoices,
                            collaborationRules: collaborationRules
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accentColor)
                }

                if overdueSummaries.isEmpty {
                    Text(localization.phrase("All sent invoices are still within their payment term."))
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                } else {
                    ForEach(overdueSummaries.prefix(3)) { summary in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(summary.invoice.invoiceNumber)
                                    .font(AppTheme.bodyFont.weight(.semibold))
                                    .foregroundStyle(AppTheme.primaryText)
                                Text(summary.invoice.client.name)
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(summary.daysOverdue) \(localization.phrase("days overdue"))")
                                    .font(AppTheme.captionFont.weight(.semibold))
                                    .foregroundStyle(.red)
                                Text(currency(summary.invoice.totalAmount))
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                        }

                        if summary.id != overdueSummaries.prefix(3).last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private var recurringInvoicesCard: some View {
        let recurringService = RecurringInvoiceService()
        let summaries = recurringService.summaries(from: recurringTemplates)
        let dueCount = summaries.filter { !$0.dueCycleDates.isEmpty }.count

        return SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(localization.phrase("Recurring invoices"))
                            .font(AppTheme.titleFont)
                            .foregroundStyle(AppTheme.primaryText)

                        Text(localization.phrase("Save repeat billing templates and generate draft invoices for each due cycle."))
                            .font(AppTheme.bodyFont)
                            .foregroundStyle(AppTheme.secondaryText)
                    }

                    Spacer()

                    NavigationLink(localization.phrase("Open")) {
                        RecurringInvoicesView()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accentColor)
                }

                if summaries.isEmpty {
                    Text(localization.phrase("No recurring templates configured yet."))
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                } else {
                    HStack {
                        DashboardMetricCard(
                            title: localization.phrase("Templates"),
                            value: "\(recurringTemplates.count)",
                            subtitle: localization.phrase("Saved repeat billing setups"),
                            systemImage: "doc.text"
                        )
                        DashboardMetricCard(
                            title: localization.phrase("Due Now"),
                            value: "\(dueCount)",
                            subtitle: localization.phrase("Templates ready to generate"),
                            systemImage: "calendar.badge.clock"
                        )
                    }

                    ForEach(summaries.prefix(2)) { summary in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(summary.template.title)
                                    .font(AppTheme.bodyFont.weight(.semibold))
                                    .foregroundStyle(AppTheme.primaryText)
                                Text(summary.template.client.name)
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text(summary.nextPlannedDate?.formatted(date: .abbreviated, time: .omitted) ?? localization.phrase("No upcoming cycle"))
                                    .font(AppTheme.captionFont.weight(.semibold))
                                    .foregroundStyle(AppTheme.primaryText)
                                Text(summary.dueCycleDates.isEmpty ? localization.phrase("Scheduled") : "\(summary.dueCycleDates.count) \(localization.phrase("cycle(s) due"))")
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(summary.dueCycleDates.isEmpty ? AppTheme.secondaryText : .orange)
                            }
                        }
                    }
                }
            }
        }
    }

    private func workflowSuggestionCard(context: InvoiceWorkflowLaunchContext) -> some View {
        let matchingEntries = workEntries.filter { context.selectedRegistrationIDs.contains($0.id) }

        return SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(workflowBannerTitle ?? context.sourceTitle)
                    .font(AppTheme.sectionTitleFont)
                    .foregroundStyle(AppTheme.primaryText)

                Text("\(matchingEntries.count) \(localization.phrase("uninvoiced registrations are ready to be added to this draft."))")
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.secondaryText)

                HStack {
                    Button(localization.phrase("Apply Suggestions")) {
                        applyLaunchContext(context)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accentColor)

                    if !viewModel.selectedRegistrationIDs.isEmpty {
                        Button(localization.phrase("Keep Current Draft")) {
                            workflowBannerTitle = nil
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
    }

    private func quoteConversionBanner(quoteNumber: String) -> some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(localization.phrase("Quote conversion draft"))
                    .font(AppTheme.sectionTitleFont)
                    .foregroundStyle(AppTheme.primaryText)
                Text("\(localization.phrase("This invoice is being prepared from quote")) \(quoteNumber). \(localization.phrase("You can edit the lines before saving the draft invoice."))")
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }

    private func invoiceBuilderGuideCard(selectedClient: Client?, availableEntries: [WorkEntry]) -> some View {
        let hasClient = selectedClient != nil
        let hasRegistrationSelection = !viewModel.selectedRegistrationIDs.isEmpty
        let hasLines = !viewModel.lineDrafts.isEmpty
        let stepTwoComplete = viewModel.mode == .manual ? hasLines : hasRegistrationSelection

        return SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(localization.phrase("Factuur maken in 3 stappen"))
                    .font(AppTheme.titleFont)
                    .foregroundStyle(AppTheme.primaryText)

                Text(localization.phrase("Kies eerst de klant, bepaal daarna hoe je de factuur wilt opbouwen en sla het concept op zodra het totaal klopt."))
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.secondaryText)

                invoiceBuilderStep(
                    number: 1,
                    title: localization.phrase("Kies een klant"),
                    detail: hasClient ? selectedClient?.name ?? "" : localization.phrase("Selecteer een bestaande klant of maak hieronder direct een nieuwe aan."),
                    isComplete: hasClient
                )
                invoiceBuilderStep(
                    number: 2,
                    title: viewModel.mode == .manual ? localization.phrase("Voeg factuurregels toe") : localization.phrase("Selecteer werk en genereer regels"),
                    detail: viewModel.mode == .manual
                        ? localization.phrase("Handmatige modus laat je zelf regels toevoegen zonder registraties.")
                        : "\(availableEntries.count) \(localization.phrase("registraties beschikbaar in deze periode. Gebruik 'Factuur op uren en producten', 'Factuur op uren', 'Factuur op producten' of genereer regels uit registraties."))",
                    isComplete: stepTwoComplete
                )
                invoiceBuilderStep(
                    number: 3,
                    title: localization.phrase("Controleer en sla op"),
                    detail: hasLines ? localization.phrase("Controleer subtotaal, btw en vervaldatum en sla daarna het concept op.") : localization.phrase("De preview wordt automatisch bijgewerkt zodra je regels toevoegt."),
                    isComplete: viewModel.canSave
                )

                if !hasClient {
                    Text(localization.phrase("Tip: bestaat de klant nog niet, tik dan op 'Nieuwe klant' en ga meteen verder."))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.accentColor)
                }
            }
        }
    }

    private func invoiceBuilderStep(number: Int, title: String, detail: String, isComplete: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(isComplete ? AppTheme.accentColor : AppTheme.accentColor.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: isComplete ? "checkmark" : "\(number).circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isComplete ? Color.white : AppTheme.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTheme.bodyFont.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
                Text(detail)
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()
        }
    }

    private func builderConfigurationCard(selectedClient: Client?) -> some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 18) {
                Text(localization.phrase("Factuur opbouwen"))
                    .font(AppTheme.titleFont)
                    .foregroundStyle(AppTheme.primaryText)

                if let activeCompanyProfile {
                    Text("\(localization.phrase("Actief bedrijf")): \(activeCompanyProfile.name)")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                    builderStatusPill(
                        title: selectedClient == nil ? localization.phrase("Klant ontbreekt") : localization.phrase("Klant gekozen"),
                        isReady: selectedClient != nil
                    )
                    builderStatusPill(
                        title: viewModel.mode == .manual ? localization.phrase("Handmatig concept") : localization.phrase("Op basis van registraties"),
                        isReady: true
                    )
                    builderStatusPill(
                        title: viewModel.canSave ? localization.phrase("Klaar om op te slaan") : localization.phrase("Concept nog niet compleet"),
                        isReady: viewModel.canSave
                    )
                }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(localization.phrase("Manier van factureren"))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.secondaryText)

                    Picker(localization.phrase("Manier van factureren"), selection: modeBinding) {
                        ForEach(InvoiceBuilderMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(viewModel.sourceQuoteNumber != nil)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(localization.phrase("Documenttype"))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.secondaryText)

                    Picker(localization.phrase("Documenttype"), selection: documentTypeBinding) {
                        ForEach(InvoiceDocumentType.allCases) { documentType in
                            Text(localization.phrase(documentType.displayName)).tag(documentType)
                        }
                    }
                    .pickerStyle(.segmented)

                    if viewModel.documentType == .credit {
                        Text(localization.phrase("Deze creditfactuur boekt de regels en totalen negatief weg. Vul bedragen positief in; de app zet ze op de creditfactuur automatisch om."))
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.secondaryText)

                        Picker(localization.phrase("Credit op factuur"), selection: creditedInvoiceBinding) {
                            Text(localization.phrase("Geen originele factuur gekozen")).tag(nil as UUID?)
                            ForEach(creditSourceInvoices) { invoice in
                                Text("\(invoice.invoiceNumber) · \(invoice.client.name)").tag(Optional(invoice.id))
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(localization.phrase("Klant"))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.secondaryText)

                    Picker(localization.phrase("Klant"), selection: selectedClientBinding) {
                        Text(localization.phrase("Kies een klant")).tag(nil as UUID?)
                        ForEach(clients) { client in
                            Text(client.name).tag(Optional(client.id))
                        }
                    }
                    .disabled(viewModel.sourceQuoteNumber != nil)
                }

                if let selectedClient {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(localization.phrase("Standaard uurtarief klant"))
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.secondaryText)

                        TextField(localization.phrase("Bijvoorbeeld 85"), text: clientHourlyRateBinding)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)

                        Button(localization.phrase("Bewaar uurtarief voor klant")) {
                            saveSelectedClientHourlyRate(selectedClient)
                        }
                        .buttonStyle(.bordered)

                        if selectedClient.defaultHourlyRate > 0 {
                            Text("\(localization.phrase("Huidig tarief")): \(currencyRate(selectedClient.defaultHourlyRate)) / \(localization.phrase("uur"))")
                                .font(AppTheme.captionFont)
                                .foregroundStyle(AppTheme.secondaryText)
                        } else {
                            Text(localization.phrase("Er staat nog geen standaard uurtarief op deze klant. Zonder tarief blijft urenfacturatie op € 0,00 staan."))
                                .font(AppTheme.captionFont)
                                .foregroundStyle(.orange)
                        }

                        if hasSelectedZeroRateEntries {
                            Text(localization.phrase("Een deel van de gekozen registraties heeft nog geen uurtarief of productprijs. Zet hier eerst een tarief op de klant, of bewerk de registratie met een aangepast uurtarief."))
                                .font(AppTheme.captionFont)
                                .foregroundStyle(.orange)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(localization.phrase("Factuurgegevens"))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.secondaryText)

                    DatePicker(localization.phrase("Factuurdatum"), selection: invoiceDateBinding, displayedComponents: .date)
                        .onChange(of: viewModel.invoiceDate) { _, _ in
                            viewModel.updateDueDate(for: selectedClient)
                        }
                    DatePicker(localization.phrase("Vervaldatum"), selection: dueDateBinding, displayedComponents: .date)
                }

                TextField(localization.phrase("Notities op factuur"), text: invoiceNotesBinding, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)

                if viewModel.mode != .manual {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(localization.phrase("Periode voor registraties"))
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.secondaryText)

                        DatePicker(localization.phrase("Van"), selection: startDateBinding, displayedComponents: .date)
                        DatePicker(localization.phrase("Tot"), selection: endDateBinding, displayedComponents: .date)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(localization.phrase("Registraties groeperen"))
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.secondaryText)

                        Picker(localization.phrase("Registraties groeperen"), selection: groupingModeBinding) {
                        ForEach(InvoiceGroupingMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    }

                    if viewModel.groupingMode == .hours {
                        Text(localization.phrase("Hiermee maak je direct factuurregels op basis van gelogde uren en het uurtarief per registratie. Producten zonder uureenheid blijven op productprijs en aantal."))
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.secondaryText)
                    } else if viewModel.groupingMode == .hoursAndProducts {
                        Text(localization.phrase("Hiermee combineer je uurregels voor werkzaamheden met aparte productregels voor materialen en aantallen. Dit is de aanbevolen modus voor gemengde facturen."))
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.secondaryText)
                    } else if viewModel.groupingMode == .product {
                        Text(localization.phrase("Hiermee maak je factuurregels op basis van productprijs en aantal per registratie, zonder terug te vallen op uren."))
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(localization.phrase("Acties"))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.secondaryText)

                    Button(localization.phrase("Nieuwe klant")) {
                        isPresentingClientForm = true
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.sourceQuoteNumber != nil)

                    Menu(localization.phrase("Regel toevoegen")) {
                        ForEach(InvoiceLineKind.allCases) { kind in
                            Button(localization.phrase(kind.title)) {
                                viewModel.addLine(kind: kind)
                            }
                        }
                    }
                    .buttonStyle(.bordered)

                    Button(localization.phrase("Factuur per periode")) {
                        isPresentingPeriodWorkflow = true
                    }
                    .buttonStyle(.bordered)

                    if viewModel.selectedClientID != nil {
                        Button(localization.phrase("Factuur op uren en producten")) {
                            viewModel.mode = .automatic
                            viewModel.groupingMode = .hoursAndProducts
                            refreshAutomaticDraft(selectAllIfNeeded: true)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.accentColor)

                        Button(localization.phrase("Factuur op uren")) {
                            viewModel.mode = .automatic
                            viewModel.groupingMode = .hours
                            refreshAutomaticDraft(selectAllIfNeeded: true)
                        }
                        .buttonStyle(.bordered)

                        Button(localization.phrase("Factuur op producten")) {
                            viewModel.mode = .automatic
                            viewModel.groupingMode = .product
                            refreshAutomaticDraft(selectAllIfNeeded: true)
                        }
                        .buttonStyle(.bordered)
                    }

                    if viewModel.mode != .manual {
                        Button(localization.phrase("Genereer regels uit registraties")) {
                            refreshAutomaticDraft(selectAllIfNeeded: true)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.accentColor)
                        .disabled(!viewModel.canGenerateAutomaticLines)
                    }
                }
            }
        }
    }

    private func builderStatusPill(title: String, isReady: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: isReady ? "checkmark.circle.fill" : "circle.dashed")
            Text(title)
        }
        .font(AppTheme.captionFont.weight(.semibold))
        .foregroundStyle(isReady ? AppTheme.accentColor : AppTheme.secondaryText)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background((isReady ? AppTheme.accentColor.opacity(0.12) : AppTheme.secondaryText.opacity(0.08)), in: Capsule())
    }

    private func registrationsSelectionCard(entries: [WorkEntry]) -> some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(localization.phrase("Registraties"))
                            .font(AppTheme.sectionTitleFont)
                            .foregroundStyle(AppTheme.primaryText)
                        Text("\(viewModel.selectedRegistrationIDs.count) \(localization.phrase("geselecteerd"))")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.secondaryText)
                    }

                    Spacer()

                    if viewModel.mode != .manual, !entries.isEmpty {
                        Button(localization.phrase("Alles")) {
                            viewModel.selectedRegistrationIDs = Set(entries.map(\.id))
                            refreshAutomaticDraft(using: entries)
                        }
                        .buttonStyle(.bordered)

                        Button(localization.phrase("Leeg")) {
                            viewModel.selectedRegistrationIDs.removeAll()
                            refreshAutomaticDraft(using: entries)
                        }
                        .buttonStyle(.bordered)
                    }
                }

                if viewModel.mode == .manual {
                    Text(localization.phrase("In handmatige modus worden registraties niet automatisch meegenomen."))
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                } else if entries.isEmpty {
                    Text(localization.phrase("Geen registraties beschikbaar in de gekozen periode."))
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                } else {
                    if hasSelectedZeroRateEntries {
                        Text(localization.phrase("Geselecteerde registraties zonder tarief worden nu als € 0,00 berekend. Stel eerst een klanttarief of aangepast uurtarief in."))
                            .font(AppTheme.bodyFont)
                            .foregroundStyle(.orange)
                    }

                    ForEach(entries) { entry in
                        let quantityText: String = {
                            if let product = entry.product, product.unitType != .hour {
                                return "\(entry.quantity.formatted(.number.precision(.fractionLength(0...2)))) \(product.unitType.displayName.lowercased())"
                            }

                            return "\(entry.hoursWorked.formatted(.number.precision(.fractionLength(0...2)))) h"
                        }()

                        Button {
                            viewModel.toggleRegistration(entry)
                            refreshAutomaticDraft(using: entries)
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: viewModel.selectedRegistrationIDs.contains(entry.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(viewModel.selectedRegistrationIDs.contains(entry.id) ? AppTheme.accentColor : AppTheme.secondaryText)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.client.name)
                                        .font(AppTheme.bodyFont.weight(.semibold))
                                        .foregroundStyle(AppTheme.primaryText)

                                    Text(entry.product?.name ?? "Algemeen werk")
                                        .font(AppTheme.captionFont)
                                        .foregroundStyle(AppTheme.secondaryText)

                                    Text(AppFormatters.mediumDateFormatter.string(from: entry.date))
                                        .font(AppTheme.captionFont)
                                        .foregroundStyle(AppTheme.secondaryText)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(quantityText)
                                        .font(AppTheme.bodyFont.weight(.semibold))
                                        .foregroundStyle(AppTheme.primaryText)

                                    Text(entry.billableAmount.formatted(.currency(code: Locale.current.currency?.identifier ?? "EUR")))
                                        .font(AppTheme.captionFont)
                                        .foregroundStyle(AppTheme.secondaryText)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if entry.id != entries.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private var invoiceLinesCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text(localization.phrase("Factuurregels"))
                        .font(AppTheme.sectionTitleFont)
                        .foregroundStyle(AppTheme.primaryText)

                    Spacer()

                    Text(viewModel.canSaveDraft ? "Concept kan worden opgeslagen" : "Maak eerst het concept af")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(viewModel.canSaveDraft ? AppTheme.accentColor : AppTheme.secondaryText)

                    Button(localization.phrase("Concept opslaan")) {
                        saveInvoice()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accentColor)
                    .disabled(!viewModel.canSaveDraft)
                }

                if viewModel.lineDrafts.isEmpty {
                    Text(localization.phrase("Voeg zelf regels toe of genereer ze uit de geselecteerde registraties."))
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                } else {
                    ForEach(viewModel.lineDrafts) { line in
                        invoiceLineEditor(line: line)

                        if line.id != viewModel.lineDrafts.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private func invoiceTotalsCard(totals: InvoiceDraftTotals, collaborationRule: CollaborationRule?) -> some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(localization.text(.preview))
                    .font(AppTheme.sectionTitleFont)
                    .foregroundStyle(AppTheme.primaryText)

                amountRow(title: localization.text(.subtotal), value: currency(totals.subtotal))
                amountRow(title: localization.text(.extraCharges), value: currency(totals.extraCharges))
                amountRow(title: localization.text(.travelCosts), value: currency(totals.travelCosts))
                amountRow(title: localization.text(.materialCosts), value: currency(totals.materialCosts))
                amountRow(title: localization.text(.manualAdjustments), value: currency(totals.manualAdjustments))
                amountRow(title: localization.text(.gross), value: currency(totals.gross))
                amountRow(title: localization.phrase("Kortingen"), value: currency(-totals.discounts))
                amountRow(title: localization.text(.netSubtotal), value: currency(totals.netSubtotal))
                amountRow(title: localization.text(.vat), value: currency(totals.vat))
                amountRow(title: localization.text(.total), value: currency(totals.total), emphasize: true)

                if !totals.vatBreakdown.isEmpty {
                    Divider()

                    Text(localization.phrase("Btw-overzicht"))
                        .font(AppTheme.bodyFont.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)

                    ForEach(totals.vatBreakdown) { item in
                        amountRow(
                            title: "\(item.rate.formatted(.number.precision(.fractionLength(0...2))))% \(localization.phrase("on")) \(currency(item.taxableAmount))",
                            value: currency(item.vatAmount)
                        )
                    }
                }

                if let collaborationRule {
                    Divider()
                    amountRow(title: "\(localization.phrase("Partner share")) (\(collaborationRule.partnerName))", value: currency(totals.partnerShare))
                    amountRow(title: localization.phrase("Netto inkomen"), value: currency(totals.netIncome), emphasize: true)
                }
            }
        }
    }

    private var savedInvoicesCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 18) {
                Text(localization.phrase("All invoices"))
                    .font(AppTheme.sectionTitleFont)
                    .foregroundStyle(AppTheme.primaryText)

                if historyViewModel.filteredInvoices.isEmpty {
                    Text(localization.phrase("No invoices match the current filters."))
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                } else {
                    invoiceSection(title: "Open", invoices: openInvoices)
                    invoiceSection(title: "Overdue", invoices: overdueInvoices)
                    invoiceSection(title: "Paid", invoices: paidInvoices)
                }
            }
        }
    }

    @ViewBuilder
    private func invoiceSection(title: String, invoices: [Invoice]) -> some View {
        if !invoices.isEmpty {
            Text(localization.phrase(title))
                .font(AppTheme.bodyFont.weight(.semibold))
                .foregroundStyle(AppTheme.primaryText)

            ForEach(invoices) { invoice in
                HStack(spacing: 12) {
                    NavigationLink {
                        InvoicePreviewView(
                            invoice: invoice,
                            collaborationRule: collaborationRules.first(where: { $0.client?.id == invoice.client.id })
                        )
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text(invoice.invoiceNumber)
                                        .font(AppTheme.bodyFont.weight(.semibold))
                                        .foregroundStyle(AppTheme.primaryText)

                                    if invoice.isCreditInvoice {
                                        creditInvoiceBadge
                                    }
                                }

                                Text(invoice.client.name)
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.secondaryText)

                                if invoice.isCreditInvoice, !invoice.creditedInvoiceNumber.isEmpty {
                                    Text("\(localization.phrase("Credit op factuur")) \(invoice.creditedInvoiceNumber)")
                                        .font(AppTheme.captionFont)
                                        .foregroundStyle(AppTheme.secondaryText)
                                }
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text(currency(invoice.totalAmount))
                                    .font(AppTheme.bodyFont.weight(.semibold))
                                    .foregroundStyle(AppTheme.primaryText)

                                Text(localization.phrase(repository.normalizedStatus(for: invoice).displayName))
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    Button {
                        toggleInvoicePaidState(invoice)
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: repository.normalizedStatus(for: invoice) == .paid ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                            Text(
                                localization.phrase(
                                    repository.normalizedStatus(for: invoice) == .paid ? "Paid" : "Open"
                                )
                            )
                                .font(AppTheme.captionFont.weight(.semibold))
                        }
                        .foregroundStyle(repository.normalizedStatus(for: invoice) == .paid ? .green : AppTheme.secondaryText)
                        .frame(minWidth: 54)
                    }
                    .buttonStyle(.plain)
                }

                if invoice.id != invoices.last?.id {
                    Divider()
                }
            }
        }
    }

    private func invoiceLineEditor(line: InvoiceLineDraft) -> some View {
        let calculation = viewModel.lineCalculation(for: line)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(line.kind.title)
                    .font(AppTheme.captionFont.weight(.semibold))
                    .foregroundStyle(AppTheme.accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.accentColor.opacity(0.12), in: Capsule())

                Spacer()
            }

            if line.kind == .productService {
                Picker(
                    localization.phrase("Product"),
                    selection: Binding(
                        get: { viewModel.lineDraft(id: line.id)?.linkedProductID ?? line.linkedProductID },
                        set: { selectedProductID in
                            guard let selectedProductID,
                                  let product = products.first(where: { $0.id == selectedProductID }) else {
                                viewModel.clearLinkedProduct(forLineWithID: line.id)
                                return
                            }

                            viewModel.applyProduct(product, toLineWithID: line.id)
                        }
                    )
                ) {
                    Text(localization.phrase("Tijdelijk product")).tag(nil as UUID?)

                    ForEach(products) { product in
                        Text(product.name).tag(Optional(product.id))
                    }
                }

                if (viewModel.lineDraft(id: line.id)?.linkedProductID ?? line.linkedProductID) == nil {
                    Text(localization.phrase("Gebruik tijdelijk product als deze factuurregel niet in je productlijst hoeft te worden opgeslagen."))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }

            TextField(
                localization.phrase("Beschrijving"),
                text: Binding(
                    get: { viewModel.lineDraft(id: line.id)?.description ?? line.description },
                    set: { newDescription in
                        viewModel.updateLine(id: line.id) { draft in
                            draft.description = newDescription
                        }
                    }
                )
            )

            HStack(spacing: 12) {
                numericField(title: "Aantal", value: line.quantity) { value in
                    viewModel.updateLine(id: line.id) { $0.quantity = value }
                }

                numericField(title: "Prijs per stuk", value: line.unitPrice) { value in
                    viewModel.updateLine(id: line.id) { $0.unitPrice = value }
                }

                numericField(title: "Btw %", value: line.vatRate) { value in
                    viewModel.updateLine(id: line.id) { $0.vatRate = value }
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(localization.phrase("Netto"))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.secondaryText)
                    Text(currency(calculation.netAmount))
                        .font(AppTheme.bodyFont.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(localization.phrase("Btw"))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.secondaryText)
                    Text(currency(calculation.vatAmount))
                        .font(AppTheme.bodyFont.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(localization.phrase("Bruto"))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.secondaryText)
                    Text(currency(calculation.grossAmount))
                        .font(AppTheme.bodyFont.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)
                }

                Button {
                    viewModel.removeLine(id: line.id)
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private var creditInvoiceBadge: some View {
        Text(localization.phrase("Creditfactuur"))
            .font(AppTheme.captionFont.weight(.semibold))
            .foregroundStyle(.purple)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.purple.opacity(0.12), in: Capsule())
    }

    private func numericField(title: String, value: Double, onChange: @escaping (Double) -> Void) -> some View {
        TextField(
            title,
            value: Binding(
                get: { value },
                set: onChange
            ),
            format: .number.precision(.fractionLength(0...2))
        )
        .keyboardType(.decimalPad)
    }

    @ViewBuilder
    private func amountRow(title: String, value: String, emphasize: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(emphasize ? AppTheme.sectionTitleFont : AppTheme.bodyFont)
                .foregroundStyle(emphasize ? AppTheme.primaryText : AppTheme.secondaryText)

            Spacer()

            Text(value)
                .font(emphasize ? AppTheme.sectionTitleFont : AppTheme.bodyFont)
                .foregroundStyle(AppTheme.primaryText)
        }
    }

    private func saveInvoice() {
        do {
            let savedInvoice = try viewModel.saveInvoice(
                in: modelContext,
                clients: clients,
                workEntries: workEntries,
                existingInvoices: invoices,
                quotes: quotes,
                companyProfiles: companyProfiles,
                activeCompanyProfile: activeCompanyProfile,
                collaborationRule: collaborationRules.first(where: { $0.client?.id == currentSelectedClient?.id }),
                invoiceNumberPrefix: appSettings.first?.invoiceNumberPrefix ?? "",
                creditInvoiceNumberPrefix: appSettings.first?.creditInvoiceNumberPrefix ?? "CR",
                invoiceNumberSequencePadding: appSettings.first?.invoiceNumberSequencePadding ?? 3
            )
            rememberRecentlySavedInvoice(savedInvoice)
            refreshInvoiceHistory()
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    private func applyPendingWorkflowIfNeeded() {
        guard let context = appViewModel.consumeInvoiceWorkflow() else { return }
        applyLaunchContext(context)
    }

    private func handleAppear() {
        let availableEntries = viewModel.availableRegistrations(from: workEntries)
        viewModel.apply(settings: appSettings.first)
        viewModel.syncSelection(with: availableEntries)
        clientHourlyRateText = currentSelectedClient.map { formatHourlyRate($0.defaultHourlyRate) } ?? ""
        refreshInvoiceHistory()
        applyPendingWorkflowIfNeeded()
        applyPendingQuoteConversionIfNeeded()
        applyPendingWeeklyReviewIfNeeded()
    }

    private func applyPendingWeeklyReviewIfNeeded() {
        guard let date = appViewModel.consumeWeeklyInvoiceReviewDate() else { return }
        periodWorkflowReferenceDate = date
        isPresentingPeriodWorkflow = true
    }

    private func applyPendingQuoteConversionIfNeeded() {
        guard let draftContext = appViewModel.consumeQuoteConversionWorkflow() else { return }
        viewModel.applyQuoteConversionDraft(draftContext)
        workflowBannerTitle = nil
    }

    private func applyLaunchContext(_ context: InvoiceWorkflowLaunchContext) {
        let appliedEntries = viewModel.applyWorkflowContext(context, workEntries: workEntries)
        if appliedEntries.isEmpty {
            saveErrorMessage = "No eligible registrations were available for that workflow."
            workflowBannerTitle = nil
            return
        }

        workflowBannerTitle = "Prepared from \(context.sourceTitle.lowercased())"
    }

    private func currency(_ value: Double) -> String {
        value.formatted(.currency(code: Locale.current.currency?.identifier ?? "EUR"))
    }

    private func refreshAutomaticDraft(using entries: [WorkEntry]? = nil, selectAllIfNeeded: Bool = false) {
        guard viewModel.mode != .manual else { return }

        let availableEntries = entries ?? viewModel.availableRegistrations(from: workEntries)
        if selectAllIfNeeded, viewModel.selectedRegistrationIDs.isEmpty {
            viewModel.selectedRegistrationIDs = Set(availableEntries.map(\.id))
        }

        viewModel.syncSelectedClient(with: availableEntries)
        viewModel.updateDueDate(for: currentSelectedClient)
        viewModel.generateAutomaticLines(from: availableEntries)
    }

    private func markInvoiceAsPaid(_ invoice: Invoice) {
        repository.markAsPaid(invoice)
        try? modelContext.save()
        refreshInvoiceHistory()
    }

    private func toggleInvoicePaidState(_ invoice: Invoice) {
        if repository.normalizedStatus(for: invoice) == .paid {
            markInvoiceAsUnpaid(invoice)
        } else {
            markInvoiceAsPaid(invoice)
        }
    }

    private func markInvoiceAsUnpaid(_ invoice: Invoice) {
        if invoice.emailSentAt != nil {
            repository.markAsSent(invoice)
        } else {
            repository.persistStatus(.draft, on: invoice)
        }

        try? modelContext.save()
        refreshInvoiceHistory()
    }

    private func rememberRecentlySavedInvoice(_ invoice: Invoice) {
        recentlySavedInvoices.removeAll { $0.id == invoice.id }
        recentlySavedInvoices.insert(invoice, at: 0)
    }

    private func refreshInvoiceHistory() {
        pruneRecentlySavedInvoices()
        historyViewModel.refresh(with: invoicesIncludingRecentlySaved)
    }

    private func pruneRecentlySavedInvoices() {
        let invoiceIDs = Set(invoices.map(\.id))
        recentlySavedInvoices.removeAll { invoiceIDs.contains($0.id) }
    }

    private var invoicesIncludingRecentlySaved: [Invoice] {
        var seenIDs = Set<UUID>()
        return (recentlySavedInvoices + invoices).filter { invoice in
            seenIDs.insert(invoice.id).inserted
        }
    }

    private func currencyRate(_ value: Double) -> String {
        "\(currency(value))"
    }

    private var hasSelectedZeroRateEntries: Bool {
        let availableEntries = viewModel.availableRegistrations(from: workEntries)
        return availableEntries.contains { entry in
            viewModel.selectedRegistrationIDs.contains(entry.id) && entry.billableAmount == 0
        }
    }

    private var clientHourlyRateBinding: Binding<String> {
        Binding(
            get: { clientHourlyRateText },
            set: { clientHourlyRateText = $0 }
        )
    }

    private func saveSelectedClientHourlyRate(_ client: Client) {
        guard let parsedRate = parseHourlyRate(clientHourlyRateText) else {
            saveErrorMessage = "Vul een geldig uurtarief in."
            return
        }

        client.defaultHourlyRate = max(0, parsedRate)
        try? modelContext.save()
        clientHourlyRateText = formatHourlyRate(client.defaultHourlyRate)
        refreshAutomaticDraft(selectAllIfNeeded: true)
    }

    private func formatHourlyRate(_ value: Double) -> String {
        AppFormatters.decimalFormatter(maximumFractionDigits: 2).string(from: NSNumber(value: value)) ?? ""
    }

    private func parseHourlyRate(_ value: String) -> Double? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return 0
        }

        let formatter = AppFormatters.decimalFormatter(maximumFractionDigits: 2)
        if let number = formatter.number(from: trimmed) {
            return number.doubleValue
        }

        let alternateSeparator = formatter.decimalSeparator == "," ? "." : ","
        let normalized = trimmed.replacingOccurrences(of: alternateSeparator, with: formatter.decimalSeparator)
        return formatter.number(from: normalized)?.doubleValue
    }

    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ]
    }

    private var currentSelectedClient: Client? {
        clients.first(where: { $0.id == viewModel.selectedClientID })
    }

    private var activeCompanyProfile: CompanyProfile? {
        CompanyProfileSelectionService().activeProfile(from: companyProfiles, settings: appSettings.first)
    }

    private var localization: AppLocalization {
        AppLocalization(localeIdentifier: appSettings.first?.preferredLocaleIdentifier)
    }

    private func isModuleEnabled(_ module: AppModule) -> Bool {
        workModeService.isModuleEnabled(
            module,
            settings: appSettings.first,
            moduleConfiguration: moduleConfigurations.first
        )
    }

    private var pendingWorkflowFingerprint: String {
        [
            appViewModel.pendingInvoiceWorkflowRequestID.uuidString,
            appViewModel.pendingInvoiceWorkflow?.fingerprint ?? ""
        ].joined(separator: "|")
    }

    private var pendingQuoteConversionFingerprint: String {
        appViewModel.pendingQuoteConversion?.fingerprint ?? ""
    }

    private var pendingWeeklyReviewFingerprint: Double {
        appViewModel.pendingWeeklyReviewDate?.timeIntervalSince1970 ?? 0
    }

    private var settingsDefaultsFingerprint: String {
        let settings = appSettings.first
        return [
            String(settings?.defaultPaymentTermDays ?? 30),
            String(settings?.defaultVATRate ?? 21)
        ].joined(separator: "|")
    }

    private var invoiceHistoryFingerprint: String {
        invoices
            .map {
                [
                    $0.id.uuidString,
                    $0.invoiceNumber,
                    $0.status.rawValue,
                    String($0.totalAmount),
                    String($0.date.timeIntervalSince1970),
                    String($0.dueDate.timeIntervalSince1970)
                ].joined(separator: ":")
            }
            .joined(separator: "|")
    }

    private var modeBinding: Binding<InvoiceBuilderMode> {
        Binding(
            get: { viewModel.mode },
            set: { newValue in
                guard viewModel.mode != newValue else { return }

                switch newValue {
                case .manual:
                    viewModel.mode = .manual
                    viewModel.selectedRegistrationIDs.removeAll()
                    viewModel.lineDrafts.removeAll { !$0.linkedWorkEntryIDs.isEmpty }
                case .mixed:
                    viewModel.mode = .mixed
                case .automatic:
                    viewModel.mode = .automatic
                    let availableEntries = viewModel.availableRegistrations(from: workEntries)
                    viewModel.syncSelection(with: availableEntries)
                    refreshAutomaticDraft(using: availableEntries, selectAllIfNeeded: true)
                }
            }
        )
    }

    private var selectedClientBinding: Binding<UUID?> {
        Binding(
            get: { viewModel.selectedClientID },
            set: { viewModel.selectedClientID = $0 }
        )
    }

    private var startDateBinding: Binding<Date> {
        Binding(
            get: { viewModel.startDate },
            set: { viewModel.startDate = $0 }
        )
    }

    private var endDateBinding: Binding<Date> {
        Binding(
            get: { viewModel.endDate },
            set: { viewModel.endDate = $0 }
        )
    }

    private var invoiceDateBinding: Binding<Date> {
        Binding(
            get: { viewModel.invoiceDate },
            set: { viewModel.invoiceDate = $0 }
        )
    }

    private var dueDateBinding: Binding<Date> {
        Binding(
            get: { viewModel.dueDate },
            set: { viewModel.dueDate = $0 }
        )
    }

    private var groupingModeBinding: Binding<InvoiceGroupingMode> {
        Binding(
            get: { viewModel.groupingMode },
            set: { viewModel.groupingMode = $0 }
        )
    }

    private var documentTypeBinding: Binding<InvoiceDocumentType> {
        Binding(
            get: { viewModel.documentType },
            set: {
                viewModel.documentType = $0
                if $0 != .credit {
                    viewModel.creditedInvoiceID = nil
                }
            }
        )
    }

    private var creditedInvoiceBinding: Binding<UUID?> {
        Binding(
            get: { viewModel.creditedInvoiceID },
            set: { viewModel.creditedInvoiceID = $0 }
        )
    }

    private var invoiceNotesBinding: Binding<String> {
        Binding(
            get: { viewModel.invoiceNotes },
            set: { viewModel.invoiceNotes = $0 }
        )
    }

    private var saveErrorBinding: Binding<Bool> {
        Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )
    }

    private var invoiceSearchBinding: Binding<String> {
        Binding(
            get: { historyViewModel.searchText },
            set: { historyViewModel.searchText = $0 }
        )
    }

    private var invoiceHistoryStartDateBinding: Binding<Date> {
        Binding(
            get: { historyViewModel.startDate ?? .now },
            set: { historyViewModel.startDate = $0 }
        )
    }

    private var invoiceHistoryEndDateBinding: Binding<Date> {
        Binding(
            get: { historyViewModel.endDate ?? .now },
            set: { historyViewModel.endDate = $0 }
        )
    }

    private var openInvoices: [Invoice] {
        historyViewModel.filteredInvoices.filter {
            let status = repository.normalizedStatus(for: $0)
            return status == .draft || status == .sent
        }
    }

    private var overdueInvoices: [Invoice] {
        historyViewModel.filteredInvoices.filter { repository.normalizedStatus(for: $0) == .overdue }
    }

    private var paidInvoices: [Invoice] {
        historyViewModel.filteredInvoices.filter { repository.normalizedStatus(for: $0) == .paid }
    }

    private var creditSourceInvoices: [Invoice] {
        invoices
            .filter { !$0.isCreditInvoice }
            .filter { invoice in
                guard let selectedClientID = viewModel.selectedClientID else { return true }
                return invoice.client.id == selectedClientID
            }
            .sorted { $0.date > $1.date }
    }

}

#Preview {
    NavigationStack {
        InvoiceGeneratorView()
            .modelContainer(DashboardPreviewData.makeContainer())
    }
}
