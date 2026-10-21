import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {

    // MARK: - Módulos y Navegación
    @Published var activeModule: ModuleType = .service
    @Published var projection: ProjectionData = .text("VISUAL DTB\nListo para proyectar")

    // MARK: - Barra de herramientas
    @Published var isBlackout: Bool = false
    @Published var isPaused: Bool = false
    @Published var isFullscreen: Bool = false
    @Published var isPresentationMode: Bool = false

    // MARK: - Brillo, Tamaño y Color de Texto
    @Published var brightness: Double = 100
    @Published var textSize: Double = 48
    @Published var textColorHex: String = "#ffffff"
    @Published var textHasBackground: Bool = false

    func increaseTextSize() {
        textSize = min(76.0, textSize + 4.0)
    }

    func decreaseTextSize() {
        textSize = max(28.0, textSize - 4.0)
    }

    func resetTextSize() {
        textSize = 48.0
    }

    // MARK: - Playlist / Diapositivas
    @Published var playlist: Playlist? = nil

    // MARK: - Temporizador
    @Published var timerMinutes: Int = 5
    @Published var timeLeft: Int = 300
    @Published var timerRunning: Bool = false
    private var timerCancellable: AnyCancellable? = nil

    // MARK: - Web
    @Published var webUrl: String = "https://www.google.com"
    @Published var webControlCommand: WebControlCommand? = nil
    @Published var webControlTriggerId: UUID = UUID()

    func sendWebCommand(_ command: WebControlCommand) {
        webControlCommand = command
        webControlTriggerId = UUID()
    }

    // Comando exclusivo para la TV externa (ej. sincronizar play/pause detectado en iPad)
    @Published var externalWebControlCommand: WebControlCommand? = nil
    @Published var externalWebControlTriggerId: UUID = UUID()

    func sendExternalWebCommand(_ command: WebControlCommand) {
        externalWebControlCommand = command
        externalWebControlTriggerId = UUID()
    }

    // MARK: - Mensajes / Cintillo (Marquee)
    @Published var messageInput: String = ""
    @Published var messageReps: String = "3"
    @Published var activeMarquee: String = ""
    @Published var marqueeSpeed: MarqueeSpeed = .normal
    @Published var marqueeTriggerId: UUID = UUID()
    @Published var marqueeScale: Double = 1.0

    // MARK: - Tema de Interfaz (Modo Claro / Modo Oscuro)
    @Published var isDarkMode: Bool = true {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        }
    }

    // MARK: - Canciones
    @Published var songsList: [Song] = DefaultData.songs
    @Published var selectedSongId: String = ""
    @Published var songSearch: String = ""
    @Published var isAddingSong: Bool = false
    @Published var newSongTitle: String = ""
    @Published var newSongLyrics: String = ""

    // MARK: - Biblias
    @Published var loadedBibles: [LoadedBible] = []
    @Published var activeBibleId: String = "rv1960"
    @Published var selectedBook: String = "Mateo"
    @Published var selectedChapter: Int = 8
    @Published var bibleSearch: String = ""

    // MARK: - Medios y Fondos
    @Published var backgroundMedia: BackgroundMedia? = BackgroundStorage.loadActive() {
        didSet {
            BackgroundStorage.saveActive(backgroundMedia)
        }
    }
    @Published var mediaPreviewUri: String? = nil
    @Published var mediaPreviewType: MediaKind? = nil
    @Published var customBackgrounds: [MediaBackground] = BackgroundStorage.load()

    // Control de reproducción de video en vivo (proyección directa y preview)
    @Published var videoSeekDelta: Double = 0
    @Published var videoSeekTriggerId: UUID = UUID()

    func seekVideo(by seconds: Double) {
        videoSeekDelta = seconds
        videoSeekTriggerId = UUID()
    }

    func toggleVideoPlayPause() {
        isPaused.toggle()
    }

    func addCustomBackground(_ bg: MediaBackground) {
        if !customBackgrounds.contains(where: { $0.id == bg.id || $0.uri == bg.uri }) {
            customBackgrounds.insert(bg, at: 0)
            BackgroundStorage.save(customBackgrounds)
        }
    }

    func deleteCustomBackground(_ bg: MediaBackground) {
        customBackgrounds.removeAll(where: { $0.id == bg.id })
        BackgroundStorage.save(customBackgrounds)
        if backgroundMedia?.uri == bg.uri {
            backgroundMedia = nil
        }
        if mediaPreviewUri == bg.uri {
            mediaPreviewUri = nil
        }
    }

    func selectBackground(_ bg: MediaBackground) {
        backgroundMedia = BackgroundMedia(type: bg.type, uri: bg.uri)
        mediaPreviewUri = nil
        mediaPreviewType = nil
    }

    // MARK: - Documentos y Navegación de Hojas
    @Published var isReadingDocument: Bool = false
    @Published var currentDocName: String = ""
    @Published var currentDocPath: String = ""
    @Published var documentCurrentPage: Int = 0
    @Published var documentTotalPages: Int = 1
    @Published var documentPageAction: DocumentNavAction? = nil
    @Published var documentNavTriggerId: UUID = UUID()

    // MARK: - Zoom y Desplazamiento Sincronizado de Documentos (Preview -> TV)
    @Published var documentZoomScale: CGFloat = 1.0
    @Published var documentScrollOffsetRatio: CGPoint = .zero

    func setDocumentZoom(_ zoom: CGFloat) {
        documentZoomScale = max(0.5, min(5.0, zoom))
    }

    func zoomInDocument() {
        documentZoomScale = min(5.0, documentZoomScale + 0.25)
    }

    func zoomOutDocument() {
        documentZoomScale = max(1.0, documentZoomScale - 0.25)
    }

    func resetDocumentZoom() {
        documentZoomScale = 1.0
        documentScrollOffsetRatio = .zero
    }

    func fitDocumentWidth() {
        // En pantallas panorámicas (16:9), un documento en vertical necesita ~2.2x de zoom para llenar el ancho
        documentZoomScale = 2.2
        documentScrollOffsetRatio = CGPoint(x: 0.5, y: 0.0)
    }

    func scrollDocumentUp() {
        documentScrollOffsetRatio.y = max(0.0, documentScrollOffsetRatio.y - 0.15)
    }

    func scrollDocumentDown() {
        documentScrollOffsetRatio.y = min(1.0, documentScrollOffsetRatio.y + 0.15)
    }

    func scrollDocumentLeft() {
        documentScrollOffsetRatio.x = max(0.0, documentScrollOffsetRatio.x - 0.15)
    }

    func scrollDocumentRight() {
        documentScrollOffsetRatio.x = min(1.0, documentScrollOffsetRatio.x + 0.15)
    }

    func setDocumentScrollOffset(x: CGFloat, y: CGFloat) {
        documentScrollOffsetRatio = CGPoint(
            x: max(0.0, min(1.0, x)),
            y: max(0.0, min(1.0, y))
        )
    }

    func centerDocumentScroll() {
        documentScrollOffsetRatio = CGPoint(x: 0.5, y: 0.5)
    }

    func goToDocumentPage(_ page: Int) {
        guard page >= 0, page < documentTotalPages else { return }
        documentCurrentPage = page
        documentPageAction = nil
        documentNavTriggerId = UUID()
    }

    func nextDocumentPage() {
        if documentTotalPages <= 1 || documentCurrentPage + 1 < documentTotalPages {
            documentCurrentPage += 1
            if documentCurrentPage >= documentTotalPages {
                documentTotalPages = documentCurrentPage + 1
            }
        } else if documentCurrentPage + 1 >= documentTotalPages && !currentDocPath.lowercased().hasSuffix(".pdf") {
            // Para presentaciones .key y .pptx en WebView, permitir avanzar para no quedar trabados
            documentCurrentPage += 1
            documentTotalPages = max(documentTotalPages, documentCurrentPage + 1)
        }
        documentPageAction = .next
        documentNavTriggerId = UUID()
        documentScrollOffsetRatio.y = min(1.0, documentScrollOffsetRatio.y + 0.12)
        webScrollRatio = documentScrollOffsetRatio.y
    }

    func prevDocumentPage() {
        if documentCurrentPage > 0 {
            documentCurrentPage -= 1
        }
        documentPageAction = .prev
        documentNavTriggerId = UUID()
        documentScrollOffsetRatio.y = max(0.0, documentScrollOffsetRatio.y - 0.12)
        webScrollRatio = documentScrollOffsetRatio.y
    }

    func resetDocumentToStart() {
        documentCurrentPage = 0
        documentScrollOffsetRatio = .zero
        webScrollRatio = 0.0
        documentPageAction = nil
        documentNavTriggerId = UUID()
    }

    /// Desplazamiento táctil fino, continuo y lento tipo pantalla táctil
    func scrollDocumentTouch(deltaY: CGFloat) {
        // deltaY: desplazamiento del gesto (en puntos)
        // Arrastrar hacia arriba (deltaY < 0) hace que el contenido suba (aumenta offset vertical)
        // Arrastrar hacia abajo (deltaY > 0) hace que el contenido baje (disminuye offset vertical)
        let sensitivity: CGFloat = 0.0016 // Movimiento lento y controlado
        let change = -(deltaY * sensitivity)
        let newRatio = max(0.0, min(1.0, documentScrollOffsetRatio.y + change))
        documentScrollOffsetRatio.y = newRatio
        webScrollRatio = newRatio
        documentNavTriggerId = UUID()
    }

    var isDocumentActive: Bool {
        projection.type == .document || projection.type == .pdf || (!currentDocPath.isEmpty && isReadingDocument)
    }

    // MARK: - Sincronización Web
    @Published var webScrollRatio: CGFloat = 0.0

    // MARK: - Órdenes de Culto (Servicios)
    @Published var services: [ServiceOrder] = DefaultData.services
    @Published var activeServiceId: String = "srv-default-1"
    @Published var activeServiceItemId: String? = nil
    @Published var recentVerses: [RecentVerse] = []

    // MARK: - Pantalla Externa (AirPlay / HDMI)
    @Published var externalDisplayEnabled: Bool = true
    @Published var hasExternalDisplay: Bool = false
    @Published var externalDisplayResolution: CGSize = CGSize(width: 1920, height: 1080)
    @Published var externalDisplayAspectRatio: CGFloat = 16.0 / 9.0
    @Published var externalDisplayName: String = "1920x1080 (16:9)"

    // MARK: - Alertas
    @Published var currentAlert: AppAlert? = nil

    // MARK: - Inicialización
    init() {
        // Inicializar sesión de audio para sonido directo en iPad y TV HDMI
        AudioSessionManager.configurePlaybackSession()

        // Cargar Biblia por defecto desde el bundle o JSON
        let bundled = BibleLoader.loadBundled()
        let initialBooks = bundled.isEmpty ? [] : bundled
        self.loadedBibles = [
            LoadedBible(id: "rv1960", name: "RV1960", books: initialBooks)
        ]
        if let mateo = initialBooks.first(where: { $0.name.localizedCaseInsensitiveContains("Mateo") }) {
            self.selectedBook = mateo.name
            self.selectedChapter = 1
        } else if let firstBook = initialBooks.first {
            self.selectedBook = firstBook.name
            self.selectedChapter = 1
        }

        // Cargar servicios guardados
        let saved = ServiceStorage.load()
        if !saved.isEmpty {
            self.services = saved
            self.activeServiceId = saved[0].id
        }

        // Cargar preferencia de tema (Modo Claro / Modo Oscuro)
        if UserDefaults.standard.object(forKey: "isDarkMode") != nil {
            self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        }

        setupTimer()
    }

    // MARK: - Lógica del Temporizador
    private func setupTimer() {
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                guard self.timerRunning && !self.isPaused else { return }

                if self.timeLeft > 0 {
                    self.timeLeft -= 1
                    if self.projection.content.contains("⏳") {
                        self.projection = .text("⏳ \(self.formatTime(self.timeLeft))")
                    }
                } else {
                    self.timerRunning = false
                    if self.projection.content.contains("⏳") {
                        self.projection = .text("Tiempo Finalizado")
                    }
                }
            }
    }

    func setTimerDuration(minutes: Int, seconds: Int = 0) {
        timerRunning = false
        timerMinutes = max(1, minutes)
        timeLeft = max(1, minutes * 60 + seconds)
        if projection.content.contains("⏳") || projection.content.contains("Tiempo Finalizado") {
            projection = .text("⏳ \(formatTime(timeLeft))")
        }
    }

    func addTimerMinutes(_ delta: Int) {
        let newTotal = max(60, timeLeft + delta * 60)
        timeLeft = newTotal
        timerMinutes = max(1, newTotal / 60)
        if projection.content.contains("⏳") {
            projection = .text("⏳ \(formatTime(timeLeft))")
        }
    }

    func startTimer() {
        if timeLeft <= 0 {
            timeLeft = timerMinutes * 60
        }
        timerRunning = true
        projection = .text("⏳ \(formatTime(timeLeft))")
    }

    func pauseTimer() {
        timerRunning = false
    }

    func resetTimer() {
        timerRunning = false
        timeLeft = timerMinutes * 60
        if projection.content.contains("⏳") || projection.content.contains("Tiempo Finalizado") {
            projection = .text("⏳ \(formatTime(timeLeft))")
        }
    }

    func formatTime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%02d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%02d:%02d", m, s)
        }
    }

    // MARK: - Control de Diapositivas (Playlist) y Hojas de Documentos
    func handleNextSlide() {
        if isDocumentActive {
            playlist = nil
            if documentCurrentPage + 1 < documentTotalPages {
                documentCurrentPage += 1
            }
            documentPageAction = .next
            documentNavTriggerId = UUID()
            return
        }
        guard var pl = playlist, pl.currentIndex < pl.items.count - 1 else { return }
        pl.currentIndex += 1
        self.playlist = pl
        self.projection = .text(pl.items[pl.currentIndex])
    }

    func handlePrevSlide() {
        if isDocumentActive {
            playlist = nil
            if documentCurrentPage > 0 {
                documentCurrentPage -= 1
            }
            documentPageAction = .prev
            documentNavTriggerId = UUID()
            return
        }
        guard var pl = playlist, pl.currentIndex > 0 else { return }
        pl.currentIndex -= 1
        self.playlist = pl
        self.projection = .text(pl.items[pl.currentIndex])
    }

    func nextServiceItem() {
        guard let srv = services.first(where: { $0.id == activeServiceId }), !srv.items.isEmpty else { return }
        if let curId = activeServiceItemId, let idx = srv.items.firstIndex(where: { $0.id == curId }) {
            if idx + 1 < srv.items.count {
                projectServiceItem(srv.items[idx + 1])
            }
        } else if let first = srv.items.first {
            projectServiceItem(first)
        }
    }

    func prevServiceItem() {
        guard let srv = services.first(where: { $0.id == activeServiceId }), !srv.items.isEmpty else { return }
        if let curId = activeServiceItemId, let idx = srv.items.firstIndex(where: { $0.id == curId }) {
            if idx > 0 {
                projectServiceItem(srv.items[idx - 1])
            }
        }
    }

    func rewind10Seconds() {
        if projection.type == .web {
            sendWebCommand(.rewind(seconds: 10))
        } else {
            seekVideo(by: -10)
        }
    }

    func forward10Seconds() {
        if projection.type == .web {
            sendWebCommand(.forward(seconds: 10))
        } else {
            seekVideo(by: 10)
        }
    }

    func togglePlayPause() {
        if projection.type == .web {
            sendWebCommand(.playPause)
        } else {
            isPaused.toggle()
        }
    }

    func clearProjection() {
        projection = .text("")
        currentDocPath = ""
        currentDocName = ""
        playlist = nil
    }

    // MARK: - Cintillo Animado (Marquee)
    func playMarquee() {
        let trimmed = messageInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        activeMarquee = trimmed
        marqueeTriggerId = UUID()
    }

    func stopMarquee() {
        activeMarquee = ""
    }

    // MARK: - Canciones
    func saveSong() {
        let title = newSongTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let lyrics = newSongLyrics.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty && !lyrics.isEmpty else { return }

        let rawStanzas = FontFitting.splitStanzas(lyrics)
        let stanzas = rawStanzas
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .enumerated()
            .map { Stanza(name: "Párrafo \($0.offset + 1)", text: $0.element) }

        let newSong = Song(id: "custom-\(Int(Date().timeIntervalSince1970 * 1000))", title: title, stanzas: stanzas)
        songsList.insert(newSong, at: 0)
        isAddingSong = false
        newSongTitle = ""
        newSongLyrics = ""
        selectedSongId = newSong.id
    }

    func editSong(id: String) {
        guard let song = songsList.first(where: { $0.id == id }) else { return }
        newSongTitle = song.title
        newSongLyrics = song.stanzas.map { $0.text }.joined(separator: "\n\n")
        songsList.removeAll(where: { $0.id == id })
        isAddingSong = true
    }

    func deleteSong(id: String) {
        currentAlert = AppAlert(
            title: "Eliminar Canción",
            message: "¿Estás seguro de que deseas eliminar esta canción?",
            confirmTitle: "Eliminar",
            onConfirm: { [weak self] in
                guard let self else { return }
                self.songsList.removeAll(where: { $0.id == id })
                if self.selectedSongId == id, let first = self.songsList.first {
                    self.selectedSongId = first.id
                }
            }
        )
    }

    // MARK: - Servicios (Órdenes de Culto)
    private func persistServices() {
        ServiceStorage.save(services)
    }

    func createService(name: String, date: String) {
        let newSrv = ServiceOrder(
            id: "srv-\(Int(Date().timeIntervalSince1970 * 1000))",
            name: name,
            date: date,
            defaultBackgroundUri: backgroundMedia?.uri ?? DefaultData.backgrounds.first?.uri,
            defaultBackgroundType: backgroundMedia?.type ?? DefaultData.backgrounds.first?.type,
            items: []
        )
        services.insert(newSrv, at: 0)
        activeServiceId = newSrv.id
        persistServices()
    }

    func deleteService(serviceId: String) {
        services.removeAll(where: { $0.id == serviceId })
        if services.isEmpty {
            let defaultSrv = ServiceOrder(
                id: "srv-\(Int(Date().timeIntervalSince1970 * 1000))",
                name: "Culto General",
                date: "Domingo",
                defaultBackgroundUri: nil,
                defaultBackgroundType: nil,
                items: []
            )
            services = [defaultSrv]
        }
        if activeServiceId == serviceId || !services.contains(where: { $0.id == activeServiceId }) {
            activeServiceId = services.first?.id ?? ""
            activeServiceItemId = nil
        }
        persistServices()
    }

    func updateServiceBackground(serviceId: String, bg: BackgroundMedia?) {
        if let idx = services.firstIndex(where: { $0.id == serviceId }) {
            services[idx].defaultBackgroundUri = bg?.uri
            services[idx].defaultBackgroundType = bg?.type
            persistServices()
        }
    }

    func addItemToService(serviceId: String, item: NewServiceItem) {
        let newItem = ServiceItem(
            id: "item-\(Int(Date().timeIntervalSince1970 * 1000))-\(Int.random(in: 100...999))",
            type: item.type,
            title: item.title,
            subtitle: item.subtitle,
            content: item.content,
            backgroundUri: item.backgroundUri,
            backgroundType: item.backgroundType,
            songId: item.songId,
            stanzas: item.stanzas,
            verseRef: item.verseRef
        )
        if let idx = services.firstIndex(where: { $0.id == serviceId }) {
            services[idx].items.append(newItem)
            persistServices()
        }
    }

    func removeItemFromService(serviceId: String, itemId: String) {
        if let idx = services.firstIndex(where: { $0.id == serviceId }) {
            services[idx].items.removeAll(where: { $0.id == itemId })
            persistServices()
        }
        if activeServiceItemId == itemId {
            activeServiceItemId = nil
        }
    }

    func reorderItemInService(serviceId: String, itemId: String, direction: ReorderDirection) {
        guard let srvIdx = services.firstIndex(where: { $0.id == serviceId }) else { return }
        var items = services[srvIdx].items
        guard let itemIdx = items.firstIndex(where: { $0.id == itemId }) else { return }
        let targetIdx = direction == .up ? itemIdx - 1 : itemIdx + 1
        guard items.indices.contains(targetIdx) else { return }

        items.swapAt(itemIdx, targetIdx)
        services[srvIdx].items = items
        persistServices()
    }

    func updateItemBackground(serviceId: String, itemId: String, bg: BackgroundMedia?) {
        guard let srvIdx = services.firstIndex(where: { $0.id == serviceId }) else { return }
        if let itemIdx = services[srvIdx].items.firstIndex(where: { $0.id == itemId }) {
            services[srvIdx].items[itemIdx].backgroundUri = bg?.uri
            services[srvIdx].items[itemIdx].backgroundType = bg?.type
            persistServices()
        }
    }

    func projectServiceItem(_ item: ServiceItem) {
        activeServiceItemId = item.id
        let currentSrv = services.first(where: { $0.id == activeServiceId })
        let bgUri = item.backgroundUri ?? currentSrv?.defaultBackgroundUri
        let bgType = item.backgroundType ?? currentSrv?.defaultBackgroundType ?? .image

        if let bgUri {
            backgroundMedia = BackgroundMedia(type: bgType, uri: bgUri)
        }

        switch item.type {
        case .song:
            if let stanzas = item.stanzas, !stanzas.isEmpty {
                let items = stanzas.map { $0.text }
                playlist = Playlist(items: items, currentIndex: 0)
                projection = .text(items[0])
            }
        case .verse, .note:
            playlist = Playlist(items: [item.content], currentIndex: 0)
            projection = .text(item.content)
        case .media:
            projection = ProjectionData(type: item.backgroundType?.projectionType ?? .image, content: item.content)
        }
    }

    // MARK: - Vistos Recientes y Agregado Rápido
    func addRecentVerse(_ item: RecentVerse) {
        var list = recentVerses.filter { $0.ref != item.ref }
        list.insert(item, at: 0)
        recentVerses = Array(list.prefix(25))
    }

    func quickAddVerseToActiveService(ref: String, text: String, fullContent: String) {
        guard let currentSrv = services.first(where: { $0.id == activeServiceId }) ?? services.first else { return }
        let sub = text.count > 55 ? String(text.prefix(55)) + "..." : text
        addItemToService(
            serviceId: currentSrv.id,
            item: NewServiceItem(
                type: .verse,
                title: ref,
                subtitle: sub,
                content: fullContent,
                backgroundUri: currentSrv.defaultBackgroundUri,
                backgroundType: currentSrv.defaultBackgroundType,
                verseRef: ref
            )
        )
        currentAlert = AppAlert(
            title: "Añadido al Culto",
            message: "\(ref) añadido a \"\(currentSrv.name)\"."
        )
    }

    func quickAddSongToActiveService(_ song: Song) {
        guard let currentSrv = services.first(where: { $0.id == activeServiceId }) ?? services.first else { return }
        let firstText = song.stanzas.first?.text ?? song.title
        addItemToService(
            serviceId: currentSrv.id,
            item: NewServiceItem(
                type: .song,
                title: song.title,
                subtitle: "\(song.stanzas.count) estrofas",
                content: firstText,
                backgroundUri: currentSrv.defaultBackgroundUri,
                backgroundType: currentSrv.defaultBackgroundType,
                songId: song.id,
                stanzas: song.stanzas
            )
        )
        currentAlert = AppAlert(
            title: "Añadido al Culto",
            message: "\"\(song.title)\" añadida a \"\(currentSrv.name)\"."
        )
    }
}

enum ReorderDirection {
    case up, down
}
