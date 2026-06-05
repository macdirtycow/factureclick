//
//  QuoteLine.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation
import SwiftData

@Model
final class QuoteLine {
    @Attribute(.unique) var id: UUID
    private var lineDescriptionStorage: String
    var quantity: Double
    var unitPrice: Double
    var vatRate: Double

    var quote: Quote
    var linkedProduct: Product?

    var description: String {
        get { lineDescriptionStorage }
        set { lineDescriptionStorage = newValue }
    }

    init(
        id: UUID = UUID(),
        description: String = "",
        quantity: Double = 1,
        unitPrice: Double = 0,
        vatRate: Double = 21,
        quote: Quote,
        linkedProduct: Product? = nil
    ) {
        self.id = id
        self.lineDescriptionStorage = description
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.vatRate = vatRate
        self.quote = quote
        self.linkedProduct = linkedProduct
    }
}
