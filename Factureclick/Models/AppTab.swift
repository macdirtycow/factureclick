//
//  AppTab.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case dashboard
    case agenda
    case registrations
    case clients
    case products
    case invoices
    case settings

    var id: String { rawValue }

    var localizationKey: AppLocalization.Key {
        switch self {
        case .dashboard:
            .tabDashboard
        case .agenda:
            .tabAgenda
        case .registrations:
            .tabRegistrations
        case .clients:
            .tabClients
        case .products:
            .tabProducts
        case .invoices:
            .tabInvoices
        case .settings:
            .tabSettings
        }
    }

    var title: LocalizedStringResource {
        switch self {
        case .dashboard:
            "tab.dashboard"
        case .agenda:
            "tab.agenda"
        case .registrations:
            "tab.registrations"
        case .clients:
            "tab.clients"
        case .products:
            "tab.products"
        case .invoices:
            "tab.invoices"
        case .settings:
            "tab.settings"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard:
            "rectangle.grid.2x2"
        case .agenda:
            "calendar"
        case .registrations:
            "checklist"
        case .clients:
            "person.2"
        case .products:
            "shippingbox"
        case .invoices:
            "doc.text"
        case .settings:
            "gearshape"
        }
    }

    var headline: LocalizedStringResource {
        switch self {
        case .dashboard:
            "section.dashboard.headline"
        case .agenda:
            "section.agenda.headline"
        case .registrations:
            "section.registrations.headline"
        case .clients:
            "section.clients.headline"
        case .products:
            "section.products.headline"
        case .invoices:
            "section.invoices.headline"
        case .settings:
            "section.settings.headline"
        }
    }

    var summary: LocalizedStringResource {
        switch self {
        case .dashboard:
            "section.dashboard.summary"
        case .agenda:
            "section.agenda.summary"
        case .registrations:
            "section.registrations.summary"
        case .clients:
            "section.clients.summary"
        case .products:
            "section.products.summary"
        case .invoices:
            "section.invoices.summary"
        case .settings:
            "section.settings.summary"
        }
    }
}
