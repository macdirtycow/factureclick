//
//  SignatureCanvasView.swift
//  Factureclick
//
//  Created by Codex on 18/04/2026.
//

import SwiftUI

struct SignatureCanvasView: View {
    @Binding var drawing: SignatureDrawing

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppTheme.elevatedBackground)

                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(AppTheme.border, style: StrokeStyle(lineWidth: 1, dash: [6, 6]))

                Canvas { context, size in
                    for stroke in drawing.strokes where !stroke.points.isEmpty {
                        var path = Path()
                        let resolvedPoints = stroke.points.map {
                            CGPoint(x: $0.x * size.width, y: $0.y * size.height)
                        }

                        guard let firstPoint = resolvedPoints.first else { continue }
                        path.move(to: firstPoint)
                        for point in resolvedPoints.dropFirst() {
                            path.addLine(to: point)
                        }
                        if resolvedPoints.count == 1 {
                            path.addEllipse(in: CGRect(x: firstPoint.x - 1, y: firstPoint.y - 1, width: 2, height: 2))
                        }

                        context.stroke(
                            path,
                            with: .color(AppTheme.primaryText),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                        )
                    }
                }

                if drawing.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "signature")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(AppTheme.secondaryText)
                        Text("Sign here")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
            }
            .contentShape(Rectangle())
            .gesture(drawingGesture(in: geometry.size))
        }
        .frame(minHeight: 220)
    }

    private func drawingGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                guard size.width > 0, size.height > 0 else { return }
                let point = SignaturePoint(
                    x: max(0, min(1, value.location.x / size.width)),
                    y: max(0, min(1, value.location.y / size.height))
                )

                if drawing.strokes.isEmpty || value.translation == .zero {
                    drawing.strokes.append(SignatureStroke(points: [point]))
                } else {
                    drawing.strokes[drawing.strokes.count - 1].points.append(point)
                }
            }
    }
}
