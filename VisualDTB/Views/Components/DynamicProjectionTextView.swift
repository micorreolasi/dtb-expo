import SwiftUI

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
                    .padding(.horizontal, textHasBackground ? (mode == .miniPreview ? 6 : (isCompact ? 14 : 22)) : 0)
                    .padding(.vertical, textHasBackground ? (mode == .miniPreview ? 4 : (isCompact ? 8 : 14)) : 0)
                    .background {
                        if textHasBackground {
                            RoundedRectangle(cornerRadius: mode == .miniPreview ? 4 : 10)
                                .fill(Color.black.opacity(0.85))
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
}
