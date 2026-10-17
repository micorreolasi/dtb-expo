import SwiftUI
import WebKit

struct WebViewRepresentable: UIViewRepresentable {
    @EnvironmentObject var appState: AppState
    let urlString: String
    var mode: ProjectionMode = .presentation
    var onNavigation: ((String) -> Void)? = nil
    var navAction: DocumentNavAction? = nil
    var navTriggerId: UUID? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.preferences.javaScriptCanOpenWindowsAutomatically = true

        let contentController = WKUserContentController()
        if mode != .external {
            contentController.add(ScriptMessageProxy(delegate: context.coordinator), name: "fullscreenHandler")
            let js = """
            (function() {
                try {
                    if (window.HTMLVideoElement) {
                        HTMLVideoElement.prototype.webkitEnterFullscreen = function() {
                            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.fullscreenHandler) {
                                window.webkit.messageHandlers.fullscreenHandler.postMessage('toggleFullscreen');
                            }
                            return false;
                        };
                    }
                } catch(e) {}

                try {
                    if (window.Element && Element.prototype.requestFullscreen) {
                        Element.prototype.requestFullscreen = function() {
                            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.fullscreenHandler) {
                                window.webkit.messageHandlers.fullscreenHandler.postMessage('toggleFullscreen');
                            }
                            return Promise.resolve();
                        };
                    }
                } catch(e) {}

                function setupFsClick() {
                    document.addEventListener('click', function(e) {
                        var target = e.target;
                        if (!target) return;
                        var btn = (target.closest) ? target.closest('.ytp-fullscreen-button, button[aria-label*="pantalla completa" i], button[aria-label*="fullscreen" i], [data-title-no-tooltip="Pantalla completa"], .vjs-fullscreen-control, button.fullscreen') : null;
                        if (btn) {
                            e.preventDefault();
                            e.stopPropagation();
                            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.fullscreenHandler) {
                                window.webkit.messageHandlers.fullscreenHandler.postMessage('toggleFullscreen');
                            }
                        }
                    }, true);
                }

                if (document.readyState === 'loading') {
                    document.addEventListener('DOMContentLoaded', setupFsClick);
                } else {
                    setupFsClick();
                }
            })();
            """
            let userScript = WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: false)
            contentController.addUserScript(userScript)
        }
        config.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.bounces = true
        webView.scrollView.delegate = context.coordinator
        webView.backgroundColor = .black
        webView.isOpaque = false

        // User Agent optimizado para iPad que previene redirecciones circulares en YouTube
        webView.customUserAgent = "Mozilla/5.0 (iPad; CPU OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1"

        context.coordinator.lastLoadedURL = urlString
        loadURL(in: webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.parent = self

        // 1. Cargar únicamente si el usuario cambió intencionalmente la URL en la app
        // (NUNCA comparar contra uiView.url porque YouTube hace redirecciones internas y PPTX usa rutas temporales)
        if context.coordinator.lastLoadedURL != urlString {
            context.coordinator.lastLoadedURL = urlString
            loadURL(in: uiView)
        }

        // 2. Si es la TV externa (modo .external) o vista previa sin tocar, sincronizar el scroll y el zoom
        if mode == .external || (mode == .miniPreview && !uiView.scrollView.isTracking && !uiView.scrollView.isDragging) {
            let sv = uiView.scrollView

            // Sincronizar zoom en PPTX / Web si aplica
            if sv.minimumZoomScale < sv.maximumZoomScale, appState.documentZoomScale > 0 {
                let targetZoom = max(sv.minimumZoomScale, min(sv.maximumZoomScale, appState.documentZoomScale))
                if abs(sv.zoomScale - targetZoom) > 0.05 {
                    sv.setZoomScale(targetZoom, animated: false)
                }
            }

            // Sincronizar posición vertical
            let maxOffset = max(0, sv.contentSize.height - sv.bounds.height)
            if maxOffset > 0 {
                let targetY = maxOffset * appState.webScrollRatio
                if abs(sv.contentOffset.y - targetY) > 2 {
                    sv.setContentOffset(CGPoint(x: sv.contentOffset.x, y: targetY), animated: false)
                }
            }
        }

        // 3. Manejo de botones de salto de página (Hoja Siguiente / Anterior en PPTX / Keynote / Documentos Web)
        if let triggerId = navTriggerId, triggerId != context.coordinator.lastTriggerId {
            context.coordinator.lastTriggerId = triggerId
            let sv = uiView.scrollView
            let pageHeight = max(200, sv.bounds.height * 0.85)
            let currentOffset = sv.contentOffset.y
            let maxOffset = max(0, sv.contentSize.height - sv.bounds.height)

            if maxOffset > 0 {
                let targetOffset: CGFloat
                if navAction == .next {
                    targetOffset = min(maxOffset, currentOffset + pageHeight)
                } else if navAction == .prev {
                    targetOffset = max(0, currentOffset - pageHeight)
                } else {
                    targetOffset = currentOffset
                }
                sv.setContentOffset(CGPoint(x: sv.contentOffset.x, y: targetOffset), animated: true)
                if mode != .external {
                    let ratio = max(0.0, min(1.0, targetOffset / maxOffset))
                    DispatchQueue.main.async {
                        self.appState.webScrollRatio = ratio
                    }
                }
            }
        }

        // 4. Ejecución de Controles de Video Web (YouTube y reproductores HTML5)
        if context.coordinator.lastWebActionId != appState.webControlTriggerId, let cmd = appState.webControlCommand {
            context.coordinator.lastWebActionId = appState.webControlTriggerId
            executeWebCommand(cmd, in: uiView)
        }
    }

    private func executeWebCommand(_ command: WebControlCommand, in webView: WKWebView) {
        switch command {
        case .playPause:
            let js = """
            (function() {
                var vids = document.querySelectorAll('video');
                if (vids.length > 0) {
                    var anyPlaying = false;
                    for (var i = 0; i < vids.length; i++) {
                        if (!vids[i].paused && !vids[i].ended && vids[i].readyState > 2) {
                            anyPlaying = true;
                            break;
                        }
                    }
                    for (var i = 0; i < vids.length; i++) {
                        if (anyPlaying) {
                            vids[i].pause();
                        } else {
                            vids[i].play();
                        }
                    }
                    return;
                }
                var playBtn = document.querySelector('.ytp-play-button') || document.querySelector('button[aria-label="Play"]') || document.querySelector('button[aria-label="Pause"]');
                if (playBtn) playBtn.click();
            })();
            """
            webView.evaluateJavaScript(js, completionHandler: nil)

        case .rewind(let seconds):
            let js = """
            (function() {
                var vids = document.querySelectorAll('video');
                for (var i = 0; i < vids.length; i++) {
                    vids[i].currentTime = Math.max(0, (vids[i].currentTime || 0) - \(seconds));
                }
            })();
            """
            webView.evaluateJavaScript(js, completionHandler: nil)

        case .forward(let seconds):
            let js = """
            (function() {
                var vids = document.querySelectorAll('video');
                for (var i = 0; i < vids.length; i++) {
                    var maxD = vids[i].duration || 999999;
                    vids[i].currentTime = Math.min(maxD, (vids[i].currentTime || 0) + \(seconds));
                }
            })();
            """
            webView.evaluateJavaScript(js, completionHandler: nil)

        case .toggleMute:
            let js = """
            (function() {
                var vids = document.querySelectorAll('video');
                for (var i = 0; i < vids.length; i++) {
                    vids[i].muted = !vids[i].muted;
                }
                var muteBtn = document.querySelector('.ytp-mute-button');
                if (muteBtn) muteBtn.click();
            })();
            """
            webView.evaluateJavaScript(js, completionHandler: nil)

        case .reload:
            webView.reload()

        case .toggleFullscreen:
            let js = """
            (function() {
                var existing = document.getElementById('dtb-fullscreen-style');
                if (existing) {
                    existing.remove();
                    var ytFsBtn = document.querySelector('.ytp-fullscreen-button');
                    if (ytFsBtn && ytFsBtn.getAttribute('title') && ytFsBtn.getAttribute('title').toLowerCase().indexOf('salir') !== -1) {
                        try { ytFsBtn.click(); } catch(e) {}
                    }
                } else {
                    var style = document.createElement('style');
                    style.id = 'dtb-fullscreen-style';
                    style.textContent = `
                        video, .html5-video-player, #player, .video-stream, .player-container, #movie_player {
                            position: fixed !important;
                            top: 0 !important;
                            left: 0 !important;
                            width: 100vw !important;
                            height: 100vh !important;
                            max-width: 100vw !important;
                            max-height: 100vh !important;
                            z-index: 2147483647 !important;
                            background: black !important;
                            object-fit: contain !important;
                        }
                        body, html {
                            overflow: hidden !important;
                            background: black !important;
                        }
                    `;
                    document.head.appendChild(style);
                    var vid = document.querySelector('video');
                    if (vid) {
                        vid.style.objectFit = 'contain';
                    }
                }
            })();
            """
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    private func loadURL(in webView: WKWebView) {
        let clean = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }

        if clean.hasPrefix("http://") || clean.hasPrefix("https://"), let url = URL(string: clean) {
            webView.load(URLRequest(url: url))
        } else {
            let cleanPath: String = {
                if clean.hasPrefix("file://"), let u = URL(string: clean) {
                    return u.path
                }
                return clean
            }()
            let localURL = URL(fileURLWithPath: cleanPath)
            let accessDir = localURL.deletingLastPathComponent().deletingLastPathComponent()
            webView.loadFileURL(localURL, allowingReadAccessTo: accessDir)
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate, UIScrollViewDelegate, WKScriptMessageHandler {
        var parent: WebViewRepresentable
        var lastTriggerId: UUID? = nil
        var lastLoadedURL: String? = nil
        var lastWebActionId: UUID? = nil

        init(_ parent: WebViewRepresentable) {
            self.parent = parent
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "fullscreenHandler" {
                DispatchQueue.main.async {
                    self.parent.appState.sendWebCommand(.toggleFullscreen)
                }
            }
        }

        // Captura el scroll y zoom en el iPad y lo envía a AppState para reflejarlo en el TV
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard parent.mode != .external, (scrollView.isTracking || scrollView.isDragging || scrollView.isDecelerating) else { return }
            let maxOffset = max(1, scrollView.contentSize.height - scrollView.bounds.height)
            let ratio = max(0.0, min(1.0, scrollView.contentOffset.y / maxOffset))
            DispatchQueue.main.async {
                self.parent.appState.webScrollRatio = ratio
            }
        }

        func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
            guard parent.mode != .external else { return }
            DispatchQueue.main.async {
                self.parent.appState.documentZoomScale = scale
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if let current = webView.url?.absoluteString {
                parent.onNavigation?(current)
            }
        }

        // Manejar links que abren en nueva ventana o target="_blank" (muy común en YouTube)
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }
    }
}

private class ScriptMessageProxy: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?
    init(delegate: WKScriptMessageHandler) {
        self.delegate = delegate
    }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        delegate?.userContentController(userContentController, didReceive: message)
    }
}
