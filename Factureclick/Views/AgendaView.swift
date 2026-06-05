//
//  AgendaView.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import SwiftData
import SwiftUI

struct AgendaView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \WorkEntry.date, order: .reverse) private var workEntries: [WorkEntry]
    @Query private var appSettings: [AppSettings]

    @State private var selectedDate = Calendar.current.startOfDay(for: .now)
    @State private var isPresentingWorkEntryForm = false
    @State private var entryPendingDeletion: WorkEntry?
    @State private var deleteErrorMessage: String?

    private let viewModel = AgendaViewModel()
    private let invoiceRepository = InvoiceRepository()
    private let timeTrackingRepository = TimeTrackingRepository()

    var body: some View {
        let weekDays = viewModel.weekDays(containing: selectedDate)
        let sections = viewModel.makeSections(for: workEntries, in: weekDays)
        let selectedEntries = viewModel.entries(for: selectedDate, from: workEntries)
        let selectedDayLaunchContext = invoiceRepository.makeLaunchContext(
            from: selectedEntries,
            sourceTitle: localization.phrase("Agenda day invoice")
        )
        let weeklyPreparation = invoiceRepository.makeEndOfWeekPreparation(from: workEntries, referenceDate: selectedDate)

        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                weekCard(weekDays: weekDays)
                selectedDayCard(entries: selectedEntries, launchContext: selectedDayLaunchContext)
                if weeklyPreparation.shouldHighlight {
                    weeklyReviewCard(preparation: weeklyPreparation)
                }
                weeklyEntriesCard(sections: sections)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(AppTheme.screenBackground.ignoresSafeArea())
        .navigationTitle(localization.phrase("Agenda"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPresentingWorkEntryForm = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingWorkEntryForm) {
            NavigationStack {
                WorkEntryFormView(selectedDate: selectedDate)
            }
        }
        .onChange(of: appViewModel.shouldPresentWorkEntryForm) { _, shouldPresent in
            guard shouldPresent, appViewModel.selectedTab == .agenda else { return }
            appViewModel.shouldPresentWorkEntryForm = false
            isPresentingWorkEntryForm = true
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

    private func weekCard(weekDays: [AgendaDay]) -> some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 18) {
                Text(localization.phrase("This week"))
                    .font(AppTheme.titleFont)
                    .foregroundStyle(AppTheme.primaryText)

                HStack(spacing: 10) {
                    ForEach(weekDays) { day in
                        CalendarDayButton(
                            day: day,
                            isSelected: viewModel.isSameDay(day.date, selectedDate)
                        ) {
                            selectedDate = day.date
                        }
                    }
                }
            }
        }
    }

    private func selectedDayCard(entries: [WorkEntry], launchContext: InvoiceWorkflowLaunchContext?) -> some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.title(for: selectedDate))
                            .font(AppTheme.titleFont)
                            .foregroundStyle(AppTheme.primaryText)

                        Text("\(entries.count) \(localization.phrase("entries"))")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.secondaryText)
                    }

                    Spacer()

                    Button(localization.phrase("Add Entry")) {
                        isPresentingWorkEntryForm = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accentColor)

                    if let launchContext {
                        Button(localization.phrase("Invoice Open Work")) {
                            appViewModel.openInvoiceWorkflow(launchContext)
                        }
                        .buttonStyle(.bordered)
                    }
                }

                if entries.isEmpty {
                    Text(localization.phrase("No work entries scheduled for this day yet."))
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                } else {
                    ForEach(entries) { entry in
                        HStack(alignment: .top, spacing: 12) {
                            WorkEntryRow(
                                entry: entry,
                                timeText: viewModel.timeString(for: entry.date),
                                canCreateInvoice: invoiceRepository.canCreateInvoice(for: entry)
                            ) {
                                if let launchContext = invoiceRepository.makeLaunchContext(
                                    from: [entry],
                                    sourceTitle: localization.phrase("Agenda registration invoice")
                                ) {
                                    appViewModel.openInvoiceWorkflow(launchContext)
                                }
                            }

                            Button(role: .destructive) {
                                entryPendingDeletion = entry
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.bordered)
                        }

                        if entry.id != entries.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private func weeklyReviewCard(preparation: WeeklyBillingPreparation) -> some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(localization.phrase("Weekly review"))
                    .font(AppTheme.sectionTitleFont)
                    .foregroundStyle(AppTheme.primaryText)

                Text(weeklyReviewText(preparation))
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.secondaryText)

                Button(localization.phrase("Open Friday Review")) {
                    appViewModel.openWeeklyInvoiceReview(for: preparation.weekEnd)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accentColor)
            }
        }
    }

    private func weeklyEntriesCard(sections: [AgendaSection]) -> some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 18) {
                Text(localization.phrase("Week overview"))
                    .font(AppTheme.sectionTitleFont)
                    .foregroundStyle(AppTheme.primaryText)

                ForEach(sections) { section in
                    Button {
                        selectedDate = section.day.date
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(viewModel.title(for: section.day.date))
                                    .font(AppTheme.bodyFont.weight(.semibold))
                                    .foregroundStyle(AppTheme.primaryText)

                                Text("\(section.entries.count) \(localization.phrase("work entries"))")
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if section.id != sections.last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    private var localization: AppLocalization {
        AppLocalization(localeIdentifier: appSettings.first?.preferredLocaleIdentifier)
    }

    private func weeklyReviewText(_ preparation: WeeklyBillingPreparation) -> String {
        switch appSettings.first.flatMap({ SupportedLocale(rawValue: $0.preferredLocaleIdentifier) }) ?? .english {
        case .english:
            "\(preparation.pendingEntries.count) uninvoiced registrations are ready for end-of-week billing."
        case .dutch:
            "\(preparation.pendingEntries.count) niet-gefactureerde registraties staan klaar voor weekafsluiting."
        case .german:
            "\(preparation.pendingEntries.count) nicht abgerechnete Erfassungen sind für den Wochenabschluss bereit."
        }
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
            if case TimeTrackingRepositoryError.entryLinkedToInvoice = error {
                deleteErrorMessage = localization.phrase("This registration is already linked to an invoice and cannot be deleted.")
            } else {
                deleteErrorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    NavigationStack {
        AgendaView()
            .environment(AppViewModel())
            .modelContainer(DashboardPreviewData.makeContainer())
    }
}
