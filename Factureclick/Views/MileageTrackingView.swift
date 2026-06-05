//
//  MileageTrackingView.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import SwiftData
import SwiftUI

struct MileageTrackingView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \MileageEntry.date, order: .reverse) private var mileageEntries: [MileageEntry]
    @Query(sort: \Client.name) private var clients: [Client]
    @Query private var appSettings: [AppSettings]

    @State private var viewModel = MileageTrackingViewModel()
    @State private var isPresentingForm = false
    @State private var editingEntry: MileageEntry?
    @State private var entryPendingDeletion: MileageEntry?

    private let repository = MileageRepository()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                summaryCard(title: localization.phrase("This week"), summary: viewModel.weeklySummary)
                summaryCard(title: localization.phrase("This month"), summary: viewModel.monthlySummary)
                filteredPeriodCard
                mileageLogsCard
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(AppTheme.screenBackground.ignoresSafeArea())
        .navigationTitle(localization.phrase("Mileage"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPresentingForm = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingForm) {
            NavigationStack {
                MileageEntryFormView()
            }
        }
        .sheet(item: $editingEntry) { entry in
            NavigationStack {
                MileageEntryFormView(entry: entry)
            }
        }
        .alert(localization.phrase("Delete Mileage Entry"), isPresented: deleteAlertBinding) {
            Button(localization.phrase("Delete"), role: .destructive) {
                deletePendingEntry()
            }
            Button(localization.phrase("Cancel"), role: .cancel) { }
        } message: {
            Text(localization.phrase("This trip log will be removed permanently."))
        }
        .task(id: refreshToken) {
            viewModel.refresh(with: mileageEntries)
        }
        .onChange(of: viewModel.selectedClientID) { _, _ in
            viewModel.refresh(with: mileageEntries)
        }
        .onChange(of: viewModel.searchText) { _, _ in
            viewModel.refresh(with: mileageEntries)
        }
        .onChange(of: viewModel.periodStartDate) { _, _ in
            viewModel.refresh(with: mileageEntries)
        }
        .onChange(of: viewModel.periodEndDate) { _, _ in
            viewModel.refresh(with: mileageEntries)
        }
    }

    private func summaryCard(title: String, summary: MileagePeriodSummary) -> some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(AppTheme.titleFont)
                    .foregroundStyle(AppTheme.primaryText)

                LazyVGrid(columns: summaryColumns, spacing: 14) {
                    metric(title: localization.phrase("Trips"), value: "\(summary.entryCount)", subtitle: localization.phrase("Mileage logs"))
                    metric(title: localization.phrase("Kilometers"), value: decimal(summary.totalKilometers), subtitle: localization.phrase("Distance tracked"))
                    metric(title: localization.phrase("Travel Cost"), value: currency(summary.totalTravelCost), subtitle: localization.phrase("Reimbursable amount"))
                    metric(title: localization.phrase("Invoice Cost"), value: currency(summary.invoiceEligibleCost), subtitle: localization.phrase("Marked for billing"))
                }
            }
        }
    }

    private var filteredPeriodCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(localization.phrase("Selected period"))
                    .font(AppTheme.sectionTitleFont)
                    .foregroundStyle(AppTheme.primaryText)

                TextField(localization.phrase("Search trips"), text: searchBinding)
                    .textFieldStyle(.roundedBorder)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        FilterChip(title: localization.phrase("All Clients"), isSelected: viewModel.selectedClientID == nil) {
                            viewModel.selectedClientID = nil
                        }

                        ForEach(clients) { client in
                            FilterChip(title: client.name, isSelected: viewModel.selectedClientID == client.id) {
                                viewModel.selectedClientID = client.id
                            }
                        }
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(MileagePeriodPreset.allCases) { preset in
                            FilterChip(title: localization.phrase(preset.title), isSelected: viewModel.selectedPreset == preset) {
                                viewModel.applyPreset(preset, using: mileageEntries)
                                viewModel.refresh(with: mileageEntries)
                            }
                        }
                    }
                }

                HStack(spacing: 12) {
                    DatePicker(localization.phrase("From"), selection: periodStartBinding, displayedComponents: .date)
                    DatePicker(localization.phrase("To"), selection: periodEndBinding, displayedComponents: .date)
                }

                LazyVGrid(columns: summaryColumns, spacing: 14) {
                    metric(title: localization.phrase("Shown"), value: "\(viewModel.selectedPeriodSummary.entryCount)", subtitle: localization.phrase("Matching trips"))
                    metric(title: localization.phrase("Kilometers"), value: decimal(viewModel.selectedPeriodSummary.totalKilometers), subtitle: localization.phrase("Filtered distance"))
                    metric(title: localization.phrase("Travel Cost"), value: currency(viewModel.selectedPeriodSummary.totalTravelCost), subtitle: localization.phrase("Filtered amount"))
                    metric(title: localization.phrase("Invoice Km"), value: decimal(viewModel.selectedPeriodSummary.invoiceEligibleKilometers), subtitle: localization.phrase("Ready to bill"))
                }
            }
        }
    }

    private var mileageLogsCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(localization.phrase("Mileage logs"))
                    .font(AppTheme.sectionTitleFont)
                    .foregroundStyle(AppTheme.primaryText)

                if viewModel.filteredEntries.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(localization.phrase("No mileage entries found for the selected filters."))
                            .font(AppTheme.bodyFont)
                            .foregroundStyle(AppTheme.secondaryText)

                        Button(localization.phrase("Log Trip")) {
                            isPresentingForm = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.accentColor)
                    }
                } else {
                    let items = repository.makeLogItems(for: viewModel.filteredEntries)
                    ForEach(items) { item in
                        mileageRow(item.entry)

                        if item.id != items.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private func mileageRow(_ entry: MileageEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.purpose)
                    .font(AppTheme.bodyFont.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
                Text(localization.mileageRoute(from: entry.startLocation, to: entry.endLocation))
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.secondaryText)
                Text(entry.client?.name ?? localization.phrase("No client"))
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.secondaryText)
                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(decimal(entry.numberOfKilometers)) km")
                    .font(AppTheme.bodyFont.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
                Text(currency(entry.totalTravelCost))
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.secondaryText)
                if entry.includeOnInvoice {
                    Text(entry.invoice?.invoiceNumber ?? localization.phrase("Invoice not linked"))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(entry.invoice == nil ? .orange : AppTheme.secondaryText)
                }
            }

            Menu {
                Button(localization.phrase("Edit")) {
                    editingEntry = entry
                }

                Button(localization.phrase("Delete"), role: .destructive) {
                    entryPendingDeletion = entry
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            editingEntry = entry
        }
        .contextMenu {
            Button(localization.phrase("Edit")) {
                editingEntry = entry
            }

            Button(localization.phrase("Delete"), role: .destructive) {
                entryPendingDeletion = entry
            }
        }
    }

    private func metric(title: String, value: String, subtitle: String) -> some View {
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

    private func decimal(_ value: Double) -> String {
        AppFormatters.decimalFormatter(maximumFractionDigits: 2).string(from: NSNumber(value: value)) ?? "0"
    }

    private func currency(_ value: Double) -> String {
        AppFormatters.currencyFormatter().string(from: NSNumber(value: value)) ?? "EUR 0.00"
    }

    private var summaryColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 14),
            GridItem(.flexible(), spacing: 14)
        ]
    }

    private var searchBinding: Binding<String> { Binding(get: { viewModel.searchText }, set: { viewModel.searchText = $0 }) }
    private var periodStartBinding: Binding<Date> { Binding(get: { viewModel.periodStartDate }, set: { viewModel.updateCustomStartDate($0) }) }
    private var periodEndBinding: Binding<Date> { Binding(get: { viewModel.periodEndDate }, set: { viewModel.updateCustomEndDate($0) }) }
    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { entryPendingDeletion != nil },
            set: { if !$0 { entryPendingDeletion = nil } }
        )
    }

    private var localization: AppLocalization {
        AppLocalization(localeIdentifier: appSettings.first?.preferredLocaleIdentifier)
    }

    private var refreshToken: String {
        mileageEntries.map {
            "\($0.id.uuidString)-\($0.date.timeIntervalSince1970)-\($0.numberOfKilometers)-\($0.reimbursementRatePerKilometer)-\($0.totalTravelCost)-\($0.includeOnInvoice)-\($0.client?.id.uuidString ?? "none")-\($0.invoice?.id.uuidString ?? "none")"
        }
        .joined(separator: "|")
    }

    private func deletePendingEntry() {
        guard let entryPendingDeletion else { return }
        modelContext.delete(entryPendingDeletion)
        try? modelContext.save()
        self.entryPendingDeletion = nil
    }
}
