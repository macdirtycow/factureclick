//
//  ProductFormViewModel.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation
import Observation

@Observable
final class ProductFormViewModel {
    var name: String
    var description: String
    var price: Double
    var vatRate: Double
    var unitType: ProductUnitType

    init(product: Product? = nil) {
        self.name = product?.name ?? ""
        self.description = product?.description ?? ""
        self.price = product?.price ?? 0
        self.vatRate = product?.vatRate ?? 21
        self.unitType = product?.unitType ?? .hour
    }

    var isValid: Bool {
        !trimmedName.isEmpty
    }

    func apply(to product: Product) {
        product.name = trimmedName
        product.description = description.trimmingCharacters(in: .whitespacesAndNewlines)
        product.price = price
        product.vatRate = vatRate
        product.unitType = unitType
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
