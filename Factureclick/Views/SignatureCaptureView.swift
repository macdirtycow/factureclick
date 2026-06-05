//
//  SignatureCaptureView.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import SwiftData
import SwiftUI

struct SignatureCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var appSettings: [AppSettings]

    let title: String
    let existingSignature: CustomerSignature?
    let onSave: (SignatureCaptureDraft) throws -> Void

    @State private var signerName: String
    @State private var dateSigned: Date
    @State private var note: String
    @State private var drawing: SignatureDrawing
    @State private var errorMessage: String?

    private let storageService = SignatureStorageService()

    init(
        title: String,
        existingSignature: CustomerSignature? = nil,
        onSave: @escaping (SignatureCaptureDraft) throws -> Void
    ) {
        self.title = title
        self.existingSignature = existingSignature
        self.onSave = onSave
        _signerName = State(initialValue: existingSignature?.signerName ?? "")
        _dateSigned = State(initialValue: existingSignature?.dateSigned ?? .now)
        _note = State(initialValue: existingSignature?.note ?? "")
        _drawing = State(initialValue: storageService.loadDrawing(from: existingSignature?.strokeLocalPath) ?? SignatureDrawing())
    }

    var body: some View {
        Form {
            Section(localization.phrase("Signature")) {
                SignatureCanvasView(
                    drawing: $drawing,
                    placeholderText: localization.phrase("Sign here")
                )

                HStack {
                    Button(localization.phrase("Clear")) {
                        drawing = SignatureDrawing()
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Text("\(drawing.strokeCount) \(localization.phrase(drawing.strokeCount == 1 ? "stroke" : "strokes"))")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }

            Section(localization.phrase("Signer")) {
                TextField(localization.phrase("Signer name"), text: $signerName)
                DatePicker(localization.phrase("Date signed"), selection: $dateSigned, displayedComponents: .date)
                TextField(localization.phrase("Optional note"), text: $note, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.screenBackground.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .alert(localization.phrase("Signature"), isPresented: errorBinding) {
            Button(localization.phrase("OK"), role: .cancel) { }
        } message: {
            Text(errorMessage ?? "")
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(localization.phrase("Cancel")) {
                    dismiss()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(localization.phrase("Save")) {
                    save()
                }
                .disabled(!canSave)
            }
        }
    }

    private var canSave: Bool {
        !signerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !drawing.isEmpty
    }

    private func save() {
        do {
            try onSave(
                SignatureCaptureDraft(
                    signerName: signerName.trimmingCharacters(in: .whitespacesAndNewlines),
                    dateSigned: dateSigned,
                    note: note.trimmingCharacters(in: .whitespacesAndNewlines),
                    drawing: drawing
                )
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private var localization: AppLocalization {
        AppLocalization(localeIdentifier: appSettings.first?.preferredLocaleIdentifier)
    }
}
