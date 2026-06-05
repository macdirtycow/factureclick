//
//  AppFormatters.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation

enum AppFormatters {
    static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("EEE")
        return formatter
    }()

    static let dayNumberFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("d")
        return formatter
    }()

    static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter
    }()

    static let shortTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()

    static let mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static func currencyFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = Locale.current.currency?.identifier ?? "EUR"
        formatter.locale = .current
        return formatter
    }

    static func decimalFormatter(maximumFractionDigits: Int) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = maximumFractionDigits
        formatter.minimumFractionDigits = 0
        formatter.locale = .current
        return formatter
    }
}
