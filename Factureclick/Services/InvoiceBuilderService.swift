//
//  InvoiceBuilderService.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation

enum InvoiceBuilderMode: String, CaseIterable, Identifiable {
    case manual
    case automatic
    case mixed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .manual:
            "Handmatig"
        case .automatic:
            "Uit registraties"
        case .mixed:
            "Gemengd"
        }
    }
}

enum InvoiceLineKind: String, CaseIterable, Identifiable, Hashable {
    case productService
    case discount
    case extraCharge
    case travelCost
    case materialCost
    case manualAdjustment

    var id: String { rawValue }

    var title: String {
        switch self {
        case .productService:
            "Product / dienst"
        case .discount:
            "Korting"
        case .extraCharge:
            "Extra kosten"
        case .travelCost:
            "Reiskosten"
        case .materialCost:
            "Materiaalkosten"
        case .manualAdjustment:
            "Handmatige correctie"
        }
    }

    var defaultDescription: String {
        switch self {
        case .productService:
            "Nieuwe regel"
        case .discount:
            "Korting"
        case .extraCharge:
            "Extra kosten"
        case .travelCost:
            "Reiskosten"
        case .materialCost:
            "Materiaalkosten"
        case .manualAdjustment:
            "Handmatige correctie"
        }
    }
}

struct InvoiceLineDraft: Identifiable, Hashable {
    let id: UUID
    var kind: InvoiceLineKind
    var description: String
    var quantity: Double
    var unitPrice: Double
    var vatRate: Double
    var linkedWorkEntryIDs: [UUID]
    var linkedProductID: UUID?

    init(
        id: UUID = UUID(),
        kind: InvoiceLineKind = .productService,
        description: String,
        quantity: Double,
        unitPrice: Double,
        vatRate: Double,
        linkedWorkEntryIDs: [UUID] = [],
        linkedProductID: UUID? = nil
    ) {
        self.id = id
        self.kind = kind
        self.description = description
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.vatRate = vatRate
        self.linkedWorkEntryIDs = linkedWorkEntryIDs
        self.linkedProductID = linkedProductID
    }
}

struct InvoiceVATBreakdown: Identifiable, Hashable {
    let id = UUID()
    let rate: Double
    let taxableAmount: Double
    let vatAmount: Double
}

struct InvoiceDraftTotals {
    let subtotal: Double
    let netSubtotal: Double
    let vat: Double
    let total: Double
    let gross: Double
    let discounts: Double
    let extraCharges: Double
    let travelCosts: Double
    let materialCosts: Double
    let manualAdjustments: Double
    let partnerShare: Double
    let netIncome: Double
    let vatBreakdown: [InvoiceVATBreakdown]
}

struct InvoiceBuilderService {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func automaticLines(
        from entries: [WorkEntry],
        groupingMode: InvoiceGroupingMode,
        defaultVATRate: Double
    ) -> [InvoiceLineDraft] {
        switch groupingMode {
        case .hours:
            groupedByHours(entries, defaultVATRate: defaultVATRate)
        case .hoursAndProducts:
            groupedByHoursAndProducts(entries, defaultVATRate: defaultVATRate)
        case .product:
            groupedByProduct(entries, defaultVATRate: defaultVATRate)
        case .date:
            groupedByDate(entries, defaultVATRate: defaultVATRate)
        case .serviceType:
            groupedByServiceType(entries, defaultVATRate: defaultVATRate)
        }
    }

    private func splitEntriesByBillingUnit(_ entries: [WorkEntry]) -> (hourEntries: [WorkEntry], productEntries: [WorkEntry]) {
        let hourEntries = entries.filter { entry in
            entry.product?.unitType == .hour || entry.product == nil
        }
        let productEntries = entries.filter { entry in
            if let product = entry.product {
                return product.unitType != .hour
            }
            return false
        }

        return (hourEntries, productEntries)
    }

    private func groupedByHoursAndProducts(_ entries: [WorkEntry], defaultVATRate: Double) -> [InvoiceLineDraft] {
        let splitEntries = splitEntriesByBillingUnit(entries)

        return (groupedByHours(splitEntries.hourEntries, defaultVATRate: defaultVATRate)
            + groupedByProduct(splitEntries.productEntries, defaultVATRate: defaultVATRate))
            .sorted { $0.description.localizedCaseInsensitiveCompare($1.description) == .orderedAscending }
    }

    private func groupedByHours(_ entries: [WorkEntry], defaultVATRate: Double) -> [InvoiceLineDraft] {
        let splitEntries = splitEntriesByBillingUnit(entries)

        struct GroupKey: Hashable {
            let productID: UUID?
            let hourlyRate: Double
            let vatRate: Double
        }

        let grouped = Dictionary(grouping: splitEntries.hourEntries) { entry in
            GroupKey(
                productID: entry.product?.id,
                hourlyRate: entry.effectiveHourlyRate,
                vatRate: entry.product?.vatRate ?? defaultVATRate
            )
        }

        let hourLines: [InvoiceLineDraft] = grouped.values.compactMap { group in
            guard let first = group.first else { return nil }

            let description: String
            if let product = first.product {
                description = product.name
            } else {
                description = "Gewerkte uren"
            }

            return InvoiceLineDraft(
                kind: .productService,
                description: description,
                quantity: group.reduce(0) { $0 + $1.hoursWorked },
                unitPrice: first.effectiveHourlyRate,
                vatRate: first.product?.vatRate ?? defaultVATRate,
                linkedWorkEntryIDs: group.map(\.id)
            )
        }

        let productLines = groupedByProduct(splitEntries.productEntries, defaultVATRate: defaultVATRate)

        return (hourLines + productLines)
            .sorted { $0.description.localizedCaseInsensitiveCompare($1.description) == .orderedAscending }
    }

    private func groupedByProduct(_ entries: [WorkEntry], defaultVATRate: Double) -> [InvoiceLineDraft] {
        struct GroupKey: Hashable {
            let productID: UUID?
            let hourlyRate: Double
        }

        let grouped = Dictionary(grouping: entries) { entry in
            GroupKey(
                productID: entry.product?.id,
                hourlyRate: entry.effectiveHourlyRate
            )
        }

        return grouped.values.compactMap { group in
            guard let first = group.first else { return nil }

            if let product = first.product {
                let quantity = product.unitType == .hour
                    ? group.reduce(0) { $0 + $1.hoursWorked }
                    : group.reduce(0) { $0 + $1.quantity }
                let unitPrice = product.unitType == .hour ? first.effectiveHourlyRate : product.price

                return InvoiceLineDraft(
                    kind: .productService,
                    description: product.name,
                    quantity: quantity,
                    unitPrice: unitPrice,
                    vatRate: product.vatRate,
                    linkedWorkEntryIDs: group.map(\.id)
                )
            } else {
                return InvoiceLineDraft(
                    kind: .productService,
                    description: "Algemeen werk",
                    quantity: group.reduce(0) { $0 + $1.hoursWorked },
                    unitPrice: first.effectiveHourlyRate,
                    vatRate: defaultVATRate,
                    linkedWorkEntryIDs: group.map(\.id)
                )
            }
        }
        .sorted { $0.description.localizedCaseInsensitiveCompare($1.description) == .orderedAscending }
    }

    private func groupedByDate(_ entries: [WorkEntry], defaultVATRate: Double) -> [InvoiceLineDraft] {
        let grouped = Dictionary(grouping: entries) { calendar.startOfDay(for: $0.date) }

        return grouped.keys.sorted().compactMap { date in
            guard let group = grouped[date] else { return nil }

            let total = group.reduce(0.0) { partial, entry in
                if let product = entry.product {
                    let quantity = product.unitType == .hour ? entry.hoursWorked : entry.quantity
                    let unitPrice = product.unitType == .hour ? entry.effectiveHourlyRate : product.price
                    return partial + (quantity * unitPrice)
                }
                return partial + entry.billableAmount
            }

            let vatRate = group.compactMap(\.product?.vatRate).first ?? defaultVATRate

            return InvoiceLineDraft(
                kind: .productService,
                description: "Werk op \(AppFormatters.mediumDateFormatter.string(from: date))",
                quantity: 1,
                unitPrice: total,
                vatRate: vatRate,
                linkedWorkEntryIDs: group.map(\.id)
            )
        }
    }

    private func groupedByServiceType(_ entries: [WorkEntry], defaultVATRate: Double) -> [InvoiceLineDraft] {
        struct GroupKey: Hashable {
            let label: String
            let unitType: ProductUnitType?
            let hourlyRate: Double?
        }

        let grouped = Dictionary(grouping: entries) { entry in
            if let product = entry.product {
                return GroupKey(
                    label: product.unitType.displayName,
                    unitType: product.unitType,
                    hourlyRate: product.unitType == .hour ? entry.effectiveHourlyRate : nil
                )
            } else {
                return GroupKey(
                    label: "Algemene dienst",
                    unitType: .hour,
                    hourlyRate: entry.effectiveHourlyRate
                )
            }
        }

        return grouped.values.compactMap { group in
            guard let first = group.first else { return nil }

            if let product = first.product {
                let quantity = product.unitType == .hour
                    ? group.reduce(0) { $0 + $1.hoursWorked }
                    : group.reduce(0) { $0 + $1.quantity }
                let unitPrice = product.unitType == .hour ? first.effectiveHourlyRate : product.price

                return InvoiceLineDraft(
                    kind: .productService,
                    description: product.unitType == .hour ? "\(product.unitType.displayName) diensten" : product.unitType.displayName,
                    quantity: quantity,
                    unitPrice: unitPrice,
                    vatRate: product.vatRate,
                    linkedWorkEntryIDs: group.map(\.id)
                )
            } else {
                return InvoiceLineDraft(
                    kind: .productService,
                    description: "Algemene dienst",
                    quantity: group.reduce(0) { $0 + $1.hoursWorked },
                    unitPrice: first.effectiveHourlyRate,
                    vatRate: defaultVATRate,
                    linkedWorkEntryIDs: group.map(\.id)
                )
            }
        }
        .sorted { $0.description.localizedCaseInsensitiveCompare($1.description) == .orderedAscending }
    }
}
