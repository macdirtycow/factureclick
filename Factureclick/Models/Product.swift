//
//  Product.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation
import SwiftData

@Model
final class Product {
    @Attribute(.unique) var id: UUID
    var name: String
    private var productDescriptionStorage: String
    var price: Double
    var vatRate: Double
    var unitTypeRawValue: String

    var workEntries: [WorkEntry]
    var quoteLines: [QuoteLine]

    var unitType: ProductUnitType {
        get { Product.normalizedUnitType(from: unitTypeRawValue) }
        set { unitTypeRawValue = newValue.rawValue }
    }

    var description: String {
        get { productDescriptionStorage }
        set { productDescriptionStorage = newValue }
    }

    init(
        id: UUID = UUID(),
        name: String = "",
        description: String = "",
        price: Double = 0,
        vatRate: Double = 21,
        unitType: ProductUnitType = .hour,
        workEntries: [WorkEntry] = [],
        quoteLines: [QuoteLine] = []
    ) {
        self.id = id
        self.name = name
        self.productDescriptionStorage = description
        self.price = price
        self.vatRate = vatRate
        self.unitTypeRawValue = unitType.rawValue
        self.workEntries = workEntries
        self.quoteLines = quoteLines
    }

    private static func normalizedUnitType(from rawValue: String) -> ProductUnitType {
        let normalizedValue = rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if let unitType = ProductUnitType(rawValue: normalizedValue) {
            return unitType
        }

        switch normalizedValue {
        case ProductUnitType.piece.displayName.lowercased():
            return .piece
        case ProductUnitType.day.displayName.lowercased():
            return .day
        case ProductUnitType.fixed.displayName.lowercased():
            return .fixed
        case ProductUnitType.hour.displayName.lowercased():
            return .hour
        default:
            return .hour
        }
    }
}
