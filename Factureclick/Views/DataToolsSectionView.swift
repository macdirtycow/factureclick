//
//  DataToolsSectionView.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct DataToolsSectionView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Client.name) private var clients: [Client]
    @Query(sort: \Product.name) private var products: [Product]
    @Query(sort: \WorkEntry.date, order: .reverse) private var registrations: [WorkEntry]
    @Query(sort: \Invoice.date, order: .reverse) private var invoices: [Invoice]
    @Query private var appSettings: [AppSettings]

    @State private var viewModel = DataToolsViewModel()
    @State private var isImportingFile = false
    @State private var isSharingExport = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            SectionCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text(localization.phrase("Data tools"))
                        .font(AppTheme.titleFont)
                        .foregroundStyle(AppTheme.primaryText)

                    Text(localization.phrase("Import clients or products from CSV, preview rows before saving, and export backups or reporting files."))
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }

            importCard
            exportCard
        }
        .fileImporter(isPresented: $isImportingFile, allowedContentTypes: [.commaSeparatedText, .text], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    viewModel.previewImport(from: url)
                }
            case .failure(let error):
                viewModel.errorMessage = error.localizedDescription
            }
        }
        .sheet(isPresented: $isSharingExport) {
            if let exportedFile = viewModel.exportedFile {
                ActivityShareSheet(items: [exportedFile.url])
            }
        }
        .alert(localization.phrase("Data Tools"), isPresented: errorBinding) {
            Button(localization.phrase("OK"), role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? importSummaryText ?? "")
        }
        .onChange(of: viewModel.exportedFile?.url.path) { _, newValue in
            if newValue != nil {
                isSharingExport = true
            }
        }
    }

    private var importCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(localization.phrase("Import CSV"))
                    .font(AppTheme.sectionTitleFont)
                    .foregroundStyle(AppTheme.primaryText)

                Picker(localization.phrase("Import type"), selection: importKindBinding) {
                    ForEach(DataImportKind.allCases) { kind in
                        Text(localization.phrase(kind.title)).tag(kind)
                    }
                }
                .pickerStyle(.segmented)

                Button(localization.phrase("Choose CSV File")) {
                    isImportingFile = true
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accentColor)

                if let preview = viewModel.importPreview {
                    Text("\(localization.phrase("Preview")): \(preview.sourceFileName)")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.secondaryText)

                    ForEach(preview.items.prefix(8)) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(item.title)
                                    .font(AppTheme.bodyFont.weight(.semibold))
                                    .foregroundStyle(AppTheme.primaryText)
                                Spacer()
                                Image(systemName: item.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(item.isValid ? .green : .red)
                            }

                            if !item.subtitle.isEmpty {
                                Text(item.subtitle)
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }

                            if let validationMessage = item.validationMessage {
                                Text(validationMessage)
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(.red)
                            }
                        }

                        if item.id != preview.items.prefix(8).last?.id {
                            Divider()
                        }
                    }

                    if !preview.errors.isEmpty {
                        Divider()
                        ForEach(preview.errors, id: \.self) { error in
                            Text(error)
                                .font(AppTheme.captionFont)
                                .foregroundStyle(.red)
                        }
                    }

                    Button(localization.phrase("Import Valid Rows")) {
                        viewModel.applyImport(in: modelContext)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accentColor)
                }
            }
        }
    }

    private var exportCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(localization.phrase("Export"))
                    .font(AppTheme.sectionTitleFont)
                    .foregroundStyle(AppTheme.primaryText)

                Button(localization.phrase("Export App Backup")) {
                    viewModel.exportBackup(
                        clients: clients,
                        products: products,
                        registrations: registrations,
                        invoices: invoices
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accentColor)

                Button(localization.phrase("Export Registrations CSV")) {
                    viewModel.exportRegistrations(registrations)
                }
                .buttonStyle(.bordered)

                Button(localization.phrase("Export Invoices CSV")) {
                    viewModel.exportInvoices(invoices)
                }
                .buttonStyle(.bordered)

                if let exportedFile = viewModel.exportedFile {
                    Text("\(localization.phrase("Ready")): \(exportedFile.title)")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
    }

    private var importKindBinding: Binding<DataImportKind> {
        Binding(
            get: { viewModel.selectedImportKind },
            set: {
                viewModel.selectedImportKind = $0
                viewModel.importPreview = nil
                viewModel.importSummary = nil
            }
        )
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil || viewModel.importSummary != nil },
            set: {
                if !$0 {
                    viewModel.errorMessage = nil
                    viewModel.importSummary = nil
                }
            }
        )
    }

    private var importSummaryText: String? {
        guard let summary = viewModel.importSummary else { return nil }
        let errorText = summary.errorMessages.isEmpty ? "" : "\n\n" + summary.errorMessages.joined(separator: "\n")
        return "Imported \(summary.successCount) rows.\(errorText)"
    }

    private var localization: AppLocalization {
        AppLocalization(localeIdentifier: appSettings.first?.preferredLocaleIdentifier)
    }
}

#Preview {
    ScrollView {
        DataToolsSectionView()
            .modelContainer(DashboardPreviewData.makeContainer())
    }
}
