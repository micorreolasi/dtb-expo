import Foundation
import CoreGraphics

// =============================================
// DYNAMIC TEXT ENGINE: AUTO-FIT PER SCREEN
// Guarantees zero text overflow and zero clipping across Phone, iPad, TV & Mini-Preview
// (port 1:1 de computeOptimalFontSize de la versión Expo)
// =============================================

struct FontConfig {
    var fontSize: CGFloat
    var lineHeight: CGFloat
    var refFontSize: CGFloat
    var refLineHeight: CGFloat
    var refMarginBottom: CGFloat
}

enum FontFitting {

    private static func round1(_ v: CGFloat) -> CGFloat { (v * 10).rounded() / 10 }

    static func computeOptimalFontSize(
        bodyText: String,
        referenceText: String?,
        safeWidth: CGFloat,
        safeHeight: CGFloat,
        mode: ProjectionMode,
        isCompact: Bool,
        sizeMultiplier: CGFloat = 1.0
    ) -> FontConfig {
        let paragraphs = bodyText.components(separatedBy: "\n")

        var maxWordLen = 1
        for p in paragraphs {
            for w in p.split(whereSeparator: { $0.isWhitespace }) where w.count > maxWordLen {
                maxWordLen = w.count
            }
        }

        // Bounds depending on screen mode
        var minFont: CGFloat = 4.5
        var maxFont: CGFloat = 22

        switch mode {
        case .miniPreview:
            if isCompact { minFont = 5; maxFont = 10 } else { minFont = 7; maxFont = 16 }
        case .presentation:
            if isCompact { minFont = 12; maxFont = 28 } else { minFont = 18; maxFont = 44 }
        case .external:
            // External display (1080p / 4K)
            minFont = 20; maxFont = 64
        }

        let step: CGFloat = mode == .miniPreview ? 0.5 : 1
        var bestFont = minFont

        var f = maxFont
        while f >= minFont {
            defer { f -= step }

            // 1. Longest word must fit horizontally in safeWidth with ample margin (0.68 * f for bold)
            let longestWordWidth = CGFloat(maxWordLen) * (0.68 * f)
            if longestWordWidth > safeWidth * 0.90 { continue }

            // 2. Reference height if present
            var refH: CGFloat = 0
            if referenceText != nil {
                let rf = max(minFont * 0.85, f * 0.82)
                let rlh = rf * 1.3
                let rmb: CGFloat = mode == .miniPreview ? 2 : max(4, f * 0.28)
                refH = rlh + rmb
            }

            let availableH = safeHeight - refH
            if availableH <= 0 { continue }

            // 3. Line wrapping calculation (conservative char width for bold)
            let charsPerLine = max(1, Int(((safeWidth * 0.90) / (0.60 * f)).rounded(.down)))
            var totalLines: CGFloat = 0
            for p in paragraphs {
                let pLen = p.trimmingCharacters(in: .whitespaces).count
                if pLen == 0 {
                    totalLines += 0.5
                } else {
                    totalLines += CGFloat(max(1, Int((Double(pLen) / Double(charsPerLine)).rounded(.up))))
                }
            }

            // 4. Total body height
            let lineH = f * 1.34
            let totalBodyH = totalLines * lineH

            if totalBodyH <= availableH * 0.90 {
                bestFont = f
                break
            }
        }

        // Apply user custom multiplier
        var finalFontSize = round1(bestFont * sizeMultiplier)

        // Strict safety check: Never allow font size so large that the longest word exceeds safeWidth * 0.90
        let maxAllowedForLongestWord = (safeWidth * 0.90) / (CGFloat(maxWordLen) * 0.68)
        finalFontSize = min(finalFontSize, maxAllowedForLongestWord)
        finalFontSize = max(minFont * 0.8, min(finalFontSize, maxFont * 1.3))
        let finalLineHeight = round1(finalFontSize * 1.34)

        let refFontSize = max(minFont * 0.85, round1(finalFontSize * 0.82))
        let refLineHeight = round1(refFontSize * 1.3)
        let refMarginBottom: CGFloat = mode == .miniPreview ? 2 : max(3, (finalFontSize * 0.28).rounded())

        return FontConfig(
            fontSize: finalFontSize,
            lineHeight: finalLineHeight,
            refFontSize: refFontSize,
            refLineHeight: refLineHeight,
            refMarginBottom: refMarginBottom
        )
    }

    // MARK: Detección de referencia bíblica en la primera línea ("Mateo 8:1")

    private static let referenceRegex = try! NSRegularExpression(
        pattern: "^([1-3]?\\s?[A-Za-zÁÉÍÓÚáéíóúñÑ]+)\\s+\\d+:\\d+(-\\d+)?$"
    )

    static func splitReference(_ content: String) -> (reference: String?, body: String) {
        let lines = content.components(separatedBy: "\n")
        let firstLine = lines.first?.trimmingCharacters(in: .whitespaces) ?? ""
        let range = NSRange(firstLine.startIndex..., in: firstLine)
        let hasReference = lines.count > 1 && referenceRegex.firstMatch(in: firstLine, range: range) != nil
        if hasReference {
            let body = lines.dropFirst().joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            return (firstLine, body)
        }
        return (nil, content)
    }

    /// Separa la letra en estrofas usando una línea vacía como separador (/\n\s*\n/).
    static func splitStanzas(_ lyrics: String) -> [String] {
        let regex = try! NSRegularExpression(pattern: "\\n\\s*\\n")
        let ns = lyrics as NSString
        var parts: [String] = []
        var last = 0
        for match in regex.matches(in: lyrics, range: NSRange(location: 0, length: ns.length)) {
            parts.append(ns.substring(with: NSRange(location: last, length: match.range.location - last)))
            last = match.range.location + match.range.length
        }
        parts.append(ns.substring(from: last))
        return parts
    }
}
