import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct MediaView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.layoutInfo) var layout

    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showFileImporter = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
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

                // Panel de Vista Previa y Acción (Proyectar Directo o Dejar como Fondo)
                if let previewUri = appState.mediaPreviewUri {
                    previewSelectionPanel(uri: previewUri)
                }

                // Botones para importar medios
                HStack(spacing: 12) {
                    // Botón 1: Importar desde Fotos (PhotosPicker)
                    PhotosPicker(
                        selection: $selectedPhotoItem,
                        matching: .any(of: [.images, .videos])
                    ) {
                        HStack(spacing: 8) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 16, weight: .bold))
                            Text("Subir desde Fotos")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundStyle(Theme.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .chip(
                            fill: Theme.blue.opacity(0.10),
                            border: Theme.blue.opacity(0.4),
                            radius: 8
                        )
                    }
                    .buttonStyle(.plain)

                    // Botón 2: Importar desde Archivos del iPad (Disco / iCloud / USB)
                    Button {
                        showFileImporter = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 16, weight: .bold))
                            Text("Subir desde Archivos del iPad")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundStyle(Theme.violetLight)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .chip(
                            fill: Theme.violet.opacity(0.12),
                            border: Theme.violetLight.opacity(0.4),
                            radius: 8
                        )
                    }
                    .buttonStyle(.plain)
                }

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
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.image, .movie, .video, .quickTimeMovie, .mpeg4Movie, .data],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
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
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.muted)
                        .padding(4)
                }
                .buttonStyle(.plain)
            }

            // Vista previa del medio
            if isVideo {
                SafeVideoPlayerView(
                    uri: uri,
                    contentFit: .fit,
                    muted: false,
                    volume: 1.0,
                    loop: true,
                    isPaused: false,
                    nativeControls: true
                )
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ProjectionImageView(uri: uri, contentMode: .fit)
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
                    let newBg = MediaBackground(
                        id: "custom-\(Int(Date().timeIntervalSince1970 * 1000))",
                        type: isVideo ? .video : .image,
                        thumbnail: uri,
                        uri: uri,
                        name: isVideo ? "Video Guardado" : "Fondo Guardado"
                    )
                    appState.addCustomBackground(newBg)
                    appState.selectBackground(newBg)
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
        do {
            if let movie = try? await item.loadTransferable(type: PickedMovie.self) {
                let uri = movie.url.path
                await MainActor.run {
                    appState.mediaPreviewUri = uri
                    appState.mediaPreviewType = .video
                }
            } else if let data = try await item.loadTransferable(type: Data.self) {
                let savedURL = try MediaStorage.saveImage(data, fileExtension: "jpg")
                let uri = savedURL.path
                await MainActor.run {
                    appState.mediaPreviewUri = uri
                    appState.mediaPreviewType = .image
                }
            }
        } catch {
            await MainActor.run {
                appState.currentAlert = AppAlert(title: "Error al importar", message: error.localizedDescription)
            }
        }
        selectedPhotoItem = nil
    }

    // MARK: - Importación desde Archivos del iPad (Disco / iCloud / USB)
    private func handleFileImport(_ result: Result<[URL], Error>) {
        do {
            guard let selectedURL = try result.get().first else { return }
            let imported = try MediaStorage.importMediaFile(from: selectedURL)
            appState.mediaPreviewUri = imported.savedPath
            appState.mediaPreviewType = imported.isVideo ? .video : .image
        } catch {
            appState.currentAlert = AppAlert(title: "Error al importar archivo", message: error.localizedDescription)
        }
    }
}
