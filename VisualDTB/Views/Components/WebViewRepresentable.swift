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
            contentController.add(ScriptMessageProxy(delegate: context.coordinator), name: "videoPlaybackSync")
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
                        var btn = (target.closest) ? target.closest('.ytp-fullscreen-button, .vp-fullscreen-button, button[data-fullscreen], button[aria-label*="pantalla completa" i], button[aria-label*="fullscreen" i], [data-title-no-tooltip="Pantalla completa"], .vjs-fullscreen-control, button.fullscreen, .fullscreen') : null;
                        if (btn) {
                            e.preventDefault();
                            e.stopPropagation();
                            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.fullscreenHandler) {
                                window.webkit.messageHandlers.fullscreenHandler.postMessage('toggleFullscreen');
                            }
                        }
                    }, true);
                }

                // Sincronización de eventos de video entre iPad y TV para Vimeo, YouTube y HTML5
                function setupVideoSync() {
                    document.addEventListener('play', function(e) {
                        if (e.target && e.target.tagName === 'VIDEO') {
                            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.videoPlaybackSync) {
                                window.webkit.messageHandlers.videoPlaybackSync.postMessage({
                                    action: 'play',
                                    time: e.target.currentTime || 0
                                });
                            }
                        }
                    }, true);

                    document.addEventListener('pause', function(e) {
                        if (e.target && e.target.tagName === 'VIDEO') {
                            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.videoPlaybackSync) {
                                window.webkit.messageHandlers.videoPlaybackSync.postMessage({
                                    action: 'pause',
                                    time: e.target.currentTime || 0
                                });
                            }
                        }
                    }, true);

                    document.addEventListener('seeked', function(e) {
                        if (e.target && e.target.tagName === 'VIDEO') {
                            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.videoPlaybackSync) {
                                window.webkit.messageHandlers.videoPlaybackSync.postMessage({
                                    action: 'seek',
                                    time: e.target.currentTime || 0
                                });
                            }
                        }
                    }, true);

                    // Registrar escuchas de eventos en iframes de Vimeo periódicamente
                    function registerIframeListeners() {
                        var iframes = document.querySelectorAll('iframe');
                        for (var i = 0; i < iframes.length; i++) {
                            try {
                                iframes[i].contentWindow.postMessage('{"method":"addEventListener","value":"play"}', '*');
                                iframes[i].contentWindow.postMessage('{"method":"addEventListener","value":"pause"}', '*');
                                iframes[i].contentWindow.postMessage('{"method":"addEventListener","value":"seeked"}', '*');
                            } catch(e) {}
                        }
                    }
                    setInterval(registerIframeListeners, 2000);
                    registerIframeListeners();

                    // Escuchar eventos de iframes de Vimeo y YouTube
                    window.addEventListener('message', function(ev) {
                        try {
                            var d = typeof ev.data === 'string' ? JSON.parse(ev.data) : ev.data;
                            if (d && window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.videoPlaybackSync) {
                                if (d.event === 'play' || d.method === 'play') {
                                    window.webkit.messageHandlers.videoPlaybackSync.postMessage({ action: 'play', time: (d.data && d.data.seconds) ? d.data.seconds : 0 });
                                } else if (d.event === 'pause' || d.method === 'pause') {
                                    window.webkit.messageHandlers.videoPlaybackSync.postMessage({ action: 'pause', time: (d.data && d.data.seconds) ? d.data.seconds : 0 });
                                } else if (d.event === 'seeked') {
                                    window.webkit.messageHandlers.videoPlaybackSync.postMessage({ action: 'seek', time: (d.data && d.data.seconds) ? d.data.seconds : 0 });
                                } else if (d.event === 'ready') {
                                    registerIframeListeners();
                                }
                            }
                        } catch(e) {}
                    });

                    // Detectar toque o clic directo en reproductores de video (Vimeo, YouTube, etc.)
                    document.addEventListener('click', function(e) {
                        var target = e.target;
                        if (!target) return;
                        var isPlayClick = (target.closest) ? target.closest('.vp-play-button, .play-button, button.play, .vp-video-wrapper, [data-play-button], .ytp-play-button, .ytp-large-play-button, button[aria-label*="Play" i], button[aria-label*="Reproducir" i], video') : null;
                        if (isPlayClick) {
                            setTimeout(function() {
                                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.videoPlaybackSync) {
                                    var v = document.querySelector('video');
                                    var isPaused = v ? v.paused : false;
                                    window.webkit.messageHandlers.videoPlaybackSync.postMessage({
                                        action: isPaused ? 'pause' : 'play',
                                        time: v ? (v.currentTime || 0) : 0
                                    });
                                }
                            }, 400);
                        }
                    }, true);
                }

                if (document.readyState === 'loading') {
                    document.addEventListener('DOMContentLoaded', function() {
                        setupFsClick();
                        setupVideoSync();
                    });
                } else {
                    setupFsClick();
                    setupVideoSync();
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
        case .play:
            let js = """
            (function() {
                var vids = document.querySelectorAll('video');
                for (var i = 0; i < vids.length; i++) {
                    vids[i].setAttribute('playsinline', '');
                    vids[i].setAttribute('webkit-playsinline', '');
                    vids[i].muted = false;
                    var p = vids[i].play();
                    if (p && p.catch) {
                        p.catch(function() {
                            vids[i].muted = true;
                            vids[i].play();
                        });
                    }
                }
                var iframes = document.querySelectorAll('iframe');
                for (var j = 0; j < iframes.length; j++) {
                    try {
                        iframes[j].contentWindow.postMessage('{"method":"play"}', '*');
                        iframes[j].contentWindow.postMessage('{"event":"command","func":"playVideo","args":""}', '*');
                    } catch(e) {}
                }
                var playSelectors = [
                    '.vp-play-button',
                    'button[data-play-button]',
                    '.play-button',
                    'button.play',
                    '.vp-overlay-play-button',
                    '.vp-telemetry-play-button',
                    '.vp-preview-play-icon',
                    'button[aria-label*="Play" i]',
                    'button[aria-label*="Reproducir" i]',
                    '.ytp-play-button',
                    '.ytp-large-play-button'
                ];
                for (var k = 0; k < playSelectors.length; k++) {
                    var el = document.querySelector(playSelectors[k]);
                    if (el) {
                        try { el.click(); } catch(e) {}
                    }
                }
                try {
                    if (window.player && typeof window.player.play === 'function') {
                        window.player.play();
                    }
                } catch(e) {}
            })();
            """
            webView.evaluateJavaScript(js, completionHandler: nil)

        case .pause:
            let js = """
            (function() {
                var vids = document.querySelectorAll('video');
                for (var i = 0; i < vids.length; i++) {
                    vids[i].pause();
                }
                var iframes = document.querySelectorAll('iframe');
                for (var j = 0; j < iframes.length; j++) {
                    try {
                        iframes[j].contentWindow.postMessage('{"method":"pause"}', '*');
                        iframes[j].contentWindow.postMessage('{"event":"command","func":"pauseVideo","args":""}', '*');
                    } catch(e) {}
                }
                var pauseSelectors = [
                    '.vp-pause-button',
                    'button[aria-label*="Pause" i]',
                    'button[aria-label*="Pausar" i]',
                    '.ytp-play-button'
                ];
                for (var k = 0; k < pauseSelectors.length; k++) {
                    var el = document.querySelector(pauseSelectors[k]);
                    if (el) {
                        try { el.click(); } catch(e) {}
                    }
                }
                try {
                    if (window.player && typeof window.player.pause === 'function') {
                        window.player.pause();
                    }
                } catch(e) {}
            })();
            """
            webView.evaluateJavaScript(js, completionHandler: nil)

        case .playPause:
            let js = """
            (function() {
                var vids = document.querySelectorAll('video');
                var anyPlaying = false;
                for (var i = 0; i < vids.length; i++) {
                    if (!vids[i].paused && !vids[i].ended && vids[i].readyState > 2) {
                        anyPlaying = true;
                        break;
                    }
                }
                if (vids.length > 0) {
                    for (var i = 0; i < vids.length; i++) {
                        if (anyPlaying) {
                            vids[i].pause();
                        } else {
                            vids[i].play();
                        }
                    }
                }
                var iframes = document.querySelectorAll('iframe');
                for (var j = 0; j < iframes.length; j++) {
                    try {
                        if (anyPlaying) {
                            iframes[j].contentWindow.postMessage('{"method":"pause"}', '*');
                            iframes[j].contentWindow.postMessage('{"event":"command","func":"pauseVideo","args":""}', '*');
                        } else {
                            iframes[j].contentWindow.postMessage('{"method":"play"}', '*');
                            iframes[j].contentWindow.postMessage('{"event":"command","func":"playVideo","args":""}', '*');
                        }
                    } catch(e) {}
                }
                var toggleSelectors = [
                    '.ytp-play-button',
                    '.vp-play-button',
                    'button[data-play-button]',
                    'button[aria-label*="Play" i]',
                    'button[aria-label*="Pause" i]',
                    'button[aria-label*="Reproducir" i]',
                    'button[aria-label*="Pausar" i]'
                ];
                for (var k = 0; k < toggleSelectors.length; k++) {
                    var el = document.querySelector(toggleSelectors[k]);
                    if (el) {
                        try { el.click(); break; } catch(e) {}
                    }
                }
            })();
            """
            webView.evaluateJavaScript(js, completionHandler: nil)

        case .syncTime(let seconds):
            let js = """
            (function() {
                var vids = document.querySelectorAll('video');
                for (var i = 0; i < vids.length; i++) {
                    if (Math.abs((vids[i].currentTime || 0) - \(seconds)) > 1.5) {
                        vids[i].currentTime = \(seconds);
                    }
                }
                var iframes = document.querySelectorAll('iframe');
                for (var j = 0; j < iframes.length; j++) {
                    try {
                        iframes[j].contentWindow.postMessage('{"method":"setCurrentTime","value":\(seconds)}', '*');
                        iframes[j].contentWindow.postMessage('{"event":"command","func":"seekTo","args":[\(seconds),true]}', '*');
                    } catch(e) {}
                }
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
                    var vimeoFsBtn = document.querySelector('.vp-fullscreen-button');
                    if (vimeoFsBtn) {
                        try { vimeoFsBtn.click(); } catch(e) {}
                    }
                    var activeElements = document.querySelectorAll('.dtb-fullscreen-active');
                    for (var i = 0; i < activeElements.length; i++) {
                        activeElements[i].classList.remove('dtb-fullscreen-active');
                    }
                } else {
                    var style = document.createElement('style');
                    style.id = 'dtb-fullscreen-style';
                    style.textContent = `
                        video,
                        .html5-video-player,
                        #player,
                        .video-stream,
                        .player-container,
                        #movie_player,
                        .vp-video-wrapper,
                        .vp-video,
                        .player,
                        div[data-player],
                        div[data-vimeo-initialized],
                        iframe[src*="vimeo.com"],
                        iframe[src*="player.vimeo.com"],
                        iframe[src*="youtube.com"],
                        .dtb-fullscreen-active {
                            position: fixed !important;
                            top: 0 !important;
                            left: 0 !important;
                            width: 100vw !important;
                            height: 100vh !important;
                            max-width: 100vw !important;
                            max-height: 100vh !important;
                            padding: 0 !important;
                            margin: 0 !important;
                            z-index: 2147483640 !important;
                            background: black !important;
                            object-fit: contain !important;
                            box-sizing: border-box !important;
                        }
                        .vp-controls-wrapper,
                        .vp-controls,
                        .ytp-chrome-bottom,
                        .ytp-chrome-top,
                        .vjs-control-bar {
                            z-index: 2147483647 !important;
                        }
                        body, html {
                            overflow: hidden !important;
                            background: black !important;
                        }
                    `;
                    document.head.appendChild(style);

                    // Detectar y maximizar videos y contenedores
                    var vids = document.querySelectorAll('video');
                    for (var i = 0; i < vids.length; i++) {
                        var v = vids[i];
                        v.classList.add('dtb-fullscreen-active');
                        v.style.setProperty('object-fit', 'contain', 'important');
                        var parent = v.closest('.vp-video-wrapper, .player, div[data-player], .html5-video-player, .player-container');
                        if (parent) {
                            parent.classList.add('dtb-fullscreen-active');
                            parent.style.setProperty('padding', '0', 'important');
                            parent.style.setProperty('height', '100vh', 'important');
                        }
                    }
                    var iframes = document.querySelectorAll('iframe[src*="vimeo"], iframe[src*="youtube"], iframe[src*="player"]');
                    for (var j = 0; j < iframes.length; j++) {
                        iframes[j].classList.add('dtb-fullscreen-active');
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
            } else if message.name == "videoPlaybackSync", let dict = message.body as? [String: Any], let action = dict["action"] as? String {
                let time = dict["time"] as? Double ?? 0.0
                DispatchQueue.main.async {
                    if action == "play" {
                        self.parent.appState.sendWebCommand(.play)
                    } else if action == "pause" {
                        self.parent.appState.sendWebCommand(.pause)
                    } else if action == "seek" {
                        self.parent.appState.sendWebCommand(.syncTime(seconds: time))
                    }
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
            if parent.mode == .external {
                let tvSetup = """
                (function() {
                    var vids = document.querySelectorAll('video');
                    for (var i = 0; i < vids.length; i++) {
                        vids[i].setAttribute('playsinline', '');
                        vids[i].setAttribute('webkit-playsinline', '');
                        vids[i].style.setProperty('object-fit', 'contain', 'important');
                    }
                })();
                """
                webView.evaluateJavaScript(tvSetup, completionHandler: nil)
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
