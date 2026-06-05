//
//  MailComposeView.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import MessageUI
import SwiftUI

struct MailComposeAttachment {
    let data: Data
    let mimeType: String
    let fileName: String
}

struct MailComposePayload {
    let recipients: [String]
    let subject: String
    let body: String
    let isHTML: Bool
    let attachments: [MailComposeAttachment]
}

struct MailComposeView: UIViewControllerRepresentable {
    let payload: MailComposePayload
    let onFinish: (MFMailComposeResult, Error?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setToRecipients(payload.recipients)
        controller.setSubject(payload.subject)
        controller.setMessageBody(payload.body, isHTML: payload.isHTML)
        for attachment in payload.attachments {
            controller.addAttachmentData(attachment.data, mimeType: attachment.mimeType, fileName: attachment.fileName)
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) { }

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onFinish: (MFMailComposeResult, Error?) -> Void

        init(onFinish: @escaping (MFMailComposeResult, Error?) -> Void) {
            self.onFinish = onFinish
        }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            onFinish(result, error)
            controller.dismiss(animated: true)
        }
    }
}
