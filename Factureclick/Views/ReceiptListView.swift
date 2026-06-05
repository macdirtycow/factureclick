//
//  ReceiptListView.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import SwiftData
import SwiftUI
import UIKit

struct ReceiptListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Receipt.date, order: .reverse) private var receipts: [Receipt]
    @Query(sort: \Client.name) private var clients: [Client]
    @Query private var appSettings: [AppSettings]

    @State private var viewModel = ReceiptListViewModel()
    @State private var isPresentingCreateForm = false
    @State private var editingReceipt: Receipt?
    @State private var pendingDeleteReceipt: Receipt?

    private let storageService = ReceiptStorageService()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                summaryCard
                filtersCard
                receiptsCard
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(AppTheme.screenBackground.ignoresSafeArea())
        .navigationTitle(localization.phrase("Receipts"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPresentingCreateForm = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingCreateForm) {
            NavigationStack {
                ReceiptFormView()
            }
        }
        .sheet(item: $editingReceipt) { receipt in
            NavigationStack {
                ReceiptFormView(receipt: receipt)
            }
        }
        .alert(localization.phrase("Delete Receipt"), isPresented: deleteAlertBinding) {
            Button(localization.phrase("Delete"), role: .destructive) {
                deletePendingReceipt()
            }
            Button(localization.phrase("Cancel"), role: .cancel) { }
        } message: {
            Text(localization.phrase("The stored receipt image and its metadata will be removed."))
        }
        .task(id: refreshToken) {
            viewModel.refresh(with: receipts)
        }
        .onChange(of: viewModel.searchText) { _, _ in
            viewModel.refresh(with: receipts)
        }
        .onChange(of: viewModel.selectedCategory?.rawValue) { _, _ in
            viewModel.refresh(with: receipts)
        }
        .onChange(of: viewModel.selectedClientID) { _, _ in
            viewModel.refresh(with: receipts)
        }
        .onChange(of: viewModel.startDate) { _, _ in
            viewModel.refresh(with: receipts)
        }
        .onChange(of: viewModel.endDate) { _, _ in
            viewModel.refresh(with: receipts)
        }
    }

    private var summaryCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(localization.phrase("Receipt summary"))
                    .font(AppTheme.titleFont)
                    .foregroundStyle(AppTheme.primaryText)

                LazyVGrid(columns: gridColumns, spacing: 14) {
                    metric(title: localization.phrase("Receipts"), value: "\(viewModel.filteredSummary.receiptCount)", subtitle: localization.phrase("Shown in current filters"))
                    metric(title: localization.phrase("Amount"), value: currency(viewModel.filteredSummary.totalAmount), subtitle: localization.phrase("Gross spend tracked"))
                    metric(title: localization.text(.vat), value: currency(viewModel.filteredSummary.totalVATAmount), subtitle: localization.phrase("Recoverable tax"))
                    metric(title: localization.phrase("Linked"), value: "\(viewModel.filteredSummary.linkedReceiptCount)", subtitle: localization.phrase("Attached to work or invoices"))
                }
            }
        }
    }

    private var filtersCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(localization.phrase("Filters"))
                    .font(AppTheme.sectionTitleFont)
                    .foregroundStyle(AppTheme.primaryText)

                TextField(localization.phrase("Search supplier, notes, invoice"), text: searchBinding)
                    .textFieldStyle(.roundedBorder)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        FilterChip(title: localization.phrase("All Categories"), isSelected: viewModel.selectedCategory == nil) {
                            viewModel.selectedCategory = nil
                        }

                        ForEach(ReceiptCategory.allCases) { category in
                            FilterChip(title: localization.phrase(category.title), isSelected: viewModel.selectedCategory == category) {
                                viewModel.selectedCategory = category
                            }
                        }
                    }
                }

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

                HStack(spacing: 12) {
                    DatePicker(localization.phrase("From"), selection: startDateBinding, displayedComponents: .date)
                    DatePicker(localization.phrase("To"), selection: endDateBinding, displayedComponents: .date)
                }
            }
        }
    }

    private var receiptsCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(localization.phrase("Stored receipts"))
                    .font(AppTheme.sectionTitleFont)
                    .foregroundStyle(AppTheme.primaryText)

                if viewModel.filteredReceipts.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(localization.phrase("No receipts match the current filters."))
                            .font(AppTheme.bodyFont)
                            .foregroundStyle(AppTheme.secondaryText)

                        Button(localization.phrase("Add Receipt")) {
                            isPresentingCreateForm = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.accentColor)
                    }
                } else {
                    ForEach(Array(viewModel.filteredReceipts.enumerated()), id: \.element.id) { index, receipt in
                        receiptRow(receipt)

                        if index < viewModel.filteredReceipts.count - 1 {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private func receiptRow(_ receipt: Receipt) -> some View {
        HStack(alignment: .top, spacing: 14) {
            thumbnail(for: receipt)

            VStack(alignment: .leading, spacing: 4) {
                Text(receipt.supplierName)
                    .font(AppTheme.bodyFont.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)

                Text(localization.phrase(receipt.category.title))
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.secondaryText)

                Text(receipt.date.formatted(date: .abbreviated, time: .omitted))
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.secondaryText)

                if let linkedLabel = linkedLabel(for: receipt) {
                    Text(linkedLabel)
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(currency(receipt.amount))
                    .font(AppTheme.bodyFont.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)

                if let vatAmount = receipt.vatAmount {
                    Text("\(localization.text(.vat)) \(currency(vatAmount))")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Menu {
                    Button(localization.phrase("Edit")) {
                        editingReceipt = receipt
                    }

                    Button(localization.phrase("Delete"), role: .destructive) {
                        pendingDeleteReceipt = receipt
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .buttonStyle(.plain)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            editingReceipt = receipt
        }
    }

    private func thumbnail(for receipt: Receipt) -> some View {
        Group {
            if let image = UIImage(contentsOfFile: receipt.localPath) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.elevatedBackground)
                    .overlay {
                        Image(systemName: "doc.text.image")
                            .foregroundStyle(AppTheme.secondaryText)
                    }
            }
        }
        .frame(width: 72, height: 72)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func linkedLabel(for receipt: Receipt) -> String? {
        if let invoice = receipt.linkedInvoice {
            return "\(localization.phrase("Invoice")) \(invoice.invoiceNumber)"
        }

        if let workEntry = receipt.linkedWorkEntry {
            return "\(localization.phrase("Registration")) \(AppFormatters.mediumDateFormatter.string(from: workEntry.date))"
        }

        if let client = receipt.linkedClient {
            return client.name
        }

        return nil
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

    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 14),
            GridItem(.flexible(), spacing: 14)
        ]
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { pendingDeleteReceipt != nil },
            set: { if !$0 { pendingDeleteReceipt = nil } }
        )
    }

    private var localization: AppLocalization {
        AppLocalization(localeIdentifier: appSettings.first?.preferredLocaleIdentifier)
    }

    private var searchBinding: Binding<String> { Binding(get: { viewModel.searchText }, set: { viewModel.searchText = $0 }) }
    private var startDateBinding: Binding<Date> { Binding(get: { viewModel.startDate }, set: { viewModel.startDate = $0 }) }
    private var endDateBinding: Binding<Date> { Binding(get: { viewModel.endDate }, set: { viewModel.endDate = $0 }) }

    private var refreshToken: String {
        receipts.map {
            "\($0.id.uuidString)-\($0.date.timeIntervalSince1970)-\($0.amount)-\($0.categoryRawValue)-\($0.linkedClient?.id.uuidString ?? "none")-\($0.updatedAt.timeIntervalSince1970)"
        }
        .joined(separator: "|")
    }

    private func deletePendingReceipt() {
        guard let pendingDeleteReceipt else { return }
        storageService.deleteStoredFile(at: pendingDeleteReceipt.localPath)
        modelContext.delete(pendingDeleteReceipt)
        try? modelContext.save()
        self.pendingDeleteReceipt = nil
    }

    private func currency(_ value: Double) -> String {
        AppFormatters.currencyFormatter().string(from: NSNumber(value: value)) ?? "EUR 0.00"
    }
}
