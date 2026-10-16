import SwiftUI

// MARK: - Colores hexadecimales (#RGB, #RRGGBB y #RRGGBBAA como en React Native)

extension Color {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        if s.count == 3 { s = s.map { "\($0)\($0)" }.joined() }
        var value: UInt64 = 0
        Scanner(string: s).scanHexInt64(&value)
        let r, g, b, a: Double
        if s.count == 8 {
            r = Double((value >> 24) & 0xFF) / 255
            g = Double((value >> 16) & 0xFF) / 255
            b = Double((value >> 8) & 0xFF) / 255
            a = Double(value & 0xFF) / 255
        } else {
            r = Double((value >> 16) & 0xFF) / 255
            g = Double((value >> 8) & 0xFF) / 255
            b = Double(value & 0xFF) / 255
            a = 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

enum Theme {
    static let bg = Color(hex: "#0f172a")
    static let bgDeep = Color(hex: "#090d16")
    static let bgBar = Color(hex: "#0b1120")
    static let panel = Color(hex: "#1e293b")
    static let border = Color(hex: "#334155")
    static let text = Color(hex: "#e2e8f0")
    static let textBright = Color(hex: "#f8fafc")
    static let textSoft = Color(hex: "#cbd5e1")
    static let muted = Color(hex: "#94a3b8")
    static let dim = Color(hex: "#64748b")
    static let faint = Color(hex: "#475569")
    static let blue = Color(hex: "#3b82f6")
    static let lightBlue = Color(hex: "#60a5fa")
    static let sky = Color(hex: "#38bdf8")
    static let green = Color(hex: "#10b981")
    static let greenLight = Color(hex: "#34d399")
    static let red = Color(hex: "#ef4444")
    static let amber = Color(hex: "#f59e0b")
    static let amberLight = Color(hex: "#fbbf24")
    static let violet = Color(hex: "#8b5cf6")
    static let violetLight = Color(hex: "#c4b5fd")
    static let marqueeRed = Color(.sRGB, red: 220 / 255, green: 38 / 255, blue: 38 / 255, opacity: 0.95)
}

// MARK: - Información de layout (equivalente a useWindowDimensions)

struct LayoutInfo: Equatable {
    var width: CGFloat = 1024
    var height: CGFloat = 768

    var isLandscape: Bool { width > height }
    var isPortrait: Bool { height >= width }
    var isCompact: Bool { min(width, height) < 600 }
}

private struct LayoutInfoKey: EnvironmentKey {
    static let defaultValue = LayoutInfo()
}

extension EnvironmentValues {
    var layoutInfo: LayoutInfo {
        get { self[LayoutInfoKey.self] }
        set { self[LayoutInfoKey.self] = newValue }
    }
}

// MARK: - Helpers de vista

extension View {
    /// Fondo redondeado con borde (patrón muy usado en la UI original).
    func chip(fill: Color, border: Color? = nil, radius: CGFloat = 6, lineWidth: CGFloat = 1) -> some View {
        self
            .background(fill, in: RoundedRectangle(cornerRadius: radius))
            .overlay {
                if let border {
                    RoundedRectangle(cornerRadius: radius).stroke(border, lineWidth: lineWidth)
                }
            }
    }

    func bottomBorder(_ color: Color = Theme.panel) -> some View {
        overlay(alignment: .bottom) { Rectangle().fill(color).frame(height: 1) }
    }

    func trailingBorder(_ color: Color = Theme.panel) -> some View {
        overlay(alignment: .trailing) { Rectangle().fill(color).frame(width: 1) }
    }
}

/// TextField con placeholder de color personalizado.
struct DarkTextField: View {
    let placeholder: String
    @Binding var text: String
    var fontSize: CGFloat = 14
    var color: Color = Theme.text
    var keyboard: UIKeyboardType = .default
    var autocapitalize = true
    var onSubmit: (() -> Void)? = nil

    var body: some View {
        TextField("", text: $text, prompt: Text(placeholder).foregroundColor(Theme.dim))
            .font(.system(size: fontSize))
            .foregroundStyle(color)
            .keyboardType(keyboard)
            .textInputAutocapitalization(autocapitalize ? .sentences : .never)
            .autocorrectionDisabled(!autocapitalize)
            .onSubmit { onSubmit?() }
    }
}

/// Editor multilínea con placeholder (TextInput multiline).
struct DarkTextEditor: View {
    let placeholder: String
    @Binding var text: String
    var fontSize: CGFloat = 16

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .font(.system(size: fontSize))
                .foregroundStyle(Theme.text)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, -4)
                .padding(.vertical, -8)
            if text.isEmpty {
                Text(placeholder)
                    .font(.system(size: fontSize))
                    .foregroundStyle(Theme.dim)
                    .allowsHitTesting(false)
            }
        }
    }
}

/// Estado vacío reutilizable (columna derecha de Biblia y Canciones).
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(Theme.faint)
                .padding(.bottom, 12)
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(Theme.dim)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.top, 6)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Botón principal (styles.projectButton).
struct ProjectButton: View {
    let title: String
    var icon: String? = nil
    var color: Color = Theme.blue
    var expand = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon { Image(systemName: icon).font(.system(size: 15)) }
                Text(title).font(.system(size: 14, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(12)
            .frame(maxWidth: expand ? .infinity : nil)
            .background(color, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

/// Título grande de módulo (styles.mockTitle).
struct ModuleTitle: View {
    let text: String
    var size: CGFloat = 24
    var bottom: CGFloat = 20

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(Theme.text)
            .padding(.bottom, bottom)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
