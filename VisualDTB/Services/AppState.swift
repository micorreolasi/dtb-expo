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

    // MARK: - Playlist / Diapositivas
    @Published var playlist: Playlist? = nil

    // MARK: - Temporizador
    @Published var timerMinutes: Int = 5
    @Published var timeLeft: Int = 300
    @Published var timerRunning: Bool = false
    private var timerCancellable: AnyCancellable? = nil

    // MARK: - Web
    @Published var webUrl: String = "https://www.google.com"

    // MARK: - Mensajes / Cintillo (Marquee)
    @Published var messageInput: String = ""
    @Published var messageReps: String = "3"
    @Published var activeMarquee: String = ""
    @Published var marqueeSpeed: MarqueeSpeed = .normal
    @Published var marqueeTriggerId: UUID = UUID()

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
    @Published var documentPageAction: DocumentNavAction? = nil
    @Published var documentNavTriggerId: UUID = UUID()

    var isDocumentActive: Bool {
        projection.type == .document || projection.type == .pdf || (!currentDocPath.isEmpty && isReadingDocument)
    }

    // MARK: - Órdenes de Culto (Servicios)
    @Published var services: [ServiceOrder] = DefaultData.services
    @Published var activeServiceId: String = "srv-default-1"
    @Published var activeServiceItemId: String? = nil
    @Published var recentVerses: [RecentVerse] = []

    // MARK: - Pantalla Externa (AirPlay / HDMI)
    @Published var externalDisplayEnabled: Bool = true
    @Published var hasExternalDisplay: Bool = false

    // MARK: - Alertas
    @Published var currentAlert: AppAlert? = nil

    // MARK: - Inicialización
    init() {
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
                        let mins = String(format: "%02d", self.timeLeft / 60)
                        let secs = String(format: "%02d", self.timeLeft % 60)
                        self.projection = .text("⏳ \(mins):\(secs)")
                    }
                } else {
                    self.timerRunning = false
                    if self.projection.content.contains("⏳") {
                        self.projection = .text("Tiempo Finalizado")
                    }
                }
            }
    }

    func startTimer() {
        timerRunning = true
        let mins = String(format: "%02d", timeLeft / 60)
        let secs = String(format: "%02d", timeLeft % 60)
        projection = .text("⏳ \(mins):\(secs)")
    }

    func pauseTimer() {
        timerRunning = false
    }

    func resetTimer() {
        timerRunning = false
        timeLeft = timerMinutes * 60
    }

    func formatTime(_ seconds: Int) -> String {
        let m = String(format: "%02d", seconds / 60)
        let s = String(format: "%02d", seconds % 60)
        return "\(m):\(s)"
    }

    // MARK: - Control de Diapositivas (Playlist) y Hojas de Documentos
    func handleNextSlide() {
        if isDocumentActive {
            playlist = nil
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
            documentPageAction = .prev
            documentNavTriggerId = UUID()
            return
        }
        guard var pl = playlist, pl.currentIndex > 0 else { return }
        pl.currentIndex -= 1
        self.playlist = pl
        self.projection = .text(pl.items[pl.currentIndex])
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
        if activeServiceId == serviceId, let first = services.first {
            activeServiceId = first.id
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
