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

    /// Color adaptativo nativo para soportar fluidamente Modo Claro y Modo Oscuro
    static func dynamic(light: String, dark: String) -> Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(Color(hex: dark)) : UIColor(Color(hex: light))
        })
    }
}

// MARK: - Paleta de colores inspirada fielmente en el Icono de la App (Proyector + iPad en azul cobalto)

enum Theme {
    // Fondos principales (Minimalismo sobrio, sin brillos artificiales ni degradados)
    // Modo oscuro: pizarra marino profundo y mate
    // Modo claro: color hueso / marfil cálido y blanco roto, sin fatiga ocular
    static let bg = Color.dynamic(light: "#f5f2eb", dark: "#0b1320")
    static let bgDeep = Color.dynamic(light: "#ebe5d8", dark: "#070c14")
    static let bgBar = Color.dynamic(light: "#efe9dd", dark: "#0e1828")
    static let panel = Color.dynamic(light: "#faf7f2", dark: "#121e33")
    static let border = Color.dynamic(light: "#d6cebf", dark: "#1e2f4d")

    // Textos con balance óptico en tonos tierra, piedra y pizarra mate
    static let text = Color.dynamic(light: "#292524", dark: "#f1f5f9")
    static let textBright = Color.dynamic(light: "#1c1917", dark: "#ffffff")
    static let textSoft = Color.dynamic(light: "#57534e", dark: "#94a3b8")
    static let muted = Color.dynamic(light: "#78716c", dark: "#64748b")
    static let dim = Color.dynamic(light: "#a8a29e", dark: "#475569")
    static let faint = Color.dynamic(light: "#e7e2d7", dark: "#1e293b")

    // Colores del Icono de la App (Azul cobalto clásico, limpio y profesional, mate)
    static let blue = Color.dynamic(light: "#1d4ed8", dark: "#3b82f6")
    static let lightBlue = Color.dynamic(light: "#2563eb", dark: "#60a5fa")
    static let sky = Color.dynamic(light: "#1d4ed8", dark: "#3b82f6") // Alias sobrio a azul cobalto
    static let royalBlue = Color(hex: "#1d4ed8")
    static let iceBlue = Color.dynamic(light: "#e2ebf6", dark: "#1e293b")

    // Colores semánticos en tonos sobrios y mates (sin fluorescencias ni neones)
    static let green = Color(hex: "#15803d")
    static let greenLight = Color(hex: "#16a34a")
    static let red = Color(hex: "#b91c1c")
    static let amber = Color(hex: "#b45309")
    static let amberLight = Color(hex: "#d97706")
    static let violet = Color.dynamic(light: "#1d4ed8", dark: "#3b82f6") // Alias a azul cobalto para evitar morados cliché
    static let violetLight = Color.dynamic(light: "#2563eb", dark: "#60a5fa")
    static let marqueeRed = Color(.sRGB, red: 185 / 255, green: 28 / 255, blue: 28 / 255, opacity: 0.95)
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
