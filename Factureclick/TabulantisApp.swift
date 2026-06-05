//
//  FactureclickApp.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import SwiftData
import SwiftUI

@main
struct FactureclickApp: App {
    @State private var appViewModel = AppViewModel()

    private let sharedModelContainer = ModelContainerFactory.makeShared()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(appViewModel)
        }
        .modelContainer(sharedModelContainer)
    }
}
