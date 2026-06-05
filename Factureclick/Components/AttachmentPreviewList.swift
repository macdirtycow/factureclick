//
//  AttachmentPreviewList.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import SwiftUI

struct AttachmentPreviewList: View {
    let attachments: [Attachment]
    var onShare: ((Attachment) -> Void)?
    var onDelete: ((Attachment) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(attachments) { attachment in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "paperclip.circle.fill")
                        .foregroundStyle(AppTheme.accentColor)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(attachment.fileName)
                            .font(AppTheme.bodyFont.weight(.semibold))
                            .foregroundStyle(AppTheme.primaryText)

                        Text(fileMeta(attachment))
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.secondaryText)
                    }

                    Spacer()

                    if let onShare {
                        Button {
                            onShare(attachment)
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .buttonStyle(.plain)
                    }

                    if let onDelete {
                        Button(role: .destructive) {
                            onDelete(attachment)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func fileMeta(_ attachment: Attachment) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return "\(formatter.string(fromByteCount: attachment.fileSize)) · \(attachment.contentType)"
    }
}
