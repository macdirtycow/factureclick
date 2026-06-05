//
//  SectionCard.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import SwiftUI

struct SectionCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(
                color: Color.black.opacity(AppTheme.shadowOpacity),
                radius: 18,
                x: 0,
                y: 10
            )
    }
}

#Preview {
    SectionCard {
        Text("Preview")
    }
    .padding()
    .background(AppTheme.screenBackground)
}
