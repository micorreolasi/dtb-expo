import Foundation

// MARK: - Módulos de navegación

enum ModuleType: String, CaseIterable, Identifiable {
    case service = "Service"
    case bible = "Bible"
    case songs = "Songs"
    case media = "Media"
    case documents = "Documents"
    case messages = "Messages"
    case timer = "Timer"
    case web = "Web"
    case settings = "Settings"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .service: return "Servicio"
        case .bible: return "Biblia"
        case .songs: return "Canciones"
        case .media: return "Medios"
        case .documents: return "Doc."
        case .messages: return "Mensajes"
        case .timer: return "Timer"
        case .web: return "Web"
        case .settings: return "Ajustes"
        }
    }

    /// Equivalente SF Symbols de los Ionicons originales.
    var icon: String {
        switch self {
        case .service: return "square.stack.3d.up.fill"
        case .bible: return "book.fill"
        case .songs: return "music.note.list"
        case .media: return "photo.on.rectangle.angled"
        case .documents: return "doc.text.fill"
        case .messages: return "ellipsis.bubble.fill"
        case .timer: return "timer"
        case .web: return "globe"
        case .settings: return "gearshape.fill"
        }
    }
}

// MARK: - Proyección

enum ProjectionType: String, Codable {
    case text, image, video, web, pdf, document
}

struct ProjectionData: Equatable {
    var type: ProjectionType
    var content: String
    var title: String? = nil

    static func text(_ content: String) -> ProjectionData {
        ProjectionData(type: .text, content: content)
    }
}

enum ProjectionMode {
    case miniPreview, presentation, external
}

enum MediaKind: String, Codable, Hashable {
    case image, video

    var projectionType: ProjectionType { self == .video ? .video : .image }

    static let videoExtensions: Set<String> = ["mp4", "mov", "m4v", "3gp", "webm"]

    static func isVideoURL(_ url: URL) -> Bool {
        videoExtensions.contains(url.pathExtension.lowercased())
    }
}

struct BackgroundMedia: Codable, Equatable {
    var type: MediaKind
    var uri: String
}

struct MediaBackground: Identifiable, Hashable, Codable {
    var id: String
    var type: MediaKind
    var thumbnail: String
    var uri: String
    var name: String
}

enum DocumentNavAction: Equatable {
    case next
    case prev
}

enum WebControlCommand: Equatable {
    case play
    case pause
    case playPause
    case rewind(seconds: Double)
    case forward(seconds: Double)
    case toggleMute
    case reload
    case goBack
    case toggleFullscreen
    case syncTime(seconds: Double)
    case dismissPopups
    case skipAd
    case closeAdOverlay
    case mirrorClick(xRatio: Double, yRatio: Double, selector: String)
    case syncInput(selector: String, value: String)
    case submitInput(selector: String)
    case navigate(url: String)
}

// MARK: - Canciones

struct Stanza: Codable, Hashable {
    var name: String
    var text: String
}

struct Song: Identifiable, Hashable {
    var id: String
    var title: String
    var stanzas: [Stanza]
}

// MARK: - Biblia

struct BibleBook: Codable, Hashable {
    var abbrev: String?
    var name: String
    var chapters: [[String]]
}

struct LoadedBible: Identifiable {
    var id: String
    var name: String
    var books: [BibleBook]
}

struct RecentVerse: Hashable {
    var ref: String
    var text: String
    var fullContent: String
}

// MARK: - Playlist / Cintillo

struct Playlist: Equatable {
    var items: [String]
    var currentIndex: Int

    var currentItem: String? {
        items.indices.contains(currentIndex) ? items[currentIndex] : nil
    }
}

enum MarqueeSpeed: String, CaseIterable, Identifiable {
    case muyLento = "muy_lento"
    case lento
    case normal
    case rapido

    var id: String { rawValue }

    var label: String {
        switch self {
        case .muyLento: return "Muy Lento"
        case .lento: return "Lento"
        case .normal: return "Normal"
        case .rapido: return "Rápido"
        }
    }

    /// Duración de una pasada completa (segundos).
    var duration: TimeInterval {
        switch self {
        case .rapido: return 5
        case .normal: return 9
        case .lento: return 16
        case .muyLento: return 26
        }
    }
}

// MARK: - Orden de Culto (persistido en disco, mismo formato JSON que la versión Expo)

enum ServiceItemType: String, Codable {
    case song, verse, media, note

    var icon: String {
        switch self {
        case .song: return "music.note.list"
        case .verse: return "book.fill"
        case .media: return "photo.on.rectangle.angled"
        case .note: return "doc.text.fill"
        }
    }

    var colorHex: String {
        switch self {
        case .song: return "#60a5fa"
        case .verse: return "#fbbf24"
        case .media: return "#c4b5fd"
        case .note: return "#34d399"
        }
    }

    var backgroundHex: String {
        switch self {
        case .song: return "#3b82f625"
        case .verse: return "#f59e0b25"
        case .media: return "#8b5cf625"
        case .note: return "#10b98125"
        }
    }
}

struct ServiceItem: Codable, Identifiable, Hashable {
    var id: String
    var type: ServiceItemType
    var title: String
    var subtitle: String?
    var content: String
    var backgroundUri: String?
    var backgroundType: MediaKind?
    var songId: String?
    var stanzas: [Stanza]?
    var verseRef: String?
}

struct ServiceOrder: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var date: String
    var defaultBackgroundUri: String?
    var defaultBackgroundType: MediaKind?
    var items: [ServiceItem]
}

/// Datos de un nuevo elemento antes de asignarle id (equivalente a `Omit<ServiceItem, 'id'>`).
struct NewServiceItem {
    var type: ServiceItemType
    var title: String
    var subtitle: String?
    var content: String
    var backgroundUri: String?
    var backgroundType: MediaKind?
    var songId: String? = nil
    var stanzas: [Stanza]? = nil
    var verseRef: String? = nil
}

// MARK: - Alertas

struct AppAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    var confirmTitle: String? = nil
    var onConfirm: (() -> Void)? = nil
}

extension String {
    /// `nil` si la cadena está vacía (emula el `||` de JavaScript).
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
