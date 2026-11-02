import Foundation
import CoreTransferable
import UniformTypeIdentifiers
import AVFoundation
import UIKit

// MARK: - Ubicación privada de datos de la app

/// Carpeta privada de la app (Application Support/VisualDTB). No es visible en la app Archivos
/// ni en Finder. La primera vez migra automáticamente los datos que estaban en Documents.
enum AppStorageLocation {
    static let root: URL = {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("VisualDTB", isDirectory: true)
        try? fm.createDirectory(at: base, withIntermediateDirectories: true)
        migrateLegacyDocuments(to: base)
        return base
    }()

    /// Mueve los JSON internos y la carpeta Media desde Documents (versiones anteriores) sin perder datos.
    private static func migrateLegacyDocuments(to base: URL) {
        let fm = FileManager.default
        let legacy = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let jsonFiles = ["dtb_service_orders_v1.json", "dtb_custom_backgrounds_v1.json", "dtb_active_background_v1.json"]
        for name in jsonFiles {
            let src = legacy.appendingPathComponent(name)
            let dst = base.appendingPathComponent(name)
            if fm.fileExists(atPath: src.path) && !fm.fileExists(atPath: dst.path) {
                try? fm.moveItem(at: src, to: dst)
            }
        }
        let legacyMedia = legacy.appendingPathComponent("Media", isDirectory: true)
        let newMedia = base.appendingPathComponent("Media", isDirectory: true)
        guard fm.fileExists(atPath: legacyMedia.path) else { return }
        try? fm.createDirectory(at: newMedia, withIntermediateDirectories: true)
        if let items = try? fm.contentsOfDirectory(at: legacyMedia, includingPropertiesForKeys: nil) {
            for item in items {
                let dst = newMedia.appendingPathComponent(item.lastPathComponent)
                if !fm.fileExists(atPath: dst.path) {
                    try? fm.moveItem(at: item, to: dst)
                }
            }
        }
        if let rest = try? fm.contentsOfDirectory(atPath: legacyMedia.path), rest.isEmpty {
            try? fm.removeItem(at: legacyMedia)
        }
    }
}

// MARK: - Persistencia de Órdenes de Culto (equivalente a serviceStorage.ts)

enum ServiceStorage {
    private static let queue = DispatchQueue(label: "visualdtb.service-storage")

    static var fileURL: URL {
        AppStorageLocation.root.appendingPathComponent("dtb_service_orders_v1.json")
    }

    static func load() -> [ServiceOrder] {
        do {
            let url = fileURL
            guard FileManager.default.fileExists(atPath: url.path) else { return DefaultData.services }
            let data = try Data(contentsOf: url)
            let parsed = try JSONDecoder().decode([ServiceOrder].self, from: data)
            if !parsed.isEmpty { return parsed }
        } catch {
            print("loadSavedServices error:", error)
        }
        return DefaultData.services
    }

    static func save(_ services: [ServiceOrder]) {
        queue.async {
            do {
                let data = try JSONEncoder().encode(services)
                try data.write(to: fileURL, options: .atomic)
            } catch {
                print("saveServicesToDisk error:", error)
            }
        }
    }
}

// MARK: - Persistencia de Fondos Personalizados

enum BackgroundStorage {
    private static let queue = DispatchQueue(label: "visualdtb.background-storage")

    static var fileURL: URL {
        AppStorageLocation.root.appendingPathComponent("dtb_custom_backgrounds_v1.json")
    }

    static var activeFileURL: URL {
        AppStorageLocation.root.appendingPathComponent("dtb_active_background_v1.json")
    }

    /// Resuelve una ruta absoluta o relativa a la ubicación actual del sandbox de la app
    static func resolveURI(_ uri: String) -> String {
        if uri.hasPrefix("http://") || uri.hasPrefix("https://") {
            return uri
        }
        let cleanPath: String = {
            if uri.hasPrefix("file://"), let u = URL(string: uri) {
                return u.path
            }
            return uri
        }()
        if FileManager.default.fileExists(atPath: cleanPath) {
            return cleanPath
        }
        let filename = (cleanPath as NSString).lastPathComponent
        let inMedia = MediaStorage.mediaDirectory.appendingPathComponent(filename).path
        if FileManager.default.fileExists(atPath: inMedia) {
            return inMedia
        }
        return cleanPath
    }

    static func load() -> [MediaBackground] {
        do {
            let url = fileURL
            if FileManager.default.fileExists(atPath: url.path) {
                let data = try Data(contentsOf: url)
                let parsed = try JSONDecoder().decode([MediaBackground].self, from: data)
                if !parsed.isEmpty {
                    // Resolver URIs para que funcionen tras reinstalación o migración de contenedor
                    return parsed.map { bg in
                        var copy = bg
                        copy.uri = resolveURI(bg.uri)
                        copy.thumbnail = resolveURI(bg.thumbnail)
                        return copy
                    }
                }
            }
        } catch {
            print("loadSavedBackgrounds error:", error)
        }
        return DefaultData.backgrounds
    }

    static func save(_ backgrounds: [MediaBackground]) {
        queue.async {
            do {
                let data = try JSONEncoder().encode(backgrounds)
                try data.write(to: fileURL, options: .atomic)
            } catch {
                print("saveBackgrounds error:", error)
            }
        }
    }

    static func loadActive() -> BackgroundMedia? {
        do {
            let url = activeFileURL
            guard FileManager.default.fileExists(atPath: url.path) else { return nil }
            let data = try Data(contentsOf: url)
            var active = try JSONDecoder().decode(BackgroundMedia.self, from: data)
            active.uri = resolveURI(active.uri)
            return active
        } catch {
            return nil
        }
    }

    static func saveActive(_ active: BackgroundMedia?) {
        queue.async {
            do {
                if let active {
                    let data = try JSONEncoder().encode(active)
                    try data.write(to: activeFileURL, options: .atomic)
                } else {
                    try? FileManager.default.removeItem(at: activeFileURL)
                }
            } catch {
                print("saveActiveBackground error:", error)
            }
        }
    }

    /// Genera una miniatura JPEG rápida de un video (optimizado para videos cortos o largos de 30-40+ min)
    static func generateVideoThumbnail(for videoURL: URL) -> String? {
        let asset = AVURLAsset(url: videoURL, options: [AVURLAssetPreferPreciseDurationAndTimingKey: false])
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 400, height: 225)
        // No forzar búsqueda precisa de fotograma exacto para que sea casi instantáneo
        generator.requestedTimeToleranceBefore = CMTime(seconds: 2, preferredTimescale: 60)
        generator.requestedTimeToleranceAfter = CMTime(seconds: 2, preferredTimescale: 60)
        let time = CMTime(seconds: 1, preferredTimescale: 60)
        if let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) {
            let uiImage = UIImage(cgImage: cgImage)
            if let data = uiImage.jpegData(compressionQuality: 0.75) {
                let thumbURL = MediaStorage.mediaDirectory.appendingPathComponent("\(UUID().uuidString)_thumb.jpg")
                try? data.write(to: thumbURL, options: .atomic)
                return thumbURL.path
            }
        }
        return nil
    }
}

// MARK: - Biblia incluida en el bundle

enum BibleLoader {
    static func loadBundled() -> [BibleBook] {
        let candidateURLs: [URL?] = [
            Bundle.module.url(forResource: "bible", withExtension: "json"),
            Bundle.main.url(forResource: "bible", withExtension: "json"),
            Bundle.main.url(forResource: "bible", withExtension: "json", subdirectory: "VisualDTB_VisualDTB.bundle"),
            Bundle.main.bundleURL.appendingPathComponent("VisualDTB_VisualDTB.bundle/bible.json"),
            Bundle.main.resourceURL?.appendingPathComponent("VisualDTB_VisualDTB.bundle/bible.json"),
            Bundle.main.resourceURL?.appendingPathComponent("bible.json")
        ]

        for case let url? in candidateURLs {
            if FileManager.default.fileExists(atPath: url.path),
               let data = try? Data(contentsOf: url),
               let books = try? JSONDecoder().decode([BibleBook].self, from: data),
               !books.isEmpty {
                print("Biblia cargada correctamente desde \(url.path), total libros: \(books.count)")
                return books
            }
        }
        print("No se pudo cargar bible.json de ninguna ubicación del bundle")
        return []
    }
}

// MARK: - Archivos de medios y documentos

enum MediaStorage {
    static var mediaDirectory: URL {
        let dir = AppStorageLocation.root.appendingPathComponent("Media", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Carpeta temporal para documentos importados (PDF, PPTX, Word...)
    static var tempDocumentsDirectory: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("Documents", isDirectory: true)
    }

    /// Copia un documento elegido con el selector a la caché (equivale a `copyToCacheDirectory: true`).
    /// Borra la copia del documento anterior para no acumular archivos.
    static func importDocument(from url: URL, replacing previousPath: String? = nil) throws -> URL {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }

        if let previousPath, !previousPath.isEmpty {
            let previousDir = URL(fileURLWithPath: previousPath).deletingLastPathComponent()
            if isInside(previousDir, tempDocumentsDirectory) {
                try? FileManager.default.removeItem(at: previousDir)
            }
        }

        let dir = tempDocumentsDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let destination = dir.appendingPathComponent(url.lastPathComponent)
        try FileManager.default.copyItem(at: url, to: destination)
        return destination
    }

    // MARK: Borrado seguro y limpieza

    /// true si `child` está realmente dentro de `parent` (rutas normalizadas, sin trucos con ".." o enlaces).
    static func isInside(_ child: URL, _ parent: URL) -> Bool {
        let c = child.standardizedFileURL.resolvingSymlinksInPath().path
        let p = parent.standardizedFileURL.resolvingSymlinksInPath().path
        let prefix = p.hasSuffix("/") ? p : p + "/"
        return c.hasPrefix(prefix) && c != p
    }

    /// Borra un archivo de medios solo si pertenece a la carpeta Media de la app.
    /// Nunca toca fondos incluidos de fábrica, URLs remotas ni archivos fuera del contenedor.
    static func deleteMediaFileIfOwned(_ uri: String) {
        guard !uri.isEmpty, !uri.hasPrefix("http://"), !uri.hasPrefix("https://") else { return }
        let resolved = BackgroundStorage.resolveURI(uri)
        let url = URL(fileURLWithPath: resolved)
        guard isInside(url, mediaDirectory) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    /// Limpieza al iniciar la app:
    /// - Vacía los documentos temporales importados en sesiones anteriores.
    /// - Borra medios huérfanos (vistas previas no guardadas) que no aparecen en ningún dato guardado.
    static func performStartupCleanup() {
        let fm = FileManager.default
        try? fm.removeItem(at: tempDocumentsDirectory)

        // Conjunto de texto de todos los JSON guardados (fondos, fondo activo, órdenes de culto)
        var referencedText = ""
        for json in [BackgroundStorage.fileURL, BackgroundStorage.activeFileURL, ServiceStorage.fileURL] {
            if let data = try? Data(contentsOf: json), let text = String(data: data, encoding: .utf8) {
                referencedText += text
            }
        }

        let minAge: TimeInterval = 60 * 60 // solo archivos con más de 1 hora
        guard let items = try? fm.contentsOfDirectory(
            at: mediaDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        for item in items {
            let name = item.lastPathComponent
            if referencedText.contains(name) { continue }
            let modified = (try? item.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date()
            if Date().timeIntervalSince(modified) > minAge {
                try? fm.removeItem(at: item)
            }
        }
    }

    static func readData(from url: URL) throws -> Data {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        return try Data(contentsOf: url)
    }

    static func saveImage(_ data: Data, fileExtension: String) throws -> URL {
        let destination = mediaDirectory.appendingPathComponent("\(UUID().uuidString).\(fileExtension)")
        try data.write(to: destination, options: .atomic)
        return destination
    }

    /// Importa cualquier archivo de imagen o video desde el selector de archivos del iPad o fototeca
    static func importMediaFile(from sourceURL: URL) throws -> (savedPath: String, isVideo: Bool, thumbnailPath: String) {
        let access = sourceURL.startAccessingSecurityScopedResource()
        defer { if access { sourceURL.stopAccessingSecurityScopedResource() } }

        let ext = sourceURL.pathExtension.lowercased()
        let isVideo = MediaKind.videoExtensions.contains(ext)
        let destExt = ext.isEmpty ? (isVideo ? "mp4" : "jpg") : ext
        let destination = mediaDirectory.appendingPathComponent("\(UUID().uuidString).\(destExt)")

        if FileManager.default.fileExists(atPath: destination.path) {
            try? FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: sourceURL, to: destination)

        var thumbnailPath = destination.path
        if isVideo {
            if let thumb = BackgroundStorage.generateVideoThumbnail(for: destination) {
                thumbnailPath = thumb
            }
        }
        return (destination.path, isVideo, thumbnailPath)
    }
}

/// Video importado desde la fototeca (PhotosPicker) copiado al directorio de la app.
struct PickedMovie: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let ext = received.file.pathExtension.isEmpty ? "mov" : received.file.pathExtension
            let destination = MediaStorage.mediaDirectory.appendingPathComponent("\(UUID().uuidString).\(ext)")
            if FileManager.default.fileExists(atPath: destination.path) {
                try? FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: received.file, to: destination)
            return PickedMovie(url: destination)
        }
    }
}

/// Fallback para videos con UTType .video
struct PickedVideo: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .video) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let ext = received.file.pathExtension.isEmpty ? "mp4" : received.file.pathExtension
            let destination = MediaStorage.mediaDirectory.appendingPathComponent("\(UUID().uuidString).\(ext)")
            if FileManager.default.fileExists(atPath: destination.path) {
                try? FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: received.file, to: destination)
            return PickedVideo(url: destination)
        }
    }
}
