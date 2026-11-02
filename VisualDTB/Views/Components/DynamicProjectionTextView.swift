import SwiftUI
import UIKit
import CoreText

struct DynamicProjectionTextView: View {
    let content: String
    let mode: ProjectionMode
    let textColorHex: String
    let textHasBackground: Bool
    var sizeMultiplier: CGFloat = 1.0
    var isCompact: Bool = false

    var body: some View {
        GeometryReader { proxy in
            let clean = content.trimmingCharacters(in: .whitespacesAndNewlines)
            if clean.isEmpty {
                Color.clear
            } else {
                let padHoriz: CGFloat = {
                    switch mode {
                    case .miniPreview: return isCompact ? 6 : 8
                    case .presentation: return isCompact ? 16 : 24
                    case .external: return 40
                    }
                }()
                let padTop: CGFloat = {
                    switch mode {
                    case .miniPreview: return isCompact ? 4 : 6
                    case .presentation: return isCompact ? 16 : 24
                    case .external: return 32
                    }
                }()
                let padBottom: CGFloat = {
                    switch mode {
                    case .miniPreview: return isCompact ? 4 : 6
                    case .presentation: return isCompact ? 16 : 24
                    case .external: return 32
                    }
                }()

                let safeW = max(40, proxy.size.width - padHoriz * 2)
                let safeH = max(30, proxy.size.height - (padTop + padBottom))

                let (ref, body) = FontFitting.splitReference(clean)
                let config = FontFitting.computeOptimalFontSize(
                    bodyText: body,
                    referenceText: ref,
                    safeWidth: safeW,
                    safeHeight: safeH,
                    mode: mode,
                    isCompact: isCompact,
                    sizeMultiplier: sizeMultiplier
                )

                let textColor = Color(hex: textColorHex)
                let refColor = textColorHex.lowercased() == "#ffffff" ? Color(hex: "#93c5fd") : textColor

                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    if textHasBackground {
                        stripedText(
                            ref: ref,
                            body: body,
                            config: config,
                            safeW: safeW,
                            safeH: safeH,
                            textColor: textColor,
                            refColor: refColor
                        )
                    } else {
                    VStack(spacing: config.refMarginBottom) {
                        if let ref {
                            Text(ref)
                                .font(.system(size: config.refFontSize, weight: .bold))
                                .foregroundStyle(refColor)
                                .multilineTextAlignment(.center)
                                .shadow(color: .black.opacity(0.9), radius: 8, x: -1, y: 1)
                                .minimumScaleFactor(0.7)
                                .allowsTightening(true)
                                .frame(maxWidth: safeW)
                        }

                        Text(body)
                            .font(.system(size: config.fontSize, weight: .bold))
                            .foregroundStyle(textColor)
                            .multilineTextAlignment(.center)
                            .lineSpacing(max(0, config.lineHeight - config.fontSize))
                            .shadow(color: .black.opacity(0.9), radius: 10, x: -1, y: 1)
                            .minimumScaleFactor(0.65)
                            .allowsTightening(true)
                            .frame(maxWidth: safeW)
                    }
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding(.horizontal, padHoriz)
                .padding(.top, padTop)
                .padding(.bottom, padBottom)
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
    }

    // MARK: - Fondo por línea (franja negra detrás de cada renglón)

    @ViewBuilder
    private func stripedText(
        ref: String?,
        body: String,
        config: FontConfig,
        safeW: CGFloat,
        safeH: CGFloat,
        textColor: Color,
        refColor: Color
    ) -> some View {
        let layout = StripedTextLayout.make(
            ref: ref,
            body: body,
            fontSize: config.fontSize,
            refFontSize: config.refFontSize,
            refMargin: config.refMarginBottom,
            safeWidth: safeW,
            safeHeight: safeH
        )
        // Con letra negra, la franja se invierte a blanca para que el texto siga siendo legible.
        let stripeColor: Color = textColorHex.lowercased() == "#000000" ? .white : .black

        VStack(spacing: layout.refMargin) {
            if !layout.refLines.isEmpty {
                VStack(spacing: layout.refMetrics.gap) {
                    ForEach(Array(layout.refLines.enumerated()), id: \.offset) { _, line in
                        stripeLine(line, metrics: layout.refMetrics, color: refColor, stripe: stripeColor, maxWidth: safeW)
                    }
                }
            }
            VStack(spacing: layout.bodyMetrics.gap) {
                ForEach(Array(layout.bodyLines.enumerated()), id: \.offset) { _, line in
                    if line.isEmpty {
                        Color.clear.frame(height: layout.bodyMetrics.fontSize * 0.4)
                    } else {
                        stripeLine(line, metrics: layout.bodyMetrics, color: textColor, stripe: stripeColor, maxWidth: safeW)
                    }
                }
            }
        }
        .frame(maxWidth: safeW)
    }

    private func stripeLine(_ line: String, metrics: StripeMetrics, color: Color, stripe: Color, maxWidth: CGFloat) -> some View {
        Text(line)
            .font(.system(size: metrics.fontSize, weight: .bold))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .allowsTightening(true)
            .padding(.horizontal, metrics.padH)
            .padding(.vertical, metrics.padV)
            .background(stripe, in: RoundedRectangle(cornerRadius: metrics.radius))
            .frame(maxWidth: maxWidth)
    }
}

// MARK: - Cálculo de renglones para el fondo por línea

struct StripeMetrics {
    let fontSize: CGFloat
    let padH: CGFloat
    let padV: CGFloat
    let gap: CGFloat
    let radius: CGFloat
    let lineHeight: CGFloat

    init(fontSize f: CGFloat) {
        fontSize = f
        padH = max(3, (f * 0.3).rounded())
        padV = max(1, (f * 0.08).rounded())
        gap = max(1, (f * 0.06).rounded())
        radius = max(2, f * 0.14)
        lineHeight = UIFont.systemFont(ofSize: f, weight: .bold).lineHeight
    }
}

struct StripedTextLayout {
    let refLines: [String]
    let bodyLines: [String]
    let refMetrics: StripeMetrics
    let bodyMetrics: StripeMetrics
    let refMargin: CGFloat

    /// Parte el texto en renglones reales (CoreText) con el tamaño calculado.
    /// Si el bloque con las franjas no cabe en la altura disponible, reduce la letra poco a poco.
    static func make(
        ref: String?,
        body: String,
        fontSize: CGFloat,
        refFontSize: CGFloat,
        refMargin: CGFloat,
        safeWidth: CGFloat,
        safeHeight: CGFloat
    ) -> StripedTextLayout {
        var scale: CGFloat = 1
        var result = build(ref: ref, body: body, fontSize: fontSize, refFontSize: refFontSize,
                           refMargin: refMargin, safeWidth: safeWidth, scale: scale)
        var attempts = 0
        while result.height > safeHeight && attempts < 30 && fontSize * scale > 6 {
            scale *= 0.94
            attempts += 1
            result = build(ref: ref, body: body, fontSize: fontSize, refFontSize: refFontSize,
                           refMargin: refMargin, safeWidth: safeWidth, scale: scale)
        }
        return result.layout
    }

    private static func build(
        ref: String?,
        body: String,
        fontSize: CGFloat,
        refFontSize: CGFloat,
        refMargin: CGFloat,
        safeWidth: CGFloat,
        scale: CGFloat
    ) -> (layout: StripedTextLayout, height: CGFloat) {
        let bodyM = StripeMetrics(fontSize: fontSize * scale)
        let refM = StripeMetrics(fontSize: refFontSize * scale)
        let margin = refMargin * scale

        let bodyLines = wrapLines(body, fontSize: bodyM.fontSize, width: max(20, safeWidth - bodyM.padH * 2))
        let refLines = ref.map { wrapLines($0, fontSize: refM.fontSize, width: max(20, safeWidth - refM.padH * 2)) } ?? []

        func blockHeight(_ lines: [String], _ m: StripeMetrics) -> CGFloat {
            guard !lines.isEmpty else { return 0 }
            let rows = lines.reduce(CGFloat(0)) { acc, l in
                acc + (l.isEmpty ? m.fontSize * 0.4 : m.lineHeight + m.padV * 2)
            }
            return rows + CGFloat(lines.count - 1) * m.gap
        }

        var height = blockHeight(bodyLines, bodyM)
        if !refLines.isEmpty { height += blockHeight(refLines, refM) + margin }

        let layout = StripedTextLayout(refLines: refLines, bodyLines: bodyLines,
                                       refMetrics: refM, bodyMetrics: bodyM, refMargin: margin)
        return (layout, height)
    }

    /// Divide el texto en los renglones que ocupará con la fuente bold del sistema y el ancho dado.
    /// Los saltos de línea del texto se respetan; las líneas vacías se conservan como "".
    static func wrapLines(_ text: String, fontSize: CGFloat, width: CGFloat) -> [String] {
        let font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
        var lines: [String] = []

        for paragraph in text.components(separatedBy: "\n") {
            let trimmed = paragraph.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                lines.append("")
                continue
            }
            let attr = NSAttributedString(string: trimmed, attributes: [.font: font])
            let typesetter = CTTypesetterCreateWithAttributedString(attr as CFAttributedString)
            let ns = trimmed as NSString
            var start = 0
            while start < ns.length {
                var count = CTTypesetterSuggestLineBreak(typesetter, start, Double(width))
                if count <= 0 { count = 1 }
                count = min(count, ns.length - start)
                let line = ns.substring(with: NSRange(location: start, length: count))
                    .trimmingCharacters(in: .whitespaces)
                if !line.isEmpty { lines.append(line) }
                start += count
            }
        }

        // Quitar líneas vacías al inicio y al final
        while lines.first == "" { lines.removeFirst() }
        while lines.last == "" { lines.removeLast() }
        return lines
    }
}
