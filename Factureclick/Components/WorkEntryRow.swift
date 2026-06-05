//
//  WorkEntryRow.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import SwiftUI

struct WorkEntryRow: View {
    let entry: WorkEntry
    let timeText: String
    let canCreateInvoice: Bool
    let createInvoice: () -> Void

    private var quantityText: String {
        if let product = entry.product, product.unitType != .hour {
            return "\(entry.quantity.formatted(.number.precision(.fractionLength(0...2)))) \(product.unitType.displayName.lowercased())"
        }

        return "\(entry.hoursWorked.formatted(.number.precision(.fractionLength(0...1)))) h"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.client.name)
                        .font(AppTheme.sectionTitleFont)
                        .foregroundStyle(AppTheme.primaryText)

                    Text(entry.product?.name ?? "General work")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(quantityText)
                        .font(AppTheme.sectionTitleFont)
                        .foregroundStyle(AppTheme.primaryText)

                    Text(timeText)
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }

            HStack {
                if entry.includeInInvoice {
                    Label(
                        entry.isInvoiced ? "Invoiced" : "Ready for invoice",
                        systemImage: entry.isInvoiced ? "checkmark.circle.fill" : "doc.text"
                    )
                    .font(AppTheme.captionFont)
                    .foregroundStyle(entry.isInvoiced ? .green : AppTheme.secondaryText)
                } else {
                    Label("Excluded from invoice", systemImage: "minus.circle")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Spacer()

                if entry.includeInInvoice {
                    Button(canCreateInvoice ? "Create Invoice" : "Already Attached") {
                        createInvoice()
                    }
                    .font(AppTheme.captionFont)
                    .buttonStyle(.bordered)
                    .tint(AppTheme.accentColor)
                    .disabled(!canCreateInvoice)
                }
            }

            if !entry.notes.isEmpty {
                Text(entry.notes)
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }
}

#Preview {
    let client = Client(name: "Preview Client")
    let product = Product(name: "Installation", description: "", price: 0, vatRate: 21, unitType: .hour)
    let entry = WorkEntry(date: .now, client: client, hoursWorked: 3.5, product: product, quantity: 2, notes: "Mounted and checked")

    return SectionCard {
        WorkEntryRow(entry: entry, timeText: "09:00", canCreateInvoice: true) { }
    }
    .padding()
    .background(AppTheme.screenBackground)
}
