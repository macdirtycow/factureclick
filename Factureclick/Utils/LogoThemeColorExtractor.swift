//
//  LogoThemeColorExtractor.swift
//  Factureclick
//
//  Created by Codex on 22/04/2026.
//

import UIKit

enum LogoThemeColorExtractor {
    static func accentHex(from imageData: Data) -> String? {
        guard let image = UIImage(data: imageData),
              let cgImage = image.cgImage else {
            return nil
        }

        let width = 24
        let height = 24
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.interpolationQuality = .medium
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var buckets: [ColorBucket: Int] = [:]

        stride(from: 0, to: pixels.count, by: bytesPerPixel).forEach { index in
            let alpha = Double(pixels[index + 3]) / 255
            guard alpha > 0.35 else { return }

            let red = Double(pixels[index]) / 255
            let green = Double(pixels[index + 1]) / 255
            let blue = Double(pixels[index + 2]) / 255
            let maxChannel = max(red, green, blue)
            let minChannel = min(red, green, blue)
            let saturation = maxChannel == 0 ? 0 : (maxChannel - minChannel) / maxChannel
            let brightness = maxChannel

            guard saturation > 0.18, brightness > 0.18, brightness < 0.96 else {
                return
            }

            let bucket = ColorBucket(
                red: Int((red * 255) / 16),
                green: Int((green * 255) / 16),
                blue: Int((blue * 255) / 16)
            )
            let score = Int((saturation * 80) + (brightness * 20))
            buckets[bucket, default: 0] += max(1, score)
        }

        guard let bestBucket = buckets.max(by: { $0.value < $1.value })?.key else {
            return nil
        }

        return String(
            format: "#%02X%02X%02X",
            min(255, bestBucket.red * 16 + 8),
            min(255, bestBucket.green * 16 + 8),
            min(255, bestBucket.blue * 16 + 8)
        )
    }
}

private struct ColorBucket: Hashable {
    let red: Int
    let green: Int
    let blue: Int
}
