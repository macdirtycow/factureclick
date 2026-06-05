//
//  AppLogoView.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import SwiftUI

struct AppLogoView: View {
    var showsWordmark: Bool = true
    var size: CGFloat = 44

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.accentColor, AppTheme.accentColor.opacity(0.68)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: 0) {
                    Rectangle()
                        .fill(.white.opacity(0.96))
                        .frame(width: size * 0.18, height: size * 0.62)
                        .clipShape(Capsule())

                    Spacer(minLength: 0)
                }
                .frame(width: size * 0.46, height: size * 0.56, alignment: .leading)

                VStack(alignment: .leading, spacing: size * 0.09) {
                    Capsule()
                        .fill(.white.opacity(0.96))
                        .frame(width: size * 0.38, height: size * 0.12)

                    Capsule()
                        .fill(.white.opacity(0.96))
                        .frame(width: size * 0.28, height: size * 0.12)
                }
                .offset(x: size * 0.07, y: -size * 0.03)
            }
            .frame(width: size, height: size)
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 8)

            if showsWordmark {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Factureclick")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(AppTheme.primaryText)

                    Text("Invoices and field work")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
    }
}

#Preview {
    AppLogoView()
        .padding()
        .background(AppTheme.screenBackground)
}
