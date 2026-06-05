//
//  ModelEnums.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import Foundation

enum ProductUnitType: String, CaseIterable, Codable {
    case hour
    case piece
    case day
    case fixed

    var displayName: String {
        switch self {
        case .hour:
            "Hour"
        case .piece:
            "Piece"
        case .day:
            "Day"
        case .fixed:
            "Fixed"
        }
    }
}

enum InvoiceStatus: String, CaseIterable, Codable {
    case draft
    case sent
    case paid
    case overdue

    var displayName: String {
        switch self {
        case .draft:
            "Draft"
        case .sent:
            "Sent"
        case .paid:
            "Paid"
        case .overdue:
            "Overdue"
        }
    }
}

enum InvoiceDocumentType: String, CaseIterable, Codable, Identifiable {
    case standard
    case credit

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .standard:
            "Factuur"
        case .credit:
            "Creditfactuur"
        }
    }
}

enum InvoiceEmailDeliveryStatus: String, CaseIterable, Codable {
    case notSent
    case initiated
    case sent
    case failed

    var displayName: String {
        switch self {
        case .notSent:
            "Not Sent"
        case .initiated:
            "Initiated"
        case .sent:
            "Sent"
        case .failed:
            "Failed"
        }
    }
}

enum InvoiceReminderLevel: String, CaseIterable, Codable, Identifiable {
    case friendly
    case second
    case final

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .friendly:
            "Friendly Reminder"
        case .second:
            "Second Reminder"
        case .final:
            "Final Reminder"
        }
    }

    var subjectPrefix: String {
        switch self {
        case .friendly:
            "Friendly payment reminder"
        case .second:
            "Second payment reminder"
        case .final:
            "Final payment reminder"
        }
    }
}

enum InvoiceReminderStatus: String, CaseIterable, Codable, Identifiable {
    case draft
    case sent

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .draft:
            "Draft"
        case .sent:
            "Sent"
        }
    }
}

enum RecurringInvoiceFrequency: String, CaseIterable, Codable, Identifiable {
    case weekly
    case monthly
    case quarterly
    case yearly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .weekly:
            "Weekly"
        case .monthly:
            "Monthly"
        case .quarterly:
            "Quarterly"
        case .yearly:
            "Yearly"
        }
    }
}

enum QuoteStatus: String, CaseIterable, Codable, Identifiable {
    case draft
    case sent
    case accepted
    case rejected
    case expired

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .draft:
            "Draft"
        case .sent:
            "Sent"
        case .accepted:
            "Accepted"
        case .rejected:
            "Rejected"
        case .expired:
            "Expired"
        }
    }
}
