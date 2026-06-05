//
//  ProductListView.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import SwiftData
import SwiftUI

struct ProductListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Product.name) private var products: [Product]
    @Query private var appSettings: [AppSettings]

    @State private var searchText = ""
    @State private var isPresentingCreateForm = false
    @State private var editProduct: Product?
    @State private var deleteBlockedMessage: String?

    var body: some View {
        VStack(spacing: 12) {
            searchBar
                .padding(.horizontal, 16)
                .padding(.top, 8)

            if filteredProducts.isEmpty {
                emptyState
            } else {
            List {
                ForEach(filteredProducts) { product in
                    NavigationLink {
                        ProductDetailView(product: product)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(product.name)
                                .font(AppTheme.sectionTitleFont)

                            HStack(spacing: 12) {
                                Text(localization.phrase(product.unitType.displayName))
                                Text(product.price.formatted(.currency(code: Locale.current.currency?.identifier ?? "EUR")))
                            }
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.secondaryText)
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(AppTheme.cardBackground)
                    .swipeActions {
                        Button(localization.phrase("Edit")) {
                            editProduct = product
                        }
                        .tint(AppTheme.accentColor)

                        Button(localization.phrase("Delete"), role: .destructive) {
                            delete(product)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            }
            .background(AppTheme.screenBackground)
        }
        .background(AppTheme.screenBackground.ignoresSafeArea())
        .navigationTitle(localization.phrase("Products"))
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
                ProductFormView()
            }
        }
        .sheet(item: $editProduct) { product in
            NavigationStack {
                ProductFormView(product: product)
            }
        }
        .alert(localization.phrase("Unable to Delete Product"), isPresented: deleteBlockedAlertBinding) {
            Button(localization.phrase("OK"), role: .cancel) { }
        } message: {
            Text(deleteBlockedMessage ?? "")
        }
        .toolbarBackground(AppTheme.screenBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.secondaryText)

            TextField(localization.phrase("Search products"), text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "shippingbox")
                .font(.system(size: 36))
                .foregroundStyle(AppTheme.secondaryText)

            Text(
                products.isEmpty
                    ? localization.phrase("No products yet")
                    : localization.phrase("No products match your search")
            )
            .font(AppTheme.sectionTitleFont)
            .foregroundStyle(AppTheme.primaryText)

            Text(
                products.isEmpty
                    ? localization.phrase("Add products or services to reuse them on invoices and registrations.")
                    : localization.phrase("Try another search term or clear the filter.")
            )
            .font(AppTheme.bodyFont)
            .foregroundStyle(AppTheme.secondaryText)

            if products.isEmpty {
                Button(localization.phrase("Add Product")) {
                    isPresentingCreateForm = true
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accentColor)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
    }

    private var filteredProducts: [Product] {
        guard !searchText.isEmpty else { return products }

        return products.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText) ||
            $0.unitType.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var deleteBlockedAlertBinding: Binding<Bool> {
        Binding(
            get: { deleteBlockedMessage != nil },
            set: { if !$0 { deleteBlockedMessage = nil } }
        )
    }

    private func delete(_ product: Product) {
        guard product.workEntries.isEmpty, product.quoteLines.isEmpty else {
            deleteBlockedMessage = localization.phrase("This product is linked to work entries or quotes and cannot be deleted.")
            return
        }

        modelContext.delete(product)
        try? modelContext.save()
    }

    private var localization: AppLocalization {
        AppLocalization(localeIdentifier: appSettings.first?.preferredLocaleIdentifier)
    }
}

#Preview {
    NavigationStack {
        ProductListView()
            .modelContainer(DashboardPreviewData.makeContainer())
    }
}
