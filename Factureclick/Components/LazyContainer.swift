//
//  LazyContainer.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import SwiftUI

struct LazyContainer<Content: View>: View {
    private let content: () -> Content
    @State private var hasAppeared = false

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        Group {
            if hasAppeared {
                content()
            } else {
                Color.clear
            }
        }
        .onAppear {
            hasAppeared = true
        }
    }
}
