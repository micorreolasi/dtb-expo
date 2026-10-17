import SwiftUI

struct TVControlPanelView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.layoutInfo) var layout

    private let colors = ["#ffffff", "#000000", "#facc15", "#38bdf8", "#4ade80", "#fb923c", "#f472b6"]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: layout.isCompact ? 8 : 12) {
                // 1. Cabecera de Estado de TV
                headerSection

                // 2. Tarjeta de Emisión Actual en Pantalla
                currentProjectionCard

                // 3. Controles de Diapositiva / Canción (Copia de los botones inferiores)
                slideNavigationSection

                // 4. Controles de Zoom de Letra en TV
                textSizeSection

                // 5. Controles de Zoom de Documento / PDF en TV (si aplica)
                if appState.isDocumentActive || appState.projection.type == .document || appState.projection.type == .pdf {
                    documentZoomSection
                }

                // 6. Controles de Video / Medios / YouTube en TV (si aplica)
                if appState.projection.type == .video || appState.projection.type == .web {
                    videoControlsSection
                }

                // 7. Control de Brillo de Pantalla
                brightnessSection
            }
            .padding(layout.isCompact ? 8 : 12)
        }
        .background(Theme.bg)
    }

    // MARK: - 1. Cabecera de TV
    private var headerSection: some View {
        HStack(spacing: 6) {
            Image(systemName: appState.hasExternalDisplay ? "tv.fill" : "tv")
                .font(.system(size: layout.isCompact ? 11 : 14))
                .foregroundStyle(appState.hasExternalDisplay ? Theme.green : (appState.isPresentationMode ? Theme.violet : Theme.muted))

            VStack(alignment: .leading, spacing: 1) {
                Text(appState.hasExternalDisplay ? "TV Conectada" : (appState.isPresentationMode ? "Presentación" : "Salida Principal: TV"))
                    .font(.system(size: layout.isCompact ? 10 : 12, weight: .bold))
                    .foregroundStyle(appState.hasExternalDisplay ? Theme.green : Theme.textBright)
                    .lineLimit(1)

                if appState.hasExternalDisplay {
                    Text(appState.externalDisplayName)
                        .font(.system(size: layout.isCompact ? 8 : 10))
                        .foregroundStyle(Theme.dim)
                }
            }

            Spacer()

            Button {
                appState.isPresentationMode = true
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: layout.isCompact ? 9 : 11))
                    Text("Pantalla")
                        .font(.system(size: layout.isCompact ? 8 : 10, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, layout.isCompact ? 6 : 8)
                .padding(.vertical, layout.isCompact ? 4 : 5)
                .background(Theme.violet, in: RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - 2. Tarjeta de Emisión Actual en Pantalla
    private var currentProjectionCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: contentTypeIcon)
                        .font(.system(size: layout.isCompact ? 9 : 11))
                        .foregroundStyle(contentTypeColor)
                    Text(contentTypeLabel)
                        .font(.system(size: layout.isCompact ? 9 : 11, weight: .bold))
                        .foregroundStyle(contentTypeColor)
                }

                Spacer()

                if appState.isBlackout {
                    Text("BLACKOUT")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Theme.red, in: RoundedRectangle(cornerRadius: 3))
                } else if appState.isPaused {
                    Text("PAUSADO")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Theme.blue, in: RoundedRectangle(cornerRadius: 3))
                }
            }

            // Resumen del contenido proyectado
            Text(currentContentSnippet)
                .font(.system(size: layout.isCompact ? 10 : 12))
                .foregroundStyle(appState.isBlackout ? Theme.dim : Theme.textSoft)
                .lineLimit(layout.isCompact ? 2 : 3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6)
                .background(Color.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 6))

            // Botones de Acción Inmediata (Limpiar, Blackout, Pausa)
            HStack(spacing: layout.isCompact ? 4 : 6) {
                // Limpiar
                Button {
                    appState.clearProjection()
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "trash")
                            .font(.system(size: layout.isCompact ? 9 : 11))
                        Text("Limpiar")
                            .font(.system(size: layout.isCompact ? 8 : 10, weight: .bold))
                    }
                    .foregroundStyle(Theme.amber)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, layout.isCompact ? 4 : 6)
                    .chip(fill: Theme.amber.opacity(0.15), border: Theme.amber.opacity(0.3), radius: 6)
                }
                .buttonStyle(.plain)

                // Blackout
                Button {
                    appState.isBlackout.toggle()
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: appState.isBlackout ? "eye.slash.fill" : "eye.slash")
                            .font(.system(size: layout.isCompact ? 9 : 11))
                        Text(appState.isBlackout ? "Activar" : "Blackout")
                            .font(.system(size: layout.isCompact ? 8 : 10, weight: .bold))
                    }
                    .foregroundStyle(appState.isBlackout ? .white : Theme.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, layout.isCompact ? 4 : 6)
                    .chip(
                        fill: appState.isBlackout ? Theme.red : Theme.red.opacity(0.12),
                        border: Theme.red.opacity(0.4),
                        radius: 6
                    )
                }
                .buttonStyle(.plain)

                // Pausar
                Button {
                    appState.togglePlayPause()
                } label: {
                    Image(systemName: appState.isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: layout.isCompact ? 9 : 11))
                        .foregroundStyle(appState.isPaused ? .white : Theme.blue)
                        .frame(width: layout.isCompact ? 26 : 30, height: layout.isCompact ? 24 : 28)
                        .chip(
                            fill: appState.isPaused ? Theme.blue : Theme.blue.opacity(0.15),
                            border: Theme.blue.opacity(0.3),
                            radius: 6
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(layout.isCompact ? 8 : 10)
        .chip(fill: Theme.panel, border: Theme.border, radius: 8)
    }

    // MARK: - 3. Controles de Diapositiva / Canción (Copia exacta de los controles inferiores)
    private var slideNavigationSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Cambio de Canción / Diapositiva")
                    .font(.system(size: layout.isCompact ? 9 : 11, weight: .bold))
                    .foregroundStyle(Theme.muted)
                Spacer()
                Text(slidePositionLabel)
                    .font(.system(size: layout.isCompact ? 8 : 10, weight: .bold))
                    .foregroundStyle(Theme.blue)
            }

            // Fila de Anterior y Siguiente
            HStack(spacing: layout.isCompact ? 4 : 6) {
                Button {
                    appState.handlePrevSlide()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: layout.isCompact ? 10 : 12, weight: .bold))
                        Text("Anterior")
                            .font(.system(size: layout.isCompact ? 9 : 11, weight: .bold))
                    }
                    .foregroundStyle(canGoPrev ? Theme.blue : Theme.dim)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, layout.isCompact ? 6 : 8)
                    .chip(
                        fill: canGoPrev ? Theme.blue.opacity(0.15) : Theme.border.opacity(0.2),
                        border: canGoPrev ? Theme.blue.opacity(0.4) : Theme.border,
                        radius: 6
                    )
                }
                .buttonStyle(.plain)
                .disabled(!canGoPrev)

                Button {
                    appState.handleNextSlide()
                } label: {
                    HStack(spacing: 3) {
                        Text("Siguiente")
                            .font(.system(size: layout.isCompact ? 9 : 11, weight: .bold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: layout.isCompact ? 10 : 12, weight: .bold))
                    }
                    .foregroundStyle(canGoNext ? Theme.blue : Theme.dim)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, layout.isCompact ? 6 : 8)
                    .chip(
                        fill: canGoNext ? Theme.blue.opacity(0.15) : Theme.border.opacity(0.2),
                        border: canGoNext ? Theme.blue.opacity(0.4) : Theme.border,
                        radius: 6
                    )
                }
                .buttonStyle(.plain)
                .disabled(!canGoNext)
            }
        }
        .padding(layout.isCompact ? 8 : 10)
        .chip(fill: Theme.panel, border: Theme.border, radius: 8)
    }

    // MARK: - 4. Controles de Zoom de Letra en TV
    private var textSizeSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Zoom de Letra en TV")
                    .font(.system(size: layout.isCompact ? 9 : 11, weight: .bold))
                    .foregroundStyle(Theme.muted)
                Spacer()
                Text("\(Int((appState.textSize / 48.0) * 100))%")
                    .font(.system(size: layout.isCompact ? 8 : 10, weight: .bold))
                    .foregroundStyle(abs(appState.textSize - 48.0) > 1.0 ? Theme.green : Theme.textSoft)
            }

            // Fila de botones A-, 100%, A+
            HStack(spacing: 4) {
                // A-
                Button {
                    appState.decreaseTextSize()
                } label: {
                    HStack(spacing: 1) {
                        Text("A")
                            .font(.system(size: layout.isCompact ? 10 : 12, weight: .bold))
                        Image(systemName: "minus")
                            .font(.system(size: layout.isCompact ? 7 : 8, weight: .bold))
                    }
                    .foregroundStyle(appState.textSize <= 28 ? Theme.dim : Theme.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, layout.isCompact ? 4 : 6)
                    .chip(fill: Theme.blue.opacity(0.12), border: Theme.blue.opacity(0.3), radius: 6)
                }
                .buttonStyle(.plain)
                .disabled(appState.textSize <= 28)

                // 100% Reset
                Button {
                    appState.resetTextSize()
                } label: {
                    Text("100%")
                        .font(.system(size: layout.isCompact ? 8 : 10, weight: .bold))
                        .foregroundStyle(abs(appState.textSize - 48.0) > 1.0 ? Theme.green : Theme.textSoft)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, layout.isCompact ? 4 : 6)
                        .chip(fill: Theme.panel, border: Theme.border, radius: 6)
                }
                .buttonStyle(.plain)

                // A+
                Button {
                    appState.increaseTextSize()
                } label: {
                    HStack(spacing: 1) {
                        Text("A")
                            .font(.system(size: layout.isCompact ? 11 : 13, weight: .bold))
                        Image(systemName: "plus")
                            .font(.system(size: layout.isCompact ? 7 : 8, weight: .bold))
                    }
                    .foregroundStyle(appState.textSize >= 76 ? Theme.dim : Theme.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, layout.isCompact ? 4 : 6)
                    .chip(fill: Theme.blue.opacity(0.12), border: Theme.blue.opacity(0.3), radius: 6)
                }
                .buttonStyle(.plain)
                .disabled(appState.textSize >= 76)
            }

            // Paleta rápida de color de letra y Fondo
            HStack(spacing: 4) {
                HStack(spacing: 3) {
                    ForEach(colors, id: \.self) { hex in
                        let isSelected = appState.textColorHex.lowercased() == hex.lowercased()
                        Button {
                            appState.textColorHex = hex
                        } label: {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: layout.isCompact ? 10 : 13, height: layout.isCompact ? 10 : 13)
                                .overlay {
                                    Circle().stroke(isSelected ? Theme.blue : (hex == "#000000" ? Theme.dim : Theme.border), lineWidth: isSelected ? 2 : 1)
                                }
                                .scaleEffect(isSelected ? 1.2 : 1.0)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 3)
                .chip(fill: Color(hex: "#0f172a"), radius: 6)

                Spacer()

                Button {
                    appState.textHasBackground.toggle()
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "square.fill")
                            .font(.system(size: 8))
                        Text(appState.textHasBackground ? "Fondo: ON" : "Fondo")
                            .font(.system(size: layout.isCompact ? 7 : 9, weight: .bold))
                    }
                    .foregroundStyle(appState.textHasBackground ? Theme.lightBlue : Theme.dim)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .chip(
                        fill: appState.textHasBackground ? Theme.blue.opacity(0.2) : Color(hex: "#0f172a"),
                        border: appState.textHasBackground ? Theme.blue : Theme.border,
                        radius: 4
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(layout.isCompact ? 8 : 10)
        .chip(fill: Theme.panel, border: Theme.border, radius: 8)
    }

    // MARK: - 5. Controles de Zoom de Documento / PDF en TV
    private var documentZoomSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Zoom de Documento en TV")
                    .font(.system(size: layout.isCompact ? 9 : 11, weight: .bold))
                    .foregroundStyle(Theme.red)
                Spacer()
                Text("\(Int(appState.documentZoomScale * 100))%")
                    .font(.system(size: layout.isCompact ? 8 : 10, weight: .bold))
                    .foregroundStyle(appState.documentZoomScale > 1.05 ? Theme.green : Theme.textSoft)
            }

            // Fila de Zoom -, 100%, Zoom +
            HStack(spacing: 4) {
                Button {
                    appState.zoomOutDocument()
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: layout.isCompact ? 9 : 11, weight: .bold))
                        .foregroundStyle(Theme.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, layout.isCompact ? 4 : 6)
                        .chip(fill: Theme.blue.opacity(0.12), border: Theme.blue.opacity(0.3), radius: 6)
                }
                .buttonStyle(.plain)

                Button {
                    appState.resetDocumentZoom()
                } label: {
                    Text("100%")
                        .font(.system(size: layout.isCompact ? 8 : 10, weight: .bold))
                        .foregroundStyle(appState.documentZoomScale <= 1.05 ? .white : Theme.textSoft)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, layout.isCompact ? 4 : 6)
                        .chip(fill: Theme.panel, border: Theme.border, radius: 6)
                }
                .buttonStyle(.plain)

                Button {
                    appState.zoomInDocument()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: layout.isCompact ? 9 : 11, weight: .bold))
                        .foregroundStyle(Theme.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, layout.isCompact ? 4 : 6)
                        .chip(fill: Theme.blue.opacity(0.12), border: Theme.blue.opacity(0.3), radius: 6)
                }
                .buttonStyle(.plain)
            }

            // Botón destacado: Ajustar al Ancho (Vertical)
            Button {
                appState.fitDocumentWidth()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.left.and.right.square.fill")
                        .font(.system(size: layout.isCompact ? 9 : 11))
                    Text("Ajustar al Ancho de la TV")
                        .font(.system(size: layout.isCompact ? 8 : 10, weight: .bold))
                }
                .foregroundStyle(appState.documentZoomScale >= 2.1 ? .white : Theme.green)
                .frame(maxWidth: .infinity)
                .padding(.vertical, layout.isCompact ? 5 : 7)
                .chip(
                    fill: appState.documentZoomScale >= 2.1 ? Theme.green : Theme.green.opacity(0.15),
                    border: Theme.green.opacity(0.4),
                    radius: 6
                )
            }
            .buttonStyle(.plain)

            // Controles de desplazamiento vertical si hay zoom activo
            if appState.documentZoomScale > 1.05 {
                HStack(spacing: 4) {
                    Text("Mover en TV:")
                        .font(.system(size: layout.isCompact ? 8 : 9))
                        .foregroundStyle(Theme.muted)

                    Spacer()

                    Button {
                        appState.scrollDocumentUp()
                    } label: {
                        HStack(spacing: 2) {
                            Image(systemName: "chevron.up")
                                .font(.system(size: 9, weight: .bold))
                            Text("Arriba")
                                .font(.system(size: 8, weight: .bold))
                        }
                        .foregroundStyle(Theme.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .chip(fill: Theme.border, radius: 4)
                    }
                    .buttonStyle(.plain)

                    Button {
                        appState.scrollDocumentDown()
                    } label: {
                        HStack(spacing: 2) {
                            Text("Abajo")
                                .font(.system(size: 8, weight: .bold))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundStyle(Theme.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .chip(fill: Theme.border, radius: 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(layout.isCompact ? 8 : 10)
        .chip(fill: Theme.panel, border: Theme.border, radius: 8)
    }

    // MARK: - 6. Controles de Video / Medios / YouTube en TV
    private var videoControlsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Controles de Video en TV")
                    .font(.system(size: layout.isCompact ? 9 : 11, weight: .bold))
                    .foregroundStyle(Theme.blue)
                Spacer()
                Text(appState.isPaused ? "PAUSA" : "PLAY")
                    .font(.system(size: layout.isCompact ? 8 : 10, weight: .bold))
                    .foregroundStyle(appState.isPaused ? Theme.amber : Theme.green)
            }

            HStack(spacing: 4) {
                // -10s
                Button {
                    appState.rewind10Seconds()
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "gobackward.10")
                            .font(.system(size: layout.isCompact ? 9 : 11))
                        Text("-10s")
                            .font(.system(size: layout.isCompact ? 8 : 10, weight: .bold))
                    }
                    .foregroundStyle(Theme.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, layout.isCompact ? 6 : 8)
                    .chip(fill: Theme.blue.opacity(0.12), border: Theme.blue.opacity(0.3), radius: 6)
                }
                .buttonStyle(.plain)

                // Play / Pausa
                Button {
                    appState.togglePlayPause()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: appState.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: layout.isCompact ? 10 : 12))
                        Text(appState.isPaused ? "Play" : "Pausa")
                            .font(.system(size: layout.isCompact ? 8 : 10, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, layout.isCompact ? 6 : 8)
                    .background(appState.isPaused ? Theme.green : Theme.blue, in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)

                // +10s
                Button {
                    appState.forward10Seconds()
                } label: {
                    HStack(spacing: 2) {
                        Text("+10s")
                            .font(.system(size: layout.isCompact ? 8 : 10, weight: .bold))
                        Image(systemName: "goforward.10")
                            .font(.system(size: layout.isCompact ? 9 : 11))
                    }
                    .foregroundStyle(Theme.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, layout.isCompact ? 6 : 8)
                    .chip(fill: Theme.blue.opacity(0.12), border: Theme.blue.opacity(0.3), radius: 6)
                }
                .buttonStyle(.plain)
            }

            // Botón de Pantalla Completa en TV
            Button {
                if appState.projection.type == .web {
                    appState.sendWebCommand(.toggleFullscreen)
                }
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: layout.isCompact ? 9 : 11, weight: .bold))
                    Text("Pantalla Completa TV")
                        .font(.system(size: layout.isCompact ? 8 : 10, weight: .bold))
                }
                .foregroundStyle(Theme.sky)
                .frame(maxWidth: .infinity)
                .padding(.vertical, layout.isCompact ? 5 : 7)
                .chip(fill: Theme.sky.opacity(0.12), border: Theme.sky.opacity(0.35), radius: 6)
            }
            .buttonStyle(.plain)
        }
        .padding(layout.isCompact ? 8 : 10)
        .chip(fill: Theme.panel, border: Theme.border, radius: 8)
    }

    // MARK: - 7. Brillo de Pantalla
    private var brightnessSection: some View {
        HStack(spacing: 6) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: layout.isCompact ? 10 : 12))
                .foregroundStyle(Theme.muted)

            Text("Brillo:")
                .font(.system(size: layout.isCompact ? 8 : 10, weight: .bold))
                .foregroundStyle(Theme.textSoft)

            Slider(value: $appState.brightness, in: 10...100)
                .tint(Theme.textBright)

            Text("\(Int(appState.brightness))%")
                .font(.system(size: layout.isCompact ? 8 : 10, weight: .bold))
                .foregroundStyle(Theme.muted)
                .frame(width: 30, alignment: .trailing)
        }
        .padding(layout.isCompact ? 6 : 8)
        .chip(fill: Theme.panel, border: Theme.border, radius: 6)
    }

    // MARK: - Helpers de Estado
    private var contentTypeIcon: String {
        switch appState.projection.type {
        case .text: return "text.alignleft"
        case .image: return "photo.fill"
        case .video: return "video.fill"
        case .web: return "globe"
        case .pdf, .document: return "doc.text.fill"
        }
    }

    private var contentTypeColor: Color {
        switch appState.projection.type {
        case .text: return Theme.blue
        case .image: return Theme.violet
        case .video: return Theme.amber
        case .web: return Theme.lightBlue
        case .pdf, .document: return Theme.red
        }
    }

    private var contentTypeLabel: String {
        switch appState.projection.type {
        case .text:
            if appState.playlist != nil { return "Canción / Letra" }
            return "Texto en TV"
        case .image: return "Imagen en TV"
        case .video: return "Video en TV"
        case .web: return "Web / YouTube"
        case .pdf, .document: return "Documento en TV"
        }
    }

    private var currentContentSnippet: String {
        if !appState.currentDocName.isEmpty {
            return appState.currentDocName
        }
        if let title = appState.projection.title, !title.isEmpty {
            return title
        }
        let clean = appState.projection.content.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.isEmpty {
            return "(Pantalla vacía / Sin proyección)"
        }
        return clean
    }

    private var slidePositionLabel: String {
        if appState.isDocumentActive {
            return "Hoja \(appState.documentCurrentPage + 1) / \(max(1, appState.documentTotalPages))"
        }
        if let pl = appState.playlist {
            return "\(pl.currentIndex + 1) / \(pl.items.count)"
        }
        if let srv = appState.services.first(where: { $0.id == appState.activeServiceId }),
           let curId = appState.activeServiceItemId,
           let idx = srv.items.firstIndex(where: { $0.id == curId }) {
            return "Ítem \(idx + 1) / \(srv.items.count)"
        }
        return "1 / 1"
    }

    private var canGoPrev: Bool {
        if appState.isDocumentActive {
            return appState.documentCurrentPage > 0
        }
        if let pl = appState.playlist {
            return pl.currentIndex > 0
        }
        return false
    }

    private var canGoNext: Bool {
        if appState.isDocumentActive {
            return appState.documentCurrentPage + 1 < appState.documentTotalPages
        }
        if let pl = appState.playlist {
            return pl.currentIndex + 1 < pl.items.count
        }
        return false
    }
}
