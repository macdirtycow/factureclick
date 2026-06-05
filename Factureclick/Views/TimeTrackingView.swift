//
//  TimeTrackingView.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import SwiftData
import SwiftUI

struct TimeTrackingView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \WorkEntry.date, order: .reverse) private var workEntries: [WorkEntry]
    @Query(sort: \Client.name) private var clients: [Client]
    @Query private var appSettings: [AppSettings]
    @Query private var moduleConfigurations: [ModuleVisibilityConfiguration]

    @State private var viewModel = TimeTrackingViewModel()
    @State private var historyViewModel = RegistrationHistoryViewModel()
    @State private var isPresentingWorkEntryForm = false
    @State private var signatureTarget: WorkEntry?
    @State private var workflowErrorMessage: String?
    @State private var entryPendingDeletion: WorkEntry?
    @State private var deleteErrorMessage: String?

    private let invoiceRepository = InvoiceRepository()
    private let timeTrackingRepository = TimeTrackingRepository()
    private let signatureService = SignaturePersistenceService()
    private let workModeService = WorkModeConfigurationService()

    var body: some View {
        ScrollView {
            content
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(AppTheme.screenBackground.ignoresSafeArea())
        .navigationTitle(localization.phrase("Registrations"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if hasRegistrationTools {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingWorkEntryForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $isPresentingWorkEntryForm) {
            NavigationStack {
                WorkEntryFormView(selectedDate: .now)
            }
        }
        .sheet(item: $signatureTarget) { entry in
            NavigationStack {
                SignatureCaptureView(title: localization.phrase("Work Confirmation"), existingSignature: entry.customerSignature) { draft in
                    try signatureService.upsertSignature(draft, for: entry, in: modelContext)
                }
            }
        }
        .task(id: refreshToken) {
            viewModel.refresh(with: workEntries)
            historyViewModel.refresh(with: workEntries)
        }
        .onChange(of: viewModel.invoicePeriodStartDate) { _, _ in
            viewModel.refresh(with: workEntries)
        }
        .onChange(of: viewModel.invoicePeriodEndDate) { _, _ in
            viewModel.refresh(with: workEntries)
        }
        .onChange(of: historyViewModel.searchText) { _, _ in
            historyViewModel.refresh(with: workEntries)
        }
        .onChange(of: historyViewModel.selectedClientID) { _, _ in
            historyViewModel.refresh(with: workEntries)
        }
        .onChange(of: historyViewModel.selectedFilter) { _, _ in
            historyViewModel.refresh(with: workEntries)
        }
        .onChange(of: appViewModel.shouldPresentWorkEntryForm) { _, shouldPresent in
            guard shouldPresent, appViewModel.selectedTab == .registrations else { return }
            appViewModel.shouldPresentWorkEntryForm = false
            isPresentingWorkEntryForm = true
        }
        .alert(localization.phrase("Factuur"), isPresented: workflowErrorBinding) {
            Button(localization.phrase("OK"), role: .cancel) { }
        } message: {
            Text(workflowErrorMessage ?? "")
        }
        .alert(localization.phrase("Delete Registration"), isPresented: deleteAlertBinding) {
            Button(localization.phrase("Delete"), role: .destructive) {
                deletePendingEntry()
            }
            Button(localization.phrase("Cancel"), role: .cancel) { }
        } message: {
            Text(localization.phrase("This registration will be removed permanently."))
        }
        .alert(localization.phrase("Unable to Delete Registration"), isPresented: deleteErrorBinding) {
            Button(localization.phrase("OK"), role: .cancel) { }
        } message: {
            Text(deleteErrorMessage ?? "")
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 24) {
            if hasRegistrationTools {
                weeklySummaryCard
                invoicePeriodCard(invoiceSuggestion: invoiceSuggestion)
            }
            if isModuleEnabled(.mileageTracking) {
                mileageTrackingCard
            }
            if isModuleEnabled(.receipts) {
                receiptStorageCard
            }
            if hasRegistrationTools {
                RevenueSplitCard(title: localization.phrase("Weekly split"), summary: viewModel.weeklyCollaborationSummary, localization: localization)
                RevenueSplitCard(title: localization.phrase("Invoice period split"), summary: viewModel.invoicePeriodCollaborationSummary, localization: localization)
                registrationHistoryCard
                dailySummaryCard
                clientSummaryCard
                timeLogsCard
            }
        }
    }

    private var weeklySummaryCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(localization.phrase("This week"))
                    .font(AppTheme.titleFont)
                    .foregroundStyle(AppTheme.primaryText)

                LazyVGrid(columns: summaryColumns, spacing: 14) {
                    trackingMetric(title: localization.phrase("Hours"), value: decimal(viewModel.weeklySummary.totalHours), subtitle: localization.phrase("Tracked this week"))
                    trackingMetric(title: localization.phrase("Billable"), value: decimal(viewModel.weeklySummary.billableHours), subtitle: localization.phrase("Marked for invoice"))
                    trackingMetric(title: localization.phrase("Value"), value: currency(viewModel.weeklySummary.totalAmount), subtitle: localization.phrase("Hourly billing"))
                    trackingMetric(title: localization.phrase("Pending"), value: decimal(viewModel.weeklySummary.pendingInvoiceHours), subtitle: localization.phrase("Not invoiced yet"))
                    trackingMetric(title: localization.phrase("Partner"), value: currency(viewModel.weeklySummary.partnerShare), subtitle: localization.phrase("Revenue share"))
                    trackingMetric(title: localization.phrase("Keep"), value: currency(viewModel.weeklySummary.userNetAmount), subtitle: localization.phrase("Net revenue"))
                }
            }
        }
    }

    private func invoicePeriodCard(invoiceSuggestion: InvoiceWorkflowLaunchContext?) -> some View {
        let hasInvoiceSuggestion = invoiceSuggestion != nil

        return SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(localization.phrase("Factuurperiode"))
                        .font(AppTheme.sectionTitleFont)
                        .foregroundStyle(AppTheme.primaryText)

                    Spacer()

                    if let invoiceSuggestion {
                        Button(localization.phrase("Naar factuur")) {
                            appViewModel.openInvoiceWorkflow(invoiceSuggestion)
                        }
                        .buttonStyle(.bordered)
                    }
                }

                DatePicker(localization.phrase("Van"), selection: invoicePeriodStartBinding, displayedComponents: .date)
                DatePicker(localization.phrase("Tot"), selection: invoicePeriodEndBinding, displayedComponents: .date)

                LazyVGrid(columns: summaryColumns, spacing: 14) {
                    trackingMetric(title: localization.phrase("Uren"), value: decimal(viewModel.invoicePeriodSummary.totalHours), subtitle: localization.phrase("Binnen deze selectie"))
                    trackingMetric(title: localization.phrase("Factureerbaar"), value: decimal(viewModel.invoicePeriodSummary.billableHours), subtitle: localization.phrase("Klaar voor factuur"))
                    trackingMetric(title: localization.phrase("Waarde"), value: currency(viewModel.invoicePeriodSummary.totalAmount), subtitle: localization.phrase("Op basis van tarief"))
                    trackingMetric(title: localization.phrase("Open"), value: decimal(viewModel.invoicePeriodSummary.pendingInvoiceHours), subtitle: localization.phrase("Nog niet gefactureerd"))
                    trackingMetric(title: localization.phrase("Partner"), value: currency(viewModel.invoicePeriodSummary.partnerShare), subtitle: localization.phrase("Verdeling"))
                    trackingMetric(title: localization.phrase("Jij houdt"), value: currency(viewModel.invoicePeriodSummary.userNetAmount), subtitle: localization.phrase("Netto na verdeling"))
                }

                if hasInvoiceSuggestion {
                    Text(localization.phrase("Gebruik 'Naar factuur' om deze registraties direct in het factuurtabblad klaar te zetten."))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
    }

    private var registrationHistoryCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(localization.phrase("Registration history"))
                    .font(AppTheme.sectionTitleFont)
                    .foregroundStyle(AppTheme.primaryText)

                TextField(localization.phrase("Search registrations"), text: historySearchBinding)
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
                        ForEach(RegistrationDateFilter.allCases) { filter in
                            FilterChip(title: localization.phrase(filter.title), isSelected: historyViewModel.selectedFilter == filter) {
                                historyViewModel.selectedFilter = filter
                            }
                        }
                    }
                }

                LazyVGrid(columns: summaryColumns, spacing: 14) {
                    trackingMetric(title: localization.phrase("Shown"), value: "\(historyViewModel.filteredEntries.count)", subtitle: localization.phrase("Matching logs"))
                    trackingMetric(title: localization.phrase("Hours"), value: decimal(historyViewModel.filteredSummary.totalHours), subtitle: localization.phrase("Filtered hours"))
                    trackingMetric(title: localization.phrase("Revenue"), value: currency(historyViewModel.filteredSummary.totalAmount), subtitle: localization.phrase("Filtered value"))
                    trackingMetric(title: localization.phrase("Open"), value: decimal(historyViewModel.filteredSummary.pendingInvoiceHours), subtitle: localization.phrase("Still open"))
                }
            }
        }
    }

    private var mileageTrackingCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(localization.phrase("Mileage tracking"))
                            .font(AppTheme.sectionTitleFont)
                            .foregroundStyle(AppTheme.primaryText)

                        Text(localization.phrase("Track trips, reimbursement costs, and optionally link them to invoices."))
                            .font(AppTheme.bodyFont)
                            .foregroundStyle(AppTheme.secondaryText)
                    }

                    Spacer()

                    NavigationLink(localization.phrase("Open")) {
                        MileageTrackingView()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accentColor)
                }
            }
        }
    }

    private var receiptStorageCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(localization.phrase("Receipt storage"))
                            .font(AppTheme.sectionTitleFont)
                            .foregroundStyle(AppTheme.primaryText)

                        Text(localization.phrase("Keep expense proofs, receipt photos, and billing context organized in one place."))
                            .font(AppTheme.bodyFont)
                            .foregroundStyle(AppTheme.secondaryText)
                    }

                    Spacer()

                    NavigationLink(localization.phrase("Open")) {
                        ReceiptListView()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accentColor)
                }
            }
        }
    }

    private var dailySummaryCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(localization.phrase("By day"))
                    .font(AppTheme.sectionTitleFont)
                    .foregroundStyle(AppTheme.primaryText)

                if viewModel.dailySummaries.isEmpty {
                    emptyState(localization.phrase("No time logs in the selected invoice period."))
                } else {
                    ForEach(viewModel.dailySummaries) { summary in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(AppFormatters.mediumDateFormatter.string(from: summary.date))
                                    .font(AppTheme.bodyFont.weight(.semibold))
                                    .foregroundStyle(AppTheme.primaryText)

                                Text(entryCountText(summary.entryCount, plural: "entries"))
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(decimal(summary.totalHours)) h")
                                    .font(AppTheme.bodyFont.weight(.semibold))
                                    .foregroundStyle(AppTheme.primaryText)

                                Text(currency(summary.totalAmount))
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.secondaryText)

                                Text(netAmountText(currency(summary.userNetAmount)))
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                        }

                        if summary.id != viewModel.dailySummaries.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private var clientSummaryCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(localization.phrase("By client"))
                    .font(AppTheme.sectionTitleFont)
                    .foregroundStyle(AppTheme.primaryText)

                if viewModel.clientSummaries.isEmpty {
                    emptyState(localization.phrase("No client hours available in the selected invoice period."))
                } else {
                    ForEach(viewModel.clientSummaries) { summary in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(summary.clientName)
                                    .font(AppTheme.bodyFont.weight(.semibold))
                                    .foregroundStyle(AppTheme.primaryText)

                                Text(entryCountText(summary.entryCount, plural: "logs"))
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(decimal(summary.totalHours)) h")
                                    .font(AppTheme.bodyFont.weight(.semibold))
                                    .foregroundStyle(AppTheme.primaryText)

                                Text(currency(summary.totalAmount))
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.secondaryText)

                                Text(netAmountText(currency(summary.userNetAmount)))
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                        }

                        if summary.id != viewModel.clientSummaries.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private var timeLogsCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(localization.phrase("Registrations"))
                    .font(AppTheme.sectionTitleFont)
                    .foregroundStyle(AppTheme.primaryText)

                if viewModel.timeLogs.isEmpty {
                    emptyState(localization.phrase("Geen registraties gevonden in de gekozen periode."))
                } else {
                    ForEach(viewModel.timeLogs) { item in
                        timeLogRow(item.entry)

                        if item.id != viewModel.timeLogs.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private func trackingMetric(title: String, value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(AppTheme.primaryText)

            Text(title)
                .font(AppTheme.sectionTitleFont)
                .foregroundStyle(AppTheme.primaryText)

            Text(subtitle)
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppTheme.elevatedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func timeLogRow(_ entry: WorkEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.client.name)
                    .font(AppTheme.bodyFont.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)

                Text(AppFormatters.mediumDateFormatter.string(from: entry.date))
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.secondaryText)

                if !entry.notes.isEmpty {
                    Text(entry.notes)
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                if let collaborationRule = entry.collaborationRule ?? entry.client.collaborationRules.first {
                    Text(splitText(partnerName: collaborationRule.partnerName, percentage: collaborationRule.percentage.formatted(.number.precision(.fractionLength(0...2)))))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                if let signature = entry.customerSignature {
                    Text(signatureText(name: signature.signerName, date: signature.dateSigned.formatted(date: .abbreviated, time: .omitted)))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(.green)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(decimal(entry.hoursWorked)) h")
                    .font(AppTheme.bodyFont.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)

                Text(currency(entry.billableAmount))
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.secondaryText)

                Text(entry.hourlyRateOverride == nil ? localization.phrase("Standaard tarief") : localization.phrase("Aangepast tarief"))
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.secondaryText)

                if entry.includeInInvoice {
                    if let invoice = entry.invoiceLine?.invoice {
                        NavigationLink(localization.phrase("Open factuur")) {
                            InvoicePreviewView(
                                invoice: invoice,
                                collaborationRule: entry.collaborationRule ?? entry.client.collaborationRules.first
                            )
                        }
                        .font(AppTheme.captionFont)
                        .buttonStyle(.bordered)
                        .tint(AppTheme.accentColor)
                    } else {
                        Button(localization.phrase("Maak factuur")) {
                            openInvoiceWorkflow(for: entry)
                        }
                        .font(AppTheme.captionFont)
                        .buttonStyle(.bordered)
                        .tint(AppTheme.accentColor)
                    }
                } else if entry.invoiceLine == nil && !entry.isInvoiced {
                    Button(localization.phrase("Neem op factuur")) {
                        openInvoiceWorkflow(for: entry)
                    }
                    .font(AppTheme.captionFont)
                    .buttonStyle(.bordered)
                    .tint(AppTheme.accentColor)
                }

                if isModuleEnabled(.customerSignatures) {
                    Button(entry.customerSignature == nil ? localization.phrase("Sign work") : localization.phrase("Update signature")) {
                        signatureTarget = entry
                    }
                    .font(AppTheme.captionFont)
                    .buttonStyle(.bordered)
                }

                Toggle(isOn: invoiceToggleBinding(for: entry)) {
                    Text(localization.phrase("Op factuur"))
                        .font(AppTheme.captionFont)
                }
                .toggleStyle(.switch)
                .labelsHidden()
                .disabled(entry.isInvoiced || entry.invoiceLine != nil)

                Button(role: .destructive) {
                    entryPendingDeletion = entry
                } label: {
                    Image(systemName: "trash")
                }
                .font(AppTheme.captionFont)
                .buttonStyle(.bordered)
            }
        }
    }

    @ViewBuilder
    private func emptyState(_ text: String) -> some View {
        Text(text)
            .font(AppTheme.bodyFont)
            .foregroundStyle(AppTheme.secondaryText)
    }

    private func decimal(_ value: Double) -> String {
        let formatter = AppFormatters.decimalFormatter(maximumFractionDigits: 2)
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    private func currency(_ value: Double) -> String {
        let formatter = AppFormatters.currencyFormatter()
        return formatter.string(from: NSNumber(value: value)) ?? "EUR 0.00"
    }

    private var summaryColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 14),
            GridItem(.flexible(), spacing: 14)
        ]
    }

    private var invoicePeriodStartBinding: Binding<Date> {
        Binding(
            get: { viewModel.invoicePeriodStartDate },
            set: { viewModel.invoicePeriodStartDate = $0 }
        )
    }

    private var invoicePeriodEndBinding: Binding<Date> {
        Binding(
            get: { viewModel.invoicePeriodEndDate },
            set: { viewModel.invoicePeriodEndDate = $0 }
        )
    }

    private var refreshToken: String {
        let signature = workEntries.map {
            "\($0.id.uuidString)-\($0.hoursWorked)-\($0.hourlyRateOverride ?? -1)-\($0.date.timeIntervalSince1970)-\($0.includeInInvoice)-\($0.isInvoiced)"
        }.joined(separator: "|")

        return "\(signature)-\(viewModel.invoicePeriodStartDate.timeIntervalSince1970)-\(viewModel.invoicePeriodEndDate.timeIntervalSince1970)-\(historyViewModel.searchText)-\(historyViewModel.selectedClientID?.uuidString ?? "all")-\(historyViewModel.selectedFilter.rawValue)"
    }

    private var historySearchBinding: Binding<String> {
        Binding(
            get: { historyViewModel.searchText },
            set: { historyViewModel.searchText = $0 }
        )
    }

    private var invoiceSuggestion: InvoiceWorkflowLaunchContext? {
        invoiceRepository.makeSuggestedLaunchContext(
            from: workEntries,
            startDate: viewModel.invoicePeriodStartDate,
            endDate: viewModel.invoicePeriodEndDate,
            sourceTitle: "Registration workspace invoice"
        )
    }

    private var currentSettings: AppSettings? {
        appSettings.first
    }

    private var localization: AppLocalization {
        AppLocalization(localeIdentifier: currentSettings?.preferredLocaleIdentifier)
    }

    private var currentModuleConfiguration: ModuleVisibilityConfiguration? {
        moduleConfigurations.first
    }

    private func isModuleEnabled(_ module: AppModule) -> Bool {
        workModeService.isModuleEnabled(
            module,
            settings: currentSettings,
            moduleConfiguration: currentModuleConfiguration
        )
    }

    private var hasRegistrationTools: Bool {
        isModuleEnabled(.workRegistrations) || isModuleEnabled(.timeTracking)
    }

    private func openInvoiceWorkflow(for entry: WorkEntry) {
        guard entry.invoiceLine == nil else {
            workflowErrorMessage = localization.phrase("Deze registratie is al gekoppeld aan een factuurregel.")
            return
        }

        guard !entry.isInvoiced else {
            workflowErrorMessage = localization.phrase("Deze registratie is al gefactureerd.")
            return
        }

        if !entry.includeInInvoice {
            entry.includeInInvoice = true
            try? modelContext.save()
        }

        if let launchContext = invoiceRepository.makeLaunchContext(
            from: [entry],
            sourceTitle: localization.phrase("Factuur vanuit registratie")
        ) {
            appViewModel.openInvoiceWorkflow(launchContext)
        } else {
            workflowErrorMessage = localization.phrase("Deze registratie kon niet naar de factuurworkflow worden gestuurd.")
        }
    }

    private func entryCountText(_ count: Int, plural: String) -> String {
        switch SupportedLocale(rawValue: currentSettings?.preferredLocaleIdentifier ?? "") ?? .english {
        case .english:
            "\(count) \(plural)"
        case .dutch:
            "\(count) registraties"
        case .german:
            "\(count) Einträge"
        }
    }

    private func netAmountText(_ amount: String) -> String {
        switch SupportedLocale(rawValue: currentSettings?.preferredLocaleIdentifier ?? "") ?? .english {
        case .english:
            "Net \(amount)"
        case .dutch:
            "Netto \(amount)"
        case .german:
            "Netto \(amount)"
        }
    }

    private func splitText(partnerName: String, percentage: String) -> String {
        switch SupportedLocale(rawValue: currentSettings?.preferredLocaleIdentifier ?? "") ?? .english {
        case .english:
            "\(partnerName) · \(percentage)% split"
        case .dutch:
            "\(partnerName) · \(percentage)% verdeling"
        case .german:
            "\(partnerName) · \(percentage)% Aufteilung"
        }
    }

    private func signatureText(name: String, date: String) -> String {
        switch SupportedLocale(rawValue: currentSettings?.preferredLocaleIdentifier ?? "") ?? .english {
        case .english:
            "Signed by \(name) on \(date)"
        case .dutch:
            "Ondertekend door \(name) op \(date)"
        case .german:
            "Unterschrieben von \(name) am \(date)"
        }
    }

    private func invoiceToggleBinding(for entry: WorkEntry) -> Binding<Bool> {
        Binding(
            get: { entry.includeInInvoice },
            set: { newValue in
                guard entry.invoiceLine == nil, !entry.isInvoiced else { return }
                entry.includeInInvoice = newValue
                try? modelContext.save()
            }
        )
    }

    private var workflowErrorBinding: Binding<Bool> {
        Binding(
            get: { workflowErrorMessage != nil },
            set: { if !$0 { workflowErrorMessage = nil } }
        )
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { entryPendingDeletion != nil },
            set: { if !$0 { entryPendingDeletion = nil } }
        )
    }

    private var deleteErrorBinding: Binding<Bool> {
        Binding(
            get: { deleteErrorMessage != nil },
            set: { if !$0 { deleteErrorMessage = nil } }
        )
    }

    private func deletePendingEntry() {
        guard let entryPendingDeletion else { return }

        do {
            try timeTrackingRepository.delete(entryPendingDeletion, in: modelContext)
            self.entryPendingDeletion = nil
        } catch {
            deleteErrorMessage = localizedDeletionErrorMessage(for: error)
        }
    }

    private func localizedDeletionErrorMessage(for error: Error) -> String {
        if case TimeTrackingRepositoryError.entryLinkedToInvoice = error {
            return localization.phrase("This registration is already linked to an invoice and cannot be deleted.")
        }

        return error.localizedDescription
    }
}

#Preview {
    NavigationStack {
        TimeTrackingView()
            .environment(AppViewModel())
            .modelContainer(DashboardPreviewData.makeContainer())
    }
}
