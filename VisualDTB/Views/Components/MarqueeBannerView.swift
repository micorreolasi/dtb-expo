import SwiftUI

struct MarqueeBannerView: View {
    @EnvironmentObject var appState: AppState
    let text: String
    let repsString: String
    let speed: MarqueeSpeed
    let mode: ProjectionMode
    let isCompact: Bool
    let triggerId: UUID

    @State private var offset: CGFloat = 400
    @State private var textWidth: CGFloat = 0
    @State private var completedCount: Int = 0

    var body: some View {
        let isExternalOrPresentation = (mode == .external || mode == .presentation)
        let scale = appState.marqueeScale
        // Altura y tamaño de tipografía óptimos para pantalla grande (TV / Proyector)
        let baseHeight: CGFloat = isExternalOrPresentation ? 96 : (isCompact ? 32 : 60)
        let baseFontSize: CGFloat = isExternalOrPresentation ? 44 : (isCompact ? 14 : 28)
        let height: CGFloat = max(28, baseHeight * scale)
        let fontSize: CGFloat = max(13, baseFontSize * scale)

        GeometryReader { proxy in
            let containerWidth = proxy.size.width
            let targetReps = Int(repsString) ?? 3

            ZStack(alignment: .leading) {
                Color(hex: "#dc2626").opacity(0.95)

                Text(text)
                    .font(.system(size: fontSize, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .background(
                        GeometryReader { textGeo in
                            Color.clear.preference(key: TextWidthPreferenceKey.self, value: textGeo.size.width)
                        }
                    )
                    .offset(x: offset)
            }
            .frame(height: height)
            .clipped()
            .onPreferenceChange(TextWidthPreferenceKey.self) { newWidth in
                self.textWidth = newWidth
                startAnimation(containerWidth: containerWidth, targetReps: targetReps)
            }
            .onChange(of: triggerId) { _ in
                completedCount = 0
                startAnimation(containerWidth: containerWidth, targetReps: targetReps)
            }
            .onChange(of: appState.marqueeScale) { _ in
                startAnimation(containerWidth: containerWidth, targetReps: targetReps)
            }
        }
        .frame(height: height)
    }

    private func startAnimation(containerWidth: CGFloat, targetReps: Int) {
        guard !text.isEmpty && textWidth > 0 else { return }
        offset = containerWidth

        let baseDuration = speed.duration

        withAnimation(.linear(duration: baseDuration)) {
            offset = -textWidth - 50
        }

        // Loop animation according to reps
        DispatchQueue.main.asyncAfter(deadline: .now() + baseDuration) {
            completedCount += 1
            if targetReps >= 999 || completedCount < targetReps {
                startAnimation(containerWidth: containerWidth, targetReps: targetReps)
            }
        }
    }
}

private struct TextWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
