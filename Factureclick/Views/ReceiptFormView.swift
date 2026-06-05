//
//  ReceiptFormView.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct ReceiptFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Client.name) private var clients: [Client]
    @Query(sort: \WorkEntry.date, order: .reverse) private var workEntries: [WorkEntry]
    @Query(sort: \Invoice.date, order: .reverse) private var invoices: [Invoice]

    private let receipt: Receipt?
    private let storageService = ReceiptStorageService()

    @State private var viewModel: ReceiptFormViewModel
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isPresentingCamera = false
    @State private var saveErrorMessage: String?

    init(receipt: Receipt? = nil) {
        self.receipt = receipt
        _viewModel = State(initialValue: ReceiptFormViewModel(receipt: receipt))
    }

    var body: some View {
        Form {
            Section("Receipt image") {
                receiptImagePreview

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label(viewModel.receiptFile == nil ? "Choose from Photos" : "Replace from Photos", systemImage: "photo.on.rectangle")
                }

                Button {
                    isPresentingCamera = true
                } label: {
                    Label(viewModel.receiptFile == nil ? "Capture Photo" : "Retake Photo", systemImage: "camera")
                }
                .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
            }

            Section("Details") {
                DatePicker("Date", selection: dateBinding, displayedComponents: .date)
                TextField("Supplier name", text: supplierBinding)
                TextField("Amount", value: amountBinding, format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.decimalPad)
                TextField("VAT amount", value: vatAmountBinding, format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.decimalPad)

                Picker("Category", selection: categoryBinding) {
                    ForEach(ReceiptCategory.allCases) { category in
                        Text(category.title).tag(category)
                    }
                }
            }

            Section("Links") {
                Picker("Client", selection: clientBinding) {
                    Text("No linked client").tag(nil as UUID?)
                    ForEach(clients) { client in
                        Text(client.name).tag(Optional(client.id))
                    }
                }

                Picker("Registration", selection: workEntryBinding) {
                    Text("No linked registration").tag(nil as UUID?)
                    ForEach(availableWorkEntries) { workEntry in
                        Text(registrationLabel(for: workEntry)).tag(Optional(workEntry.id))
                    }
                }

                Picker("Invoice", selection: invoiceBinding) {
                    Text("No linked invoice").tag(nil as UUID?)
                    ForEach(availableInvoices) { invoice in
                        Text("\(invoice.invoiceNumber) · \(invoice.client.name)").tag(Optional(invoice.id))
                    }
                }

                Text("Link either a registration or an invoice. Selecting one clears the other.")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Section("Notes") {
                TextField("Add expense context", text: notesBinding, axis: .vertical)
                    .lineLimit(4, reservesSpace: true)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.screenBackground.ignoresSafeArea())
        .navigationTitle(receipt == nil ? "New Receipt" : "Edit Receipt")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isPresentingCamera) {
            ReceiptCameraPicker(
                onImagePicked: { image in
                    handleCapturedImage(image)
                    isPresentingCamera = false
                },
                onCancel: {
                    isPresentingCamera = false
                }
            )
            .ignoresSafeArea()
        }
        .task(id: selectedPhotoItem) {
            await handleSelectedPhotoItem()
        }
        .alert("Receipt", isPresented: saveErrorBinding) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveErrorMessage ?? "")
        }
        .onChange(of: viewModel.selectedWorkEntryID) { _, selectedID in
            guard let selectedID, let workEntry = workEntries.first(where: { $0.id == selectedID }) else { return }
            viewModel.selectedClientID = workEntry.client.id
        }
        .onChange(of: viewModel.selectedInvoiceID) { _, selectedID in
            guard let selectedID, let invoice = invoices.first(where: { $0.id == selectedID }) else { return }
            viewModel.selectedClientID = invoice.client.id
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    save()
                }
                .disabled(!viewModel.canSave)
            }
        }
    }

    private var receiptImagePreview: some View {
        Group {
            if let image = receiptUIImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppTheme.elevatedBackground)
                    .frame(height: 180)
                    .overlay {
                        VStack(spacing: 10) {
                            Image(systemName: "doc.text.viewfinder")
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundStyle(AppTheme.accentColor)
                            Text("Add a receipt image to store proof safely on-device.")
                                .font(AppTheme.bodyFont)
                                .foregroundStyle(AppTheme.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                    }
            }
        }
    }

    private var receiptUIImage: UIImage? {
        guard let localPath = viewModel.receiptFile?.localPath, !localPath.isEmpty else { return nil }
        return UIImage(contentsOfFile: localPath)
    }

    private var availableWorkEntries: [WorkEntry] {
        workEntries.filter { workEntry in
            guard let selectedClientID = viewModel.selectedClientID else { return true }
            return workEntry.client.id == selectedClientID
        }
    }

    private var availableInvoices: [Invoice] {
        invoices.filter { invoice in
            guard let selectedClientID = viewModel.selectedClientID else { return true }
            return invoice.client.id == selectedClientID
        }
    }

    private var dateBinding: Binding<Date> { Binding(get: { viewModel.date }, set: { viewModel.date = $0 }) }
    private var supplierBinding: Binding<String> { Binding(get: { viewModel.supplierName }, set: { viewModel.supplierName = $0 }) }
    private var amountBinding: Binding<Double> { Binding(get: { viewModel.amount }, set: { viewModel.amount = $0 }) }
    private var notesBinding: Binding<String> { Binding(get: { viewModel.notes }, set: { viewModel.notes = $0 }) }
    private var categoryBinding: Binding<ReceiptCategory> { Binding(get: { viewModel.selectedCategory }, set: { viewModel.selectedCategory = $0 }) }
    private var clientBinding: Binding<UUID?> { Binding(get: { viewModel.selectedClientID }, set: { viewModel.selectedClientID = $0 }) }
    private var workEntryBinding: Binding<UUID?> { Binding(get: { viewModel.selectedWorkEntryID }, set: { viewModel.selectLinkedWorkEntry($0) }) }
    private var invoiceBinding: Binding<UUID?> { Binding(get: { viewModel.selectedInvoiceID }, set: { viewModel.selectLinkedInvoice($0) }) }
    private var saveErrorBinding: Binding<Bool> {
        Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )
    }
    private var vatAmountBinding: Binding<Double?> {
        Binding(
            get: { viewModel.vatAmount },
            set: { viewModel.vatAmount = $0 }
        )
    }

    private func handleCapturedImage(_ image: UIImage) {
        do {
            let payload = try storageService.storeCapturedImage(image)
            replaceDraftImage(with: payload, importSource: .camera)
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    private func handleSelectedPhotoItem() async {
        guard let selectedPhotoItem else { return }

        do {
            guard let imageData = try await selectedPhotoItem.loadTransferable(type: Data.self) else {
                throw ReceiptStorageError.emptyImageData
            }

            let payload = try storageService.storePhotoLibraryImage(data: imageData)
            replaceDraftImage(with: payload, importSource: .photoLibrary)
        } catch {
            saveErrorMessage = error.localizedDescription
        }

        self.selectedPhotoItem = nil
    }

    private func replaceDraftImage(with payload: StoredReceiptPayload, importSource: ReceiptImportSource) {
        if let previousPath = viewModel.receiptFile?.localPath, previousPath != receipt?.localPath {
            storageService.deleteStoredFile(at: previousPath)
        }

        viewModel.updateStoredFile(payload, importSource: importSource)
    }

    private func registrationLabel(for workEntry: WorkEntry) -> String {
        let date = AppFormatters.mediumDateFormatter.string(from: workEntry.date)
        let summary = workEntry.notes.isEmpty ? "\(workEntry.hoursWorked.formatted(.number.precision(.fractionLength(0...1)))) h" : workEntry.notes
        return "\(date) · \(summary)"
    }

    private func save() {
        let target = receipt ?? Receipt()
        let previousLocalPath = receipt?.localPath

        viewModel.apply(
            to: target,
            clients: clients,
            workEntries: workEntries,
            invoices: invoices
        )

        if receipt == nil {
            modelContext.insert(target)
        }

        do {
            try modelContext.save()

            if let previousLocalPath, previousLocalPath != target.localPath {
                storageService.deleteStoredFile(at: previousLocalPath)
            }

            dismiss()
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }
}
