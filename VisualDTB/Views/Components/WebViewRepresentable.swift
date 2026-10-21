import SwiftUI
import WebKit

/// Entorno global compartido para WebKit (misma caché, almacenamiento y pool de procesos entre iPad y TV)
final class WebKitEnvironment {
    static let sharedProcessPool = WKProcessPool()
}

struct WebViewRepresentable: UIViewRepresentable {
    @EnvironmentObject var appState: AppState
    let urlString: String
    var mode: ProjectionMode = .presentation
    var scrollRatio: CGFloat = 0.0
    var scrollOffsetRatio: CGPoint = .zero
    var onNavigation: ((String) -> Void)? = nil
    var navAction: DocumentNavAction? = nil
    var navTriggerId: UUID? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.processPool = WebKitEnvironment.sharedProcessPool
        config.websiteDataStore = WKWebsiteDataStore.default()
        config.allowsInlineMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.preferences.javaScriptCanOpenWindowsAutomatically = true

        let contentController = WKUserContentController()
        if mode != .external {
            contentController.add(ScriptMessageProxy(delegate: context.coordinator), name: "fullscreenHandler")
            contentController.add(ScriptMessageProxy(delegate: context.coordinator), name: "videoPlaybackSync")
            contentController.add(ScriptMessageProxy(delegate: context.coordinator), name: "clickMirrorHandler")
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

                // Reflejar toques, clics, reproducciones y cierre de popups desde el iPad hacia la TV
                function setupClickMirror() {
                    var lastMirrorTime = 0;
                    function handleMirror(e) {
                        var now = Date.now();
                        if (now - lastMirrorTime < 120) return;
                        lastMirrorTime = now;
                        var target = e.target;
                        if (!target) return;
                        var touch = e.changedTouches ? e.changedTouches[0] : e;
                        var clientX = touch.clientX || (window.innerWidth * 0.5);
                        var clientY = touch.clientY || (window.innerHeight * 0.5);
                        var xR = clientX / window.innerWidth;
                        var yR = clientY / window.innerHeight;
                        var sel = '';
                        if (target.id) {
                            sel = '#' + target.id;
                        } else if (target.className && typeof target.className === 'string') {
                            var cls = target.className.trim().split(/\\s+/).filter(function(c) { return c && !c.includes(':'); }).slice(0, 2).join('.');
                            if (cls) sel = target.tagName.toLowerCase() + '.' + cls;
                        }
                        if (!sel) sel = target.tagName.toLowerCase();

                        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.clickMirrorHandler) {
                            window.webkit.messageHandlers.clickMirrorHandler.postMessage({
                                xRatio: xR,
                                yRatio: yR,
                                selector: sel
                            });
                        }
                    }

                    document.addEventListener('touchend', handleMirror, true);
                    document.addEventListener('click', handleMirror, true);
                }

                // Sincronización segura de eventos de video iPad -> TV (anti-bucle y anti-bloqueo)
                function setupVideoSync() {
                    var lastAction = '';
                    var lastActionTime = 0;

                    function dispatchSync(action, time) {
                        var now = Date.now();
                        if (lastAction === action && (now - lastActionTime) < 2000) return;
                        lastAction = action;
                        lastActionTime = now;
                        try {
                            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.videoPlaybackSync) {
                                window.webkit.messageHandlers.videoPlaybackSync.postMessage({
                                    action: action,
                                    time: time || 0
                                });
                            }
                        } catch(e) {}
                    }

                    document.addEventListener('play', function(e) {
                        if (e.target && e.target.tagName === 'VIDEO') {
                            dispatchSync('play', e.target.currentTime || 0);
                        }
                    }, true);

                    document.addEventListener('pause', function(e) {
                        if (e.target && e.target.tagName === 'VIDEO') {
                            dispatchSync('pause', e.target.currentTime || 0);
                        }
                    }, true);

                    document.addEventListener('seeked', function(e) {
                        if (e.target && e.target.tagName === 'VIDEO') {
                            dispatchSync('seek', e.target.currentTime || 0);
                        }
                    }, true);

                    // Escuchar eventos de iframe de forma pasiva y sin re-suscripciones circulares
                    window.addEventListener('message', function(ev) {
                        try {
                            var d = typeof ev.data === 'string' ? JSON.parse(ev.data) : ev.data;
                            if (d && d.event) {
                                if (d.event === 'play') {
                                    dispatchSync('play', (d.data && d.data.seconds) ? d.data.seconds : 0);
                                } else if (d.event === 'pause') {
                                    dispatchSync('pause', (d.data && d.data.seconds) ? d.data.seconds : 0);
                                } else if (d.event === 'seeked') {
                                    dispatchSync('seek', (d.data && d.data.seconds) ? d.data.seconds : 0);
                                }
                            }
                        } catch(e) {}
                    });
                }

                if (document.readyState === 'loading') {
                    document.addEventListener('DOMContentLoaded', function() {
                        setupFsClick();
                        setupClickMirror();
                        setupVideoSync();
                    });
                } else {
                    setupFsClick();
                    setupClickMirror();
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
        let sv = uiView.scrollView
        if mode == .external || (!sv.isTracking && !sv.isDragging) {
            // Sincronizar zoom en PPTX / Web si aplica
            if sv.minimumZoomScale < sv.maximumZoomScale, appState.documentZoomScale > 0 {
                let targetZoom = max(sv.minimumZoomScale, min(sv.maximumZoomScale, appState.documentZoomScale))
                if abs(sv.zoomScale - targetZoom) > 0.05 {
                    sv.setZoomScale(targetZoom, animated: false)
                }
            }

            // Sincronizar posición vertical (documentos .key / .pptx usan documentScrollOffsetRatio, web usa webScrollRatio)
            let maxOffset = max(0, sv.contentSize.height - sv.bounds.height)
            let activeRatio = appState.isDocumentActive ? scrollOffsetRatio.y : scrollRatio
            if maxOffset > 0 {
                let targetY = maxOffset * activeRatio
                if abs(sv.contentOffset.y - targetY) > 2 {
                    sv.setContentOffset(CGPoint(x: sv.contentOffset.x, y: targetY), animated: false)
                }
            }

            // Sincronizar scroll por DOM para diapositivas .key en QuickLook y HTML
            let jsScroll = """
            (function() {
                var maxH = Math.max(document.body.scrollHeight, document.documentElement.scrollHeight) - window.innerHeight;
                if (maxH > 0) {
                    window.scrollTo({ top: maxH * \(activeRatio), behavior: 'instant' });
                }
            })();
            """
            uiView.evaluateJavaScript(jsScroll, completionHandler: nil)
        }

        // 3. Manejo de botones de salto de página (Hoja Siguiente / Anterior en PPTX / Keynote / Documentos Web)
        if let triggerId = navTriggerId, triggerId != context.coordinator.lastTriggerId {
            context.coordinator.lastTriggerId = triggerId
            let sv = uiView.scrollView
            let maxOffset = max(0, sv.contentSize.height - sv.bounds.height)

            if maxOffset > 0 {
                let pageHeight = max(200, sv.bounds.height * 0.90)
                let currentOffset = sv.contentOffset.y
                let targetOffset: CGFloat
                if navAction == .next {
                    targetOffset = min(maxOffset, currentOffset + pageHeight)
                } else if navAction == .prev {
                    targetOffset = max(0, currentOffset - pageHeight)
                } else {
                    targetOffset = currentOffset
                }
                sv.setContentOffset(CGPoint(x: sv.contentOffset.x, y: targetOffset), animated: true)
                let ratio = max(0.0, min(1.0, targetOffset / maxOffset))
                DispatchQueue.main.async {
                    self.appState.documentScrollOffsetRatio.y = ratio
                    self.appState.webScrollRatio = ratio
                }
            }
        }

        // 4. Ejecución de Controles de Video Web (desde la botonera DTB)
        if context.coordinator.lastWebActionId != appState.webControlTriggerId, let cmd = appState.webControlCommand {
            context.coordinator.lastWebActionId = appState.webControlTriggerId
            executeWebCommand(cmd, in: uiView)
        }

        // 5. Ejecución de sincronización de video iPad -> TV (exclusivo para modo .external, nunca en iPad)
        if mode == .external, context.coordinator.lastExternalActionId != appState.externalWebControlTriggerId, let cmd = appState.externalWebControlCommand {
            context.coordinator.lastExternalActionId = appState.externalWebControlTriggerId
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
                var playBtns = document.querySelectorAll('.vp-play-button, .play, button[data-title-play], .ytp-play-button[aria-label*="Play" i], .ytp-play-button[aria-label*="Reproducir" i]');
                for (var k = 0; k < playBtns.length; k++) {
                    try { playBtns[k].click(); } catch(e) {}
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
                // 1. Intentar botón de pantalla completa propio del reproductor (Vimeo / YouTube)
                var vimeoFsBtn = document.querySelector('.vp-fullscreen-button');
                if (vimeoFsBtn) {
                    try { vimeoFsBtn.click(); return; } catch(e) {}
                }
                var ytFsBtn = document.querySelector('.ytp-fullscreen-button');
                if (ytFsBtn) {
                    try { ytFsBtn.click(); return; } catch(e) {}
                }
                // 2. Intentar API nativa webkitEnterFullscreen en <video>
                var vids = document.querySelectorAll('video');
                for (var i = 0; i < vids.length; i++) {
                    if (vids[i].webkitEnterFullscreen) {
                        try { vids[i].webkitEnterFullscreen(); return; } catch(e) {}
                    }
                }
                // 3. PostMessage a iframes embebidos
                var iframes = document.querySelectorAll('iframe');
                for (var j = 0; j < iframes.length; j++) {
                    try {
                        iframes[j].contentWindow.postMessage('{"method":"requestFullscreen"}', '*');
                    } catch(e) {}
                }
            })();
            """
            webView.evaluateJavaScript(js, completionHandler: nil)

        case .dismissPopups:
            let js = """
            (function() {
                var gp = document.getElementById('credential_picker_container') || document.querySelector('iframe[src*="accounts.google.com/gsi"]');
                if (gp) gp.remove();
                var cookieBtn = document.querySelector('#onetrust-accept-btn-handler, button[aria-label*="Accept" i], button[aria-label*="Aceptar" i], .cookie-close, [aria-label*="Close" i]');
                if (cookieBtn) {
                    try { cookieBtn.click(); } catch(e) {}
                }
                var modals = document.querySelectorAll('#credential_picker_container, .onetrust-pc-dark-filter, #onetrust-consent-sdk, .cookie-banner');
                for (var i = 0; i < modals.length; i++) {
                    modals[i].remove();
                }
            })();
            """
            webView.evaluateJavaScript(js, completionHandler: nil)

        case .mirrorClick(let xRatio, let yRatio, let selector):
            let js = """
            (function() {
                // 1. Eliminar popup de Google si estuviera visible
                var gp = document.getElementById('credential_picker_container') || document.querySelector('iframe[src*="accounts.google.com/gsi"]');
                if (gp) {
                    gp.remove();
                    if (\(xRatio) > 0.5 && \(yRatio) < 0.35) return;
                }

                // 2. Click por selector directo si existe
                if ('\(selector)' && '\(selector)' !== '') {
                    try {
                        var elSel = document.querySelector('\(selector)');
                        if (elSel) {
                            elSel.click();
                            var pBtn = elSel.closest('button, a, [role="button"], video, .play, .vp-play-button');
                            if (pBtn && pBtn !== elSel) pBtn.click();
                            return;
                        }
                    } catch(e) {}
                }

                // 3. Simulación de toque y click en la coordenada proporcional
                var x = window.innerWidth * \(xRatio);
                var y = window.innerHeight * \(yRatio);
                var el = document.elementFromPoint(x, y);
                if (el) {
                    try {
                        el.click();
                        var btn = el.closest('button, a, [role="button"], video, .play, .vp-play-button');
                        if (btn && btn !== el) btn.click();
                    } catch(e) {}
                }

                // 4. Si el toque fue en el área del reproductor, garantizar reproducción
                if (\(xRatio) > 0.10 && \(xRatio) < 0.90 && \(yRatio) > 0.10 && \(yRatio) < 0.90) {
                    var vids = document.querySelectorAll('video');
                    for (var i = 0; i < vids.length; i++) {
                        vids[i].setAttribute('playsinline', '');
                        vids[i].setAttribute('webkit-playsinline', '');
                        try {
                            if (vids[i].paused) {
                                var p = vids[i].play();
                                if (p && p.catch) {
                                    p.catch(function() {
                                        vids[i].muted = true;
                                        vids[i].play();
                                    });
                                }
                            }
                        } catch(e) {}
                    }
                    var iframes = document.querySelectorAll('iframe');
                    for (var j = 0; j < iframes.length; j++) {
                        try {
                            iframes[j].contentWindow.postMessage('{"method":"play"}', '*');
                            iframes[j].contentWindow.postMessage('{"event":"command","func":"playVideo","args":""}', '*');
                        } catch(e) {}
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
        var lastExternalActionId: UUID? = nil
        var lastSyncReceivedTime: Date = .distantPast

        init(_ parent: WebViewRepresentable) {
            self.parent = parent
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "fullscreenHandler" {
                DispatchQueue.main.async {
                    self.parent.appState.sendWebCommand(.toggleFullscreen)
                }
            } else if message.name == "clickMirrorHandler", let dict = message.body as? [String: Any] {
                let xRatio = dict["xRatio"] as? Double ?? 0.5
                let yRatio = dict["yRatio"] as? Double ?? 0.5
                let sel = dict["selector"] as? String ?? ""
                DispatchQueue.main.async {
                    self.parent.appState.sendExternalWebCommand(.mirrorClick(xRatio: xRatio, yRatio: yRatio, selector: sel))
                }
            } else if message.name == "videoPlaybackSync", let dict = message.body as? [String: Any], let action = dict["action"] as? String {
                let now = Date()
                guard now.timeIntervalSince(self.lastSyncReceivedTime) >= 1.5 else { return }
                self.lastSyncReceivedTime = now

                let time = dict["time"] as? Double ?? 0.0
                DispatchQueue.main.async {
                    if action == "play" {
                        self.parent.appState.sendExternalWebCommand(.play)
                    } else if action == "pause" {
                        self.parent.appState.sendExternalWebCommand(.pause)
                    } else if action == "seek" {
                        self.parent.appState.sendExternalWebCommand(.syncTime(seconds: time))
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
                if self.parent.appState.isDocumentActive {
                    self.parent.appState.documentScrollOffsetRatio.y = ratio
                }
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
                    var style = document.createElement('style');
                    style.id = 'dtb-tv-clean-style';
                    style.textContent = `
                        #credential_picker_container,
                        iframe[src*="accounts.google.com/gsi"],
                        div[id*="google-signin"],
                        div[class*="google-one-tap"],
                        .g_id_onload,
                        #onetrust-consent-sdk,
                        .cookie-banner,
                        div[class*="cookie-notice"],
                        div[class*="consent-banner"] {
                            display: none !important;
                            visibility: hidden !important;
                            pointer-events: none !important;
                        }
                    `;
                    document.head.appendChild(style);

                    function cleanPopups() {
                        var gp = document.getElementById('credential_picker_container') || document.querySelector('iframe[src*="accounts.google.com/gsi"]');
                        if (gp) gp.remove();
                    }
                    cleanPopups();
                    setInterval(cleanPopups, 1500);

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
