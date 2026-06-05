//
//  ProductFormView.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import SwiftData
import SwiftUI

struct ProductFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var appSettings: [AppSettings]

    private let product: Product?

    @State private var viewModel: ProductFormViewModel
    @State private var priceText: String
    @State private var percentageAdjustmentText = ""
    @State private var saveMessage: String?

    init(product: Product? = nil) {
        self.product = product
        let viewModel = ProductFormViewModel(product: product)
        _viewModel = State(initialValue: viewModel)
        _priceText = State(initialValue: Self.formatDecimal(viewModel.price))
    }

    var body: some View {
        Form {
            Section(localization.phrase("Product")) {
                TextField(localization.phrase("Product name"), text: nameBinding)
                TextField(localization.phrase("Description"), text: descriptionBinding, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
            }

            Section(localization.phrase("Pricing")) {
                TextField(localization.phrase("Price"), text: $priceText)
                    .keyboardType(.decimalPad)
                percentageAdjustmentControls
                TextField(localization.phrase("VAT rate"), value: vatRateBinding, format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.decimalPad)
                Picker(localization.phrase("Unit type"), selection: unitTypeBinding) {
                    ForEach(ProductUnitType.allCases, id: \.self) { unitType in
                        Text(localization.phrase(unitType.displayName)).tag(unitType)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.screenBackground.ignoresSafeArea())
        .navigationTitle(product == nil ? localization.phrase("New product") : localization.phrase("Edit product"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(localization.phrase("Cancel")) { dismiss() }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(localization.phrase("Save")) {
                    save()
                }
                .disabled(!canSave)
            }
        }
        .onAppear {
            applyDefaultVATIfNeeded()
            if priceText.isEmpty {
                priceText = Self.formatDecimal(viewModel.price)
            }
        }
        .alert(localization.phrase("Product"), isPresented: saveAlertBinding) {
            Button(localization.phrase("OK"), role: .cancel) { }
        } message: {
            Text(saveMessage ?? "")
        }
    }

    private var percentageAdjustmentControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField(localization.phrase("Percentage increase/decrease"), text: $percentageAdjustmentText)
                .keyboardType(.decimalPad)

            HStack {
                Button(localization.phrase("Increase")) {
                    applyPercentageAdjustment(multiplierDirection: 1)
                }
                .disabled(!canApplyPercentageAdjustment)

                Button(localization.phrase("Decrease")) {
                    applyPercentageAdjustment(multiplierDirection: -1)
                }
                .disabled(!canApplyPercentageAdjustment)
            }
            .buttonStyle(.bordered)

            if let adjustedPricePreview {
                Text("\(localization.phrase("Preview")): \(Self.formatDecimal(adjustedPricePreview))")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }

    private func save() {
        guard let parsedPrice = Self.parseDecimal(priceText) else {
            saveMessage = localization.phrase("Enter a valid price.")
            return
        }

        viewModel.price = max(0, parsedPrice)
        let target = product ?? Product()
        viewModel.apply(to: target)

        if product == nil {
            modelContext.insert(target)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            saveMessage = error.localizedDescription
        }
    }

    private func applyDefaultVATIfNeeded() {
        guard product == nil,
              viewModel.vatRate == Product().vatRate,
              let defaultVATRate = appSettings.first?.defaultVATRate else {
            return
        }

        viewModel.vatRate = defaultVATRate
    }

    private func applyPercentageAdjustment(multiplierDirection: Double) {
        guard let currentPrice = Self.parseDecimal(priceText),
              let percentage = Self.parseDecimal(percentageAdjustmentText) else {
            return
        }

        let multiplier = 1 + ((percentage / 100) * multiplierDirection)
        priceText = Self.formatDecimal(max(0, currentPrice * multiplier))
    }

    private var canSave: Bool {
        viewModel.isValid && Self.parseDecimal(priceText) != nil
    }

    private var canApplyPercentageAdjustment: Bool {
        Self.parseDecimal(priceText) != nil && Self.parseDecimal(percentageAdjustmentText) != nil
    }

    private var adjustedPricePreview: Double? {
        guard let currentPrice = Self.parseDecimal(priceText),
              let percentage = Self.parseDecimal(percentageAdjustmentText) else {
            return nil
        }

        return max(0, currentPrice * (1 + (percentage / 100)))
    }

    private var localization: AppLocalization {
        AppLocalization(localeIdentifier: appSettings.first?.preferredLocaleIdentifier)
    }

    private var nameBinding: Binding<String> { Binding(get: { viewModel.name }, set: { viewModel.name = $0 }) }
    private var descriptionBinding: Binding<String> { Binding(get: { viewModel.description }, set: { viewModel.description = $0 }) }
    private var vatRateBinding: Binding<Double> { Binding(get: { viewModel.vatRate }, set: { viewModel.vatRate = $0 }) }
    private var unitTypeBinding: Binding<ProductUnitType> { Binding(get: { viewModel.unitType }, set: { viewModel.unitType = $0 }) }
    private var saveAlertBinding: Binding<Bool> {
        Binding(
            get: { saveMessage != nil },
            set: { if !$0 { saveMessage = nil } }
        )
    }

    private static func formatDecimal(_ value: Double) -> String {
        AppFormatters.decimalFormatter(maximumFractionDigits: 2).string(from: NSNumber(value: value)) ?? ""
    }

    private static func parseDecimal(_ value: String) -> Double? {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedValue.isEmpty {
            return 0
        }

        let formatter = AppFormatters.decimalFormatter(maximumFractionDigits: 2)
        if let number = formatter.number(from: trimmedValue) {
            return number.doubleValue
        }

        let alternateSeparator = formatter.decimalSeparator == "," ? "." : ","
        let normalizedValue = trimmedValue.replacingOccurrences(of: alternateSeparator, with: formatter.decimalSeparator)
        return formatter.number(from: normalizedValue)?.doubleValue
    }
}

#Preview {
    NavigationStack {
        ProductFormView()
            .modelContainer(DashboardPreviewData.makeContainer())
    }
}
