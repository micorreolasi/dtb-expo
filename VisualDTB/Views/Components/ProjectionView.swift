import SwiftUI
import AVFoundation
import UIKit

struct ProjectionView: View {
    @EnvironmentObject var appState: AppState
    let mode: ProjectionMode

    var body: some View {
        GeometryReader { proxy in
            let isCompact = min(proxy.size.width, proxy.size.height) < 600

            ZStack {
                Color.black.ignoresSafeArea()

                if !appState.isBlackout {
                    // 1. Fondo Multimedia (Imagen o Video)
                    if let bg = appState.backgroundMedia {
                        switch bg.type {
                        case .image:
                            ProjectionImageView(uri: bg.uri, contentMode: .fill)
                                .frame(width: proxy.size.width, height: proxy.size.height)
                                .clipped()
                                .id("bg-img-\(bg.uri)")
                        case .video:
                            SafeVideoPlayerView(
                                uri: bg.uri,
                                contentFit: .fill,
                                muted: true,
                                volume: 0,
                                loop: true,
                                isPaused: appState.isPaused,
                                nativeControls: false
                            )
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .clipped()
                            .id("bg-vid-\(bg.uri)")
                        }
                    }

                    // 2. Contenido Proyectado Activo
                    contentView(isCompact: isCompact, width: proxy.size.width, height: proxy.size.height)

                    // 3. Atenuador de Brillo
                    if appState.brightness < 100 {
                        Color.black
                            .opacity(1.0 - (appState.brightness / 100.0))
                            .allowsHitTesting(false)
                    }

                    // 4. Cintillo Animado (Marquee)
                    if !appState.activeMarquee.isEmpty {
                        VStack {
                            Spacer()
                            MarqueeBannerView(
                                text: appState.activeMarquee,
                                repsString: appState.messageReps,
                                speed: appState.marqueeSpeed,
                                mode: mode,
                                isCompact: isCompact,
                                triggerId: appState.marqueeTriggerId
                            )
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func contentView(isCompact: Bool, width: CGFloat, height: CGFloat) -> some View {
        switch appState.projection.type {
        case .text:
            DynamicProjectionTextView(
                content: appState.projection.content,
                mode: mode,
                textColorHex: appState.textColorHex,
                textHasBackground: appState.textHasBackground,
                sizeMultiplier: CGFloat(appState.textSize / 48.0),
                isCompact: isCompact
            )

        case .image:
            ProjectionImageView(uri: appState.projection.content, contentMode: .fit)
                .frame(width: width, height: height)
                .clipped()
                .id("proj-img-\(appState.projection.content)")

        case .video:
            let shouldMute = (mode == .miniPreview) && (appState.hasExternalDisplay && appState.externalDisplayEnabled)
            SafeVideoPlayerView(
                uri: appState.projection.content,
                contentFit: .fit,
                muted: shouldMute,
                volume: 1.0,
                loop: true,
                isPaused: appState.isPaused,
                nativeControls: mode == .presentation
            )
            .frame(width: width, height: height)
            .clipped()
            .id("proj-vid-\(appState.projection.content)")

        case .web:
            WebViewRepresentable(urlString: appState.projection.content, mode: mode)

        case .pdf, .document:
            PDFDocumentView(uri: appState.projection.content, mode: mode)
        }
    }
}

/// Helper para cargar imágenes locales o remotas
struct ProjectionImageView: View {
    let uri: String
    let contentMode: ContentMode

    var body: some View {
        Group {
            if uri.hasPrefix("http://") || uri.hasPrefix("https://") {
                if let url = URL(string: uri) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: contentMode)
                        case .failure:
                            Color.black
                        case .empty:
                            Color.black
                        @unknown default:
                            Color.black
                        }
                    }
                } else {
                    Color.black
                }
            } else if let uiImage = loadLocalImage(uri: uri) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                Color.black
            }
        }
        .clipped()
    }

    private func loadLocalImage(uri: String) -> UIImage? {
        let resolved = BackgroundStorage.resolveURI(uri)
        if let img = UIImage(contentsOfFile: resolved) {
            return img
        }
        let cleanPath: String = {
            if uri.hasPrefix("file://"), let u = URL(string: uri) {
                return u.path
            }
            return uri
        }()
        if let img = UIImage(contentsOfFile: cleanPath) {
            return img
        }
        // Fallback de miniatura para archivos de video
        let ext = (cleanPath as NSString).pathExtension.lowercased()
        if MediaKind.videoExtensions.contains(ext) {
            let fileURL = URL(fileURLWithPath: resolved)
            let asset = AVURLAsset(url: fileURL)
            let gen = AVAssetImageGenerator(asset: asset)
            gen.appliesPreferredTrackTransform = true
            gen.maximumSize = CGSize(width: 480, height: 270)
            if let cg = try? gen.copyCGImage(at: CMTime(seconds: 1, preferredTimescale: 60), actualTime: nil) {
                return UIImage(cgImage: cg)
            }
        }
        return UIImage(named: uri)
    }
}
