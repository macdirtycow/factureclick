//
//  ProductDetailView.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import SwiftData
import SwiftUI

struct ProductDetailView: View {
    let product: Product

    @Query private var appSettings: [AppSettings]
    @State private var editProduct: Product?

    var body: some View {
        List {
            Section(localization.phrase("Product")) {
                detailRow(title: localization.phrase("Name"), value: product.name)
                detailRow(title: localization.phrase("Description"), value: product.description)
                detailRow(title: localization.phrase("Unit type"), value: localization.phrase(product.unitType.displayName))
            }
            .listRowBackground(AppTheme.cardBackground)

            Section(localization.phrase("Pricing")) {
                detailRow(title: localization.phrase("Price"), value: product.price.formatted(.currency(code: Locale.current.currency?.identifier ?? "EUR")))
                detailRow(title: localization.text(.vat), value: "\(product.vatRate.formatted(.number.precision(.fractionLength(0...2))))%")
            }
            .listRowBackground(AppTheme.cardBackground)

            Section(localization.phrase("Usage")) {
                detailRow(title: localization.phrase("Work entries"), value: "\(product.workEntries.count)")
                detailRow(title: localization.phrase("Quote lines"), value: "\(product.quoteLines.count)")
            }
            .listRowBackground(AppTheme.cardBackground)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.screenBackground.ignoresSafeArea())
        .navigationTitle(product.name)
        .toolbarBackground(AppTheme.screenBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(localization.phrase("Edit")) {
                    editProduct = product
                }
            }
        }
        .sheet(item: $editProduct) { product in
            NavigationStack {
                ProductFormView(product: product)
            }
        }
    }

    @ViewBuilder
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(AppTheme.secondaryText)

            Spacer()

            Text(value.isEmpty ? localization.phrase("Not set") : value)
                .multilineTextAlignment(.trailing)
        }
    }

    private var localization: AppLocalization {
        AppLocalization(localeIdentifier: appSettings.first?.preferredLocaleIdentifier)
    }
}
