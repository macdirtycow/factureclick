//
//  AppLogoView.swift
//  Factureclick
//
//  Created by Leopold on 11/04/2026.
//

import SwiftUI

struct AppLogoView: View {
    var logoData: Data? = nil
    var title: String = AppBrand.displayName
    var subtitle: String = "Invoices and field work"
    var showsWordmark: Bool = true
    var size: CGFloat = 44
    var accentColor: Color? = nil

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let logoData, let image = UIImage(data: logoData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    FactureclickLogoMark(accentColor: resolvedAccentColor)
                }
            }
            .frame(width: size, height: size)
            .background(AppTheme.elevatedBackground)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.32, style: .continuous))
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 8)

            if showsWordmark {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(AppTheme.primaryText)

                    Text(subtitle)
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
    }

    private var resolvedAccentColor: Color {
        accentColor ?? AppTheme.accentColor
    }
}

private struct FactureclickLogoMark: View {
    let accentColor: Color

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)

            ZStack {
                RoundedRectangle(cornerRadius: side * 0.32, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                accentColor,
                                accentColor.opacity(0.78),
                                Color(uiColor: .systemTeal).opacity(0.92)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: side * 0.24, style: .continuous)
                    .stroke(.white.opacity(0.28), lineWidth: max(1, side * 0.035))
                    .padding(side * 0.08)

                invoiceSheet(in: side)
                    .frame(width: side * 0.48, height: side * 0.58)
                    .offset(x: -side * 0.08, y: -side * 0.02)

                ClickPointerShape()
                    .fill(.white)
                    .frame(width: side * 0.28, height: side * 0.34)
                    .shadow(color: .black.opacity(0.18), radius: side * 0.035, x: 0, y: side * 0.02)
                    .offset(x: side * 0.18, y: side * 0.14)

                Circle()
                    .fill(.white)
                    .frame(width: side * 0.26, height: side * 0.26)
                    .overlay {
                        CheckmarkShape()
                            .trim(from: 0, to: 1)
                            .stroke(
                                accentColor,
                                style: StrokeStyle(lineWidth: max(2, side * 0.055), lineCap: .round, lineJoin: .round)
                            )
                            .padding(side * 0.075)
                    }
                    .shadow(color: .black.opacity(0.14), radius: side * 0.06, x: 0, y: side * 0.035)
                    .offset(x: side * 0.15, y: -side * 0.16)
            }
        }
    }

    private func invoiceSheet(in side: CGFloat) -> some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: side * 0.08, style: .continuous)
                .fill(.white)

            Path { path in
                path.move(to: CGPoint(x: side * 0.34, y: 0))
                path.addLine(to: CGPoint(x: side * 0.48, y: side * 0.14))
                path.addLine(to: CGPoint(x: side * 0.34, y: side * 0.14))
                path.closeSubpath()
            }
            .fill(accentColor.opacity(0.18))

            VStack(alignment: .leading, spacing: side * 0.045) {
                Capsule()
                    .fill(accentColor.opacity(0.92))
                    .frame(width: side * 0.22, height: side * 0.045)

                Capsule()
                    .fill(Color(uiColor: .systemGray3))
                    .frame(width: side * 0.30, height: side * 0.035)

                Capsule()
                    .fill(Color(uiColor: .systemGray4))
                    .frame(width: side * 0.24, height: side * 0.035)

                Spacer(minLength: 0)

                Capsule()
                    .fill(accentColor.opacity(0.16))
                    .frame(width: side * 0.26, height: side * 0.07)
            }
            .padding(side * 0.09)
        }
    }
}

private struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.minY + rect.height * 0.54))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.42, y: rect.minY + rect.height * 0.76))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.82, y: rect.minY + rect.height * 0.28))
        return path
    }
}

private struct ClickPointerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.minY + rect.height * 0.04))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.82, y: rect.minY + rect.height * 0.58))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.52, y: rect.minY + rect.height * 0.62))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.68, y: rect.minY + rect.height * 0.96))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.46, y: rect.minY + rect.height))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.31, y: rect.minY + rect.height * 0.66))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.minY + rect.height * 0.88))
        path.closeSubpath()
        return path
    }
}

#Preview {
    AppLogoView()
        .padding()
        .background(AppTheme.screenBackground)
}
