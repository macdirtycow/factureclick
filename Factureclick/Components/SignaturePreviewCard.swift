//
//  SignaturePreviewCard.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import SwiftUI
import SwiftData

struct SignaturePreviewCard: View {
    @Query private var appSettings: [AppSettings]

    let signature: CustomerSignature?
    let addActionTitle: String
    let onAddOrEdit: () -> Void
    let onDelete: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(localization.phrase("Customer signature"))
                        .font(AppTheme.sectionTitleFont)
                        .foregroundStyle(AppTheme.primaryText)
                    Text(
                        signature == nil
                            ? localization.phrase("No signature captured yet.")
                            : localization.phrase("Saved for later confirmation and export use.")
                    )
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Spacer()
            }

            if let signature {
                if let image = UIImage(contentsOfFile: signature.imageLocalPath) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 180)
                        .padding(12)
                        .background(AppTheme.elevatedBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                infoRow(localization.phrase("Signer"), signature.signerName)
                infoRow(localization.phrase("Signed"), signature.dateSigned.formatted(date: .abbreviated, time: .omitted))
                if !signature.note.isEmpty {
                    infoRow(localization.phrase("Note"), signature.note)
                }
            }

            HStack {
                Button(signature == nil ? addActionTitle : localization.phrase("Update Signature")) {
                    onAddOrEdit()
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accentColor)

                if signature != nil, let onDelete {
                    Button(localization.phrase("Remove"), role: .destructive) {
                        onDelete()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .foregroundStyle(AppTheme.secondaryText)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(AppTheme.primaryText)
        }
    }

    private var localization: AppLocalization {
        AppLocalization(localeIdentifier: appSettings.first?.preferredLocaleIdentifier)
    }
}
