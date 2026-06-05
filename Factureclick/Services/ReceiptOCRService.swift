//
//  ReceiptOCRService.swift
//  Factureclick
//
//  Created by Codex on 21/04/2026.
//

import Foundation
import UIKit
import Vision

struct RecognizedReceiptDraft {
    let supplierName: String?
    let date: Date?
    let amount: Double?
    let vatAmount: Double?
    let category: ReceiptCategory?
    let rawText: String
}

enum ReceiptOCRError: LocalizedError {
    case imageCouldNotBeLoaded
    case noTextRecognized

    var errorDescription: String? {
        switch self {
        case .imageCouldNotBeLoaded:
            "The receipt image could not be read for text recognition."
        case .noTextRecognized:
            "No readable receipt text was found."
        }
    }
}

struct ReceiptOCRService {
    func recognizeReceipt(at url: URL) throws -> RecognizedReceiptDraft {
        guard let image = UIImage(contentsOfFile: url.path), let cgImage = image.cgImage else {
            throw ReceiptOCRError.imageCouldNotBeLoaded
        }

        var recognizedLines: [String] = []
        let request = VNRecognizeTextRequest { request, _ in
            let observations = request.results as? [VNRecognizedTextObservation] ?? []
            recognizedLines = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["nl-NL", "en-US", "de-DE"]

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: CGImagePropertyOrientation(image.imageOrientation))
        try handler.perform([request])

        let lines = recognizedLines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !lines.isEmpty else {
            throw ReceiptOCRError.noTextRecognized
        }

        return RecognizedReceiptDraft(
            supplierName: recognizedSupplier(from: lines),
            date: recognizedDate(from: lines),
            amount: recognizedTotalAmount(from: lines),
            vatAmount: recognizedVATAmount(from: lines),
            category: recognizedCategory(from: lines),
            rawText: lines.joined(separator: "\n")
        )
    }

    private func recognizedSupplier(from lines: [String]) -> String? {
        let ignoredFragments = [
            "receipt", "bon", "factuur", "invoice", "datum", "date", "btw", "vat", "mwst",
            "totaal", "total", "subtotal", "subtotaal", "iban", "kvk", "tax", "pin", "card"
        ]

        return lines.prefix(8).first { line in
            let normalized = line.lowercased()
            let hasIgnoredFragment = ignoredFragments.contains { normalized.contains($0) }
            return !hasIgnoredFragment && line.rangeOfCharacter(from: .letters) != nil && line.count >= 3
        }
    }

    private func recognizedDate(from lines: [String]) -> Date? {
        let text = lines.joined(separator: " ")
        let patterns = [
            #"(\d{1,2})[./-](\d{1,2})[./-](\d{2,4})"#,
            #"(\d{4})[./-](\d{1,2})[./-](\d{1,2})"#
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else {
                continue
            }

            let parts = (1..<match.numberOfRanges).compactMap { index -> Int? in
                guard let range = Range(match.range(at: index), in: text) else { return nil }
                return Int(text[range])
            }

            guard parts.count == 3 else { continue }
            let components: DateComponents
            if pattern.hasPrefix(#"(\d{4})"#) {
                components = DateComponents(year: parts[0], month: parts[1], day: parts[2])
            } else {
                let year = parts[2] < 100 ? 2000 + parts[2] : parts[2]
                components = DateComponents(year: year, month: parts[1], day: parts[0])
            }

            if let date = Calendar.current.date(from: components) {
                return date
            }
        }

        return nil
    }

    private func recognizedTotalAmount(from lines: [String]) -> Double? {
        let totalKeywords = ["totaal", "total", "te betalen", "amount due", "grand total", "summe", "gesamt"]
        let totalLineAmounts = lines
            .filter { line in totalKeywords.contains { line.lowercased().contains($0) } }
            .flatMap(amounts(in:))

        if let amount = totalLineAmounts.max() {
            return amount
        }

        return lines.flatMap(amounts(in:)).max()
    }

    private func recognizedVATAmount(from lines: [String]) -> Double? {
        let vatKeywords = ["btw", "vat", "mwst", "tax"]
        return lines
            .filter { line in vatKeywords.contains { line.lowercased().contains($0) } }
            .flatMap(amounts(in:))
            .max()
    }

    private func amounts(in line: String) -> [Double] {
        let pattern = #"(?<!\d)(?:€|eur)?\s*(\d{1,6}(?:[.,]\d{2}))(?!\d)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return []
        }

        return regex.matches(in: line, range: NSRange(line.startIndex..., in: line)).compactMap { match in
            guard let range = Range(match.range(at: 1), in: line) else { return nil }
            return Double(line[range].replacingOccurrences(of: ",", with: "."))
        }
    }

    private func recognizedCategory(from lines: [String]) -> ReceiptCategory? {
        let text = lines.joined(separator: " ").lowercased()
        if text.contains("parking") || text.contains("parkeren") { return .parking }
        if text.contains("hotel") || text.contains("lodging") { return .lodging }
        if text.contains("restaurant") || text.contains("cafe") || text.contains("lunch") { return .meals }
        if text.contains("software") || text.contains("subscription") || text.contains("abonnement") { return .software }
        if text.contains("fuel") || text.contains("benzine") || text.contains("diesel") || text.contains("train") { return .travel }
        if text.contains("equipment") || text.contains("hardware") { return .equipment }
        return nil
    }
}

private extension CGImagePropertyOrientation {
    init(_ imageOrientation: UIImage.Orientation) {
        switch imageOrientation {
        case .up:
            self = .up
        case .down:
            self = .down
        case .left:
            self = .left
        case .right:
            self = .right
        case .upMirrored:
            self = .upMirrored
        case .downMirrored:
            self = .downMirrored
        case .leftMirrored:
            self = .leftMirrored
        case .rightMirrored:
            self = .rightMirrored
        @unknown default:
            self = .up
        }
    }
}
