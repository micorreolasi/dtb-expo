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

        // Bounds depending on screen mode (optimizado para máxima legibilidad a distancia en TV)
        var minFont: CGFloat = 8
        var maxFont: CGFloat = 28

        switch mode {
        case .miniPreview:
            if isCompact { minFont = 8; maxFont = 16 } else { minFont = 10; maxFont = 24 }
        case .presentation:
            if isCompact { minFont = 18; maxFont = 48 } else { minFont = 24; maxFont = 72 }
        case .external:
            // Pantalla externa (TV HDMI / Proyector 1080p - 4K): texto grande, imponente y legible
            minFont = 28; maxFont = 105
        }

        let step: CGFloat = mode == .miniPreview ? 0.5 : 1
        var bestFont = minFont

        var f = maxFont
        while f >= minFont {
            defer { f -= step }

            // 1. La palabra más larga debe caber horizontalmente con margen seguro (0.58 * f)
            let longestWordWidth = CGFloat(maxWordLen) * (0.58 * f)
            if longestWordWidth > safeWidth * 0.95 { continue }

            // 2. Altura de referencia bíblica si está presente
            var refH: CGFloat = 0
            if referenceText != nil {
                let rf = max(minFont * 0.85, f * 0.75)
                let rlh = rf * 1.25
                let rmb: CGFloat = mode == .miniPreview ? 3 : max(6, f * 0.22)
                refH = rlh + rmb
            }

            let availableH = safeHeight - refH
            if availableH <= 0 { continue }

            // 3. Cálculo de líneas con ajuste de texto realista
            let charsPerLine = max(1, Int(((safeWidth * 0.95) / (0.54 * f)).rounded(.down)))
            var totalLines: CGFloat = 0
            for p in paragraphs {
                let pLen = p.trimmingCharacters(in: .whitespaces).count
                if pLen == 0 {
                    totalLines += 0.4
                } else {
                    totalLines += CGFloat(max(1, Int((Double(pLen) / Double(charsPerLine)).rounded(.up))))
                }
            }

            // 4. Altura total del cuerpo de texto
            let lineH = f * 1.28
            let totalBodyH = totalLines * lineH

            if totalBodyH <= availableH * 0.95 {
                bestFont = f
                break
            }
        }

        // Aplicar multiplicador del usuario desde la barra de herramientas
        var finalFontSize = round1(bestFont * sizeMultiplier)

        // Seguridad para no desbordar la palabra más larga
        let maxAllowedForLongestWord = (safeWidth * 0.95) / (CGFloat(maxWordLen) * 0.58)
        finalFontSize = min(finalFontSize, maxAllowedForLongestWord)
        finalFontSize = max(minFont * 0.85, min(finalFontSize, maxFont * 1.4))
        let finalLineHeight = round1(finalFontSize * 1.28)

        let refFontSize = max(minFont * 0.85, round1(finalFontSize * 0.75))
        let refLineHeight = round1(refFontSize * 1.25)
        let refMarginBottom: CGFloat = mode == .miniPreview ? 3 : max(5, (finalFontSize * 0.22).rounded())

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
