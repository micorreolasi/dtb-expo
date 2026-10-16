import Foundation
import CoreTransferable
import UniformTypeIdentifiers
import AVFoundation
import UIKit

// MARK: - Persistencia de Órdenes de Culto (equivalente a serviceStorage.ts)

enum ServiceStorage {
    private static let queue = DispatchQueue(label: "visualdtb.service-storage")

    static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("dtb_service_orders_v1.json")
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
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("dtb_custom_backgrounds_v1.json")
    }

    static var activeFileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("dtb_active_background_v1.json")
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

    /// Genera una miniatura JPEG rápida de un video
    static func generateVideoThumbnail(for videoURL: URL) -> String? {
        let asset = AVURLAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 480, height: 270)
        let time = CMTime(seconds: 1, preferredTimescale: 60)
        if let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) {
            let uiImage = UIImage(cgImage: cgImage)
            if let data = uiImage.jpegData(compressionQuality: 0.8) {
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
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Media", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Copia un documento elegido con el selector a la caché (equivale a `copyToCacheDirectory: true`).
    static func importDocument(from url: URL) throws -> URL {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }

        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("Documents", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let destination = dir.appendingPathComponent(url.lastPathComponent)
        try FileManager.default.copyItem(at: url, to: destination)
        return destination
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
            try FileManager.default.copyItem(at: received.file, to: destination)
            return PickedMovie(url: destination)
        }
    }
}
