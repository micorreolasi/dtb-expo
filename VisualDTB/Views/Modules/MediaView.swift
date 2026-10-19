import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct MediaView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.layoutInfo) var layout

    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var isImporting = false
    @State private var importStatus = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Indicador de importación de video largo
                if isImporting {
                    HStack(spacing: 12) {
                        ProgressView()
                            .tint(.white)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Procesando video largo...")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                            Text(importStatus.isEmpty ? "Copiando y optimizando para vista previa..." : importStatus)
                                .font(.system(size: 11))
                                .foregroundStyle(Color(hex: "#93c5fd"))
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(Theme.blue.opacity(0.85), in: RoundedRectangle(cornerRadius: 8))
                }

                // Cabecera: Título y Botón "Fondo a Negro"
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Galería Multimedia y Fondos")
                            .font(.system(size: layout.isCompact ? 18 : 22, weight: .bold))
                            .foregroundStyle(Theme.textBright)
                        Text("\(appState.customBackgrounds.count) fondos disponibles en este iPad")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.muted)
                    }

                    Spacer()

                    Button {
                        appState.backgroundMedia = nil
                        appState.mediaPreviewUri = nil
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "moon.fill")
                                .font(.system(size: 12))
                            Text("Fondo a Negro")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Theme.red, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }

                // Panel de Control de Video Proyectado en Vivo en TV
                if appState.projection.type == .video {
                    activeVideoControlPanel
                }

                // Panel de Vista Previa y Acción (Proyectar Directo o Dejar como Fondo)
                if let previewUri = appState.mediaPreviewUri {
                    previewSelectionPanel(uri: previewUri)
                }

                // Botón para importar medios desde Galería / Fotos
                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .any(of: [.images, .videos])
                ) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 16, weight: .bold))
                        Text("Subir desde Galería")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Theme.blue, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)

                // Título de la galería
                Text("Fondos Guardados")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.text)
                    .padding(.top, 4)

                // Cuadrícula de Fondos Guardados (16:9 sin encimarse)
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: layout.isCompact ? 160 : 200), spacing: 16)],
                    spacing: 16
                ) {
                    ForEach(appState.customBackgrounds) { bg in
                        backgroundCard(bg: bg)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg)
        .onChange(of: selectedPhotoItem) { newItem in
            guard let newItem else { return }
            Task {
                await handlePhotoPicked(newItem)
            }
        }
    }

    // MARK: - Tarjeta de Fondo en la Galería
    private func backgroundCard(bg: MediaBackground) -> some View {
        let isCurrentBg = appState.backgroundMedia?.uri == bg.uri

        return VStack(spacing: 0) {
            // Contenedor 16:9 con imagen/miniatura
            ZStack(alignment: .topTrailing) {
                ProjectionImageView(uri: bg.thumbnail, contentMode: .fill)
                    .frame(height: layout.isCompact ? 95 : 115)
                    .frame(maxWidth: .infinity)
                    .clipped()

                // Insignias en esquinas
                HStack {
                    if isCurrentBg {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                            Text("ACTIVO")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Theme.green, in: RoundedRectangle(cornerRadius: 4))
                    }

                    Spacer()

                    // Icono de tipo de medio (Foto o Video)
                    Image(systemName: bg.type == .video ? "video.fill" : "photo.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.white)
                        .padding(5)
                        .background(Color.black.opacity(0.6), in: Circle())
                }
                .padding(6)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                // Al tocarlo, se coloca inmediatamente como fondo y se guarda
                appState.selectBackground(bg)
            }

            // Barra inferior con Nombre y Acciones
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    Text(bg.name)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.textBright)
                        .lineLimit(1)
                    Spacer()
                }

                HStack(spacing: 8) {
                    // Botón Usar como Fondo
                    Button {
                        appState.selectBackground(bg)
                    } label: {
                        Text(isCurrentBg ? "En Pantalla" : "Poner Fondo")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(isCurrentBg ? Theme.green : Theme.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                            .background(isCurrentBg ? Theme.green.opacity(0.15) : Theme.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)

                    // Botón Proyectar Directo
                    Button {
                        appState.playlist = nil
                        appState.projection = ProjectionData(
                            type: bg.type.projectionType,
                            content: bg.uri,
                            title: bg.name
                        )
                    } label: {
                        Image(systemName: "play.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.white)
                            .frame(width: 26, height: 24)
                            .background(Theme.violet, in: RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)

                    // Botón Eliminar
                    Button {
                        appState.deleteCustomBackground(bg)
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.red)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Theme.panel)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isCurrentBg ? Theme.green : Theme.border, lineWidth: isCurrentBg ? 2 : 1)
        }
    }

    // MARK: - Panel de Control de Video Activo en Proyección Directa
    private var activeVideoControlPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "tv.fill")
                        .foregroundStyle(Theme.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reproduciendo Video en Vivo en TV")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.textBright)
                        Text(appState.projection.title ?? "Video en Pantalla")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.green)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Button {
                    appState.projection = .text("")
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "stop.fill")
                        Text("Detener")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Theme.red, in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }

            // Barra de controles de video (-10s, Pausa/Play, +10s)
            HStack(spacing: 10) {
                // Retroceder 10s
                Button {
                    appState.seekVideo(by: -10)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "gobackward.10")
                            .font(.system(size: 14))
                        Text("Retroceder 10s")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(Theme.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .chip(fill: Theme.blue.opacity(0.15), border: Theme.blue.opacity(0.4), radius: 8)
                }
                .buttonStyle(.plain)

                // Pausa / Play
                Button {
                    appState.toggleVideoPlayPause()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: appState.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 16))
                        Text(appState.isPaused ? "Reanudar" : "Pausar Video")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(appState.isPaused ? Theme.green : Theme.violet, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)

                // Adelantar 10s
                Button {
                    appState.seekVideo(by: 10)
                } label: {
                    HStack(spacing: 4) {
                        Text("Adelantar 10s")
                            .font(.system(size: 13, weight: .bold))
                        Image(systemName: "goforward.10")
                            .font(.system(size: 14))
                    }
                    .foregroundStyle(Theme.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .chip(fill: Theme.blue.opacity(0.15), border: Theme.blue.opacity(0.4), radius: 8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .chip(fill: Theme.panel, border: Theme.green.opacity(0.5), radius: 10)
    }

    // MARK: - Panel de Previsualización y Elección de Acción
    private func previewSelectionPanel(uri: String) -> some View {
        let isVideo = appState.mediaPreviewType == .video

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: isVideo ? "video.fill" : "photo.fill")
                        .foregroundStyle(Theme.blue)
                    Text(isVideo ? "Video Seleccionado" : "Imagen Seleccionada")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.textBright)
                }

                Spacer()

                Button {
                    appState.mediaPreviewUri = nil
                    appState.mediaPreviewType = nil
                    appState.playlist = nil
                    appState.projection = .text("")
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(Color.black.opacity(0.6), in: Circle())
                }
                .buttonStyle(.plain)
            }

            // Vista previa del medio (en silencio para no interrumpir el culto)
            if isVideo {
                SafeVideoPlayerView(
                    uri: uri,
                    contentFit: .fit,
                    muted: true,
                    volume: 0.0,
                    loop: true,
                    isPaused: appState.isPaused,
                    nativeControls: true
                )
                .id("preview-vid-\(uri)")
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Controles de Vista Previa para Video (-10s, Pausa/Play, +10s)
                HStack(spacing: 10) {
                    Button {
                        appState.seekVideo(by: -10)
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "gobackward.10")
                            Text("-10s")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.blue)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .chip(fill: Theme.blue.opacity(0.12), border: Theme.blue.opacity(0.3), radius: 6)
                    }
                    .buttonStyle(.plain)

                    Button {
                        appState.toggleVideoPlayPause()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: appState.isPaused ? "play.fill" : "pause.fill")
                            Text(appState.isPaused ? "Reproducir" : "Pausar")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(appState.isPaused ? Theme.green : Theme.border, in: RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)

                    Button {
                        appState.seekVideo(by: 10)
                    } label: {
                        HStack(spacing: 3) {
                            Text("+10s")
                            Image(systemName: "goforward.10")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.blue)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .chip(fill: Theme.blue.opacity(0.12), border: Theme.blue.opacity(0.3), radius: 6)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                ProjectionImageView(uri: uri, contentMode: .fit)
                    .id("preview-img-\(uri)")
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Acciones claras: Proyectar Directo o Guardar como Fondo
            HStack(spacing: 12) {
                // 1. Proyectar Directo
                Button {
                    appState.playlist = nil
                    appState.projection = ProjectionData(
                        type: isVideo ? .video : .image,
                        content: uri,
                        title: isVideo ? "Video en Vivo" : "Imagen en Vivo"
                    )
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                        Text("Proyectar Directo \(isVideo ? "(con sonido)" : "")")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Theme.green, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)

                // 2. Guardar y poner de Fondo
                Button {
                    var thumb = uri
                    if isVideo {
                        let resolvedPath = BackgroundStorage.resolveURI(uri)
                        if let generated = BackgroundStorage.generateVideoThumbnail(for: URL(fileURLWithPath: resolvedPath)) {
                            thumb = generated
                        }
                    }
                    let newBg = MediaBackground(
                        id: "custom-\(Int(Date().timeIntervalSince1970 * 1000))",
                        type: isVideo ? .video : .image,
                        thumbnail: thumb,
                        uri: uri,
                        name: isVideo ? "Video Guardado" : "Fondo Guardado"
                    )
                    appState.addCustomBackground(newBg)
                    appState.selectBackground(newBg)
                    appState.mediaPreviewUri = nil
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "photo.fill")
                        Text("Guardar como Fondo")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Theme.violet, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .chip(fill: Theme.panel, border: Theme.border, radius: 10)
    }

    // MARK: - Importación desde Fotos (PhotosPicker)
    private func handlePhotoPicked(_ item: PhotosPickerItem) async {
        await MainActor.run {
            isImporting = true
            importStatus = "Extrayendo archivo multimedia de la fototeca..."
        }
        defer {
            Task { @MainActor in
                isImporting = false
                selectedPhotoItem = nil
            }
        }

        AudioSessionManager.ensureActive()

        do {
            // 1. Intentar cargar como video mediante PickedMovie (.movie)
            if let movie = try? await item.loadTransferable(type: PickedMovie.self) {
                let uri = movie.url.path
                await MainActor.run {
                    appState.mediaPreviewUri = uri
                    appState.mediaPreviewType = .video
                }
                return
            }

            // 2. Intentar cargar como video mediante PickedVideo (.video)
            if let video = try? await item.loadTransferable(type: PickedVideo.self) {
                let uri = video.url.path
                await MainActor.run {
                    appState.mediaPreviewUri = uri
                    appState.mediaPreviewType = .video
                }
                return
            }

            // 3. Importación como imagen
            await MainActor.run {
                importStatus = "Guardando imagen..."
            }
            if let data = try await item.loadTransferable(type: Data.self) {
                let savedURL = try MediaStorage.saveImage(data, fileExtension: "jpg")
                let uri = savedURL.path
                await MainActor.run {
                    appState.mediaPreviewUri = uri
                    appState.mediaPreviewType = .image
                }
            }
        } catch {
            await MainActor.run {
                appState.currentAlert = AppAlert(title: "Error al importar medio", message: error.localizedDescription)
            }
        }
    }
}
