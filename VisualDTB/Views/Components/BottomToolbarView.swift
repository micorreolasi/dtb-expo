import SwiftUI

struct BottomToolbarView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.layoutInfo) var layout

    private let colors = ["#ffffff", "#000000", "#facc15", "#38bdf8", "#4ade80", "#fb923c", "#f472b6"]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: layout.isCompact ? 6 : 12) {
                // 1. Botones de Acción (Limpiar, Pausa, Blackout, Pantalla Completa, Playlist)
                actionButtonsGroup

                separator

                // 2. Control de Brillo
                brightnessGroup

                separator

                // 3. Selector de Color de Letra
                textColorGroup

                separator

                // 4. Fondo de Letra (ON / OFF)
                textBackgroundGroup
            }
            .padding(.horizontal, 10)
            .padding(.trailing, 20)
            .frame(height: layout.isCompact ? 40 : 50)
        }
        .background(Theme.panel)
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.border).frame(height: 1)
        }
    }

    private var actionButtonsGroup: some View {
        HStack(spacing: layout.isCompact ? 3 : 6) {
            // Limpiar
            Button {
                appState.projection = .text("")
                appState.currentDocPath = ""
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "trash")
                        .font(.system(size: layout.isCompact ? 11 : 13))
                    Text("Limpiar")
                        .font(.system(size: layout.isCompact ? 10 : 12, weight: .bold))
                }
                .foregroundStyle(Theme.amber)
                .padding(.horizontal, layout.isCompact ? 6 : 10)
                .frame(height: layout.isCompact ? 26 : 32)
                .chip(fill: Theme.amber.opacity(0.15), border: Theme.amber.opacity(0.3), radius: 6)
            }
            .buttonStyle(.plain)

            // Pausar
            Button {
                appState.isPaused.toggle()
            } label: {
                Image(systemName: "pause.fill")
                    .font(.system(size: layout.isCompact ? 11 : 14))
                    .foregroundStyle(appState.isPaused ? .white : Theme.textSoft)
                    .frame(width: layout.isCompact ? 26 : 32, height: layout.isCompact ? 26 : 32)
                    .chip(
                        fill: appState.isPaused ? Theme.blue : Theme.border,
                        radius: 6
                    )
            }
            .buttonStyle(.plain)

            // Blackout
            Button {
                appState.isBlackout.toggle()
            } label: {
                Image(systemName: appState.isBlackout ? "eye.slash.fill" : "eye.slash")
                    .font(.system(size: layout.isCompact ? 11 : 14))
                    .foregroundStyle(appState.isBlackout ? .white : Theme.red)
                    .frame(width: layout.isCompact ? 26 : 32, height: layout.isCompact ? 26 : 32)
                    .chip(
                        fill: appState.isBlackout ? Theme.red : Theme.red.opacity(0.12),
                        radius: 6
                    )
            }
            .buttonStyle(.plain)

            // Pantalla Completa / Expandir
            Button {
                appState.isFullscreen.toggle()
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: layout.isCompact ? 11 : 13))
                    .foregroundStyle(appState.isFullscreen ? .white : Theme.green)
                    .frame(width: layout.isCompact ? 26 : 32, height: layout.isCompact ? 26 : 32)
                    .chip(
                        fill: appState.isFullscreen ? Theme.green : Theme.border,
                        radius: 6
                    )
            }
            .buttonStyle(.plain)

            // Controles de Navegación (Playlist de Estrofas / Versículos o Hojas de Documento PDF/PPTX)
            if appState.playlist != nil || appState.isDocumentActive {
                HStack(spacing: 0) {
                    Button {
                        appState.handlePrevSlide()
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: layout.isCompact ? 10 : 12))
                            if appState.isDocumentActive {
                                Text("Hoja")
                                    .font(.system(size: layout.isCompact ? 8 : 10, weight: .bold))
                            }
                        }
                        .foregroundStyle(Theme.blue)
                        .padding(.horizontal, layout.isCompact ? 6 : 8)
                        .frame(height: layout.isCompact ? 26 : 32)
                        .background(Theme.blue.opacity(0.15))
                    }
                    .buttonStyle(.plain)

                    Rectangle().fill(Theme.border).frame(width: 1, height: layout.isCompact ? 26 : 32)

                    Button {
                        appState.handleNextSlide()
                    } label: {
                        HStack(spacing: 3) {
                            if appState.isDocumentActive {
                                Text("Hoja")
                                    .font(.system(size: layout.isCompact ? 8 : 10, weight: .bold))
                            }
                            Image(systemName: "chevron.right")
                                .font(.system(size: layout.isCompact ? 10 : 12))
                        }
                        .foregroundStyle(Theme.blue)
                        .padding(.horizontal, layout.isCompact ? 6 : 8)
                        .frame(height: layout.isCompact ? 26 : 32)
                        .background(Theme.blue.opacity(0.15))
                    }
                    .buttonStyle(.plain)
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay {
                    RoundedRectangle(cornerRadius: 6).stroke(Theme.border, lineWidth: 1)
                }
            }
        }
    }

    private var brightnessGroup: some View {
        HStack(spacing: 6) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: layout.isCompact ? 11 : 14))
                .foregroundStyle(Theme.muted)

            if !layout.isCompact {
                Text("Brillo")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSoft)
            }

            Slider(value: $appState.brightness, in: 10...100)
                .frame(width: layout.isCompact ? 50 : 90)
                .tint(.white)

            Text("\(Int(appState.brightness))%")
                .font(.system(size: layout.isCompact ? 9 : 11))
                .foregroundStyle(Theme.muted)
                .frame(width: 32, alignment: .trailing)
        }
    }

    private var textColorGroup: some View {
        HStack(spacing: 6) {
            Image(systemName: "paintpalette.fill")
                .font(.system(size: layout.isCompact ? 11 : 14))
                .foregroundStyle(Theme.muted)

            if !layout.isCompact {
                Text("Color")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSoft)
            }

            HStack(spacing: layout.isCompact ? 3 : 6) {
                ForEach(colors, id: \.self) { hex in
                    let isSelected = appState.textColorHex.lowercased() == hex.lowercased()
                    Button {
                        appState.textColorHex = hex
                    } label: {
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: layout.isCompact ? 12 : 18, height: layout.isCompact ? 12 : 18)
                            .overlay {
                                Circle().stroke(isSelected ? Theme.blue : (hex == "#000000" ? Theme.dim : Theme.border), lineWidth: isSelected ? 2 : 1)
                            }
                            .scaleEffect(isSelected ? 1.25 : 1.0)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, layout.isCompact ? 4 : 8)
            .padding(.vertical, 4)
            .chip(fill: Color(hex: "#0f172a"), radius: 10)
        }
    }

    private var textBackgroundGroup: some View {
        Button {
            appState.textHasBackground.toggle()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "square.fill")
                    .font(.system(size: layout.isCompact ? 9 : 12))
                    .foregroundStyle(appState.textHasBackground ? Theme.lightBlue : Theme.dim)
                Text(appState.textHasBackground ? "Fondo: ON" : "Fondo")
                    .font(.system(size: layout.isCompact ? 9 : 11, weight: .bold))
                    .foregroundStyle(appState.textHasBackground ? Theme.lightBlue : Theme.muted)
            }
            .padding(.horizontal, layout.isCompact ? 6 : 8)
            .padding(.vertical, layout.isCompact ? 4 : 6)
            .chip(
                fill: appState.textHasBackground ? Theme.blue.opacity(0.18) : Color(hex: "#0f172a"),
                border: appState.textHasBackground ? Theme.blue : Theme.border,
                radius: 4
            )
        }
        .buttonStyle(.plain)
    }

    private var separator: some View {
        Rectangle()
            .fill(Theme.border)
            .frame(width: 1, height: layout.isCompact ? 16 : 20)
    }
}
