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

    static func isValidTopLevelWebUrl(_ urlString: String) -> Bool {
        guard urlString.hasPrefix("http://") || urlString.hasPrefix("https://") else { return false }
        let lower = urlString.lowercased()
        if lower.contains("proxy.html") ||
           lower.contains("/static/proxy") ||
           lower.contains("about:blank") ||
           lower.contains("accounts.google.com/gsi") ||
           lower.contains("doubleclick.net") {
            return false
        }
        return true
    }

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
            contentController.add(ScriptMessageProxy(delegate: context.coordinator), name: "videoPlaybackSync")
            contentController.add(ScriptMessageProxy(delegate: context.coordinator), name: "clickMirrorHandler")
            contentController.add(ScriptMessageProxy(delegate: context.coordinator), name: "urlChangeHandler")
            contentController.add(ScriptMessageProxy(delegate: context.coordinator), name: "inputSyncHandler")
            contentController.add(ScriptMessageProxy(delegate: context.coordinator), name: "documentPageCountHandler")

            let js = """
            (function() {
                // Detección precisa de diapositivas en presentaciones (.key, .pptx, QuickLook)
                function detectDocumentPages() {
                    try {
                        var slides = document.querySelectorAll('.slide, .page, section, [data-slide-index], [data-page-number], div[id*="slide"], canvas');
                        var count = 0;
                        if (slides && slides.length > 1) {
                            count = slides.length;
                        } else {
                            var totalH = Math.max(document.body.scrollHeight, document.documentElement.scrollHeight, document.body.offsetHeight);
                            var vh = window.innerHeight || 768;
                            if (totalH > vh * 1.1) {
                                count = Math.max(1, Math.round(totalH / vh));
                            } else {
                                count = 1;
                            }
                        }
                        if (count > 1 && window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.documentPageCountHandler) {
                            window.webkit.messageHandlers.documentPageCountHandler.postMessage(count);
                        }
                    } catch(e) {}
                }

                // Sincronización continua de URLs para SPAs (YouTube, Vimeo, etc.)
                function setupUrlChangeSync() {
                    // CRÍTICO: SOLO el frame principal (window.top) debe reportar cambios de URL
                    // Las páginas como Vimeo cargan iframes auxiliares (ej: player.vimeo.com/static/proxy.html)
                    // que NUNCA deben reportarse como URL principal.
                    if (window !== window.top) return;

                    var lastReportedUrl = location.href;
                    function reportUrl(u) {
                        if (!u || u === lastReportedUrl) return;
                        if (u.indexOf('http') !== 0) return;
                        if (u.indexOf('proxy.html') !== -1 || u.indexOf('about:blank') !== -1) return;
                        lastReportedUrl = u;
                        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.urlChangeHandler) {
                            window.webkit.messageHandlers.urlChangeHandler.postMessage(u);
                        }
                    }

                    try {
                        var _pushState = history.pushState;
                        history.pushState = function() {
                            var ret = _pushState.apply(this, arguments);
                            reportUrl(location.href);
                            return ret;
                        };
                        var _replaceState = history.replaceState;
                        history.replaceState = function() {
                            var ret = _replaceState.apply(this, arguments);
                            reportUrl(location.href);
                            return ret;
                        };
                    } catch(e) {}

                    window.addEventListener('popstate', function() { reportUrl(location.href); }, true);
                    window.addEventListener('hashchange', function() { reportUrl(location.href); }, true);
                    window.addEventListener('yt-navigate-finish', function() { reportUrl(location.href); }, true);
                    window.addEventListener('yt-page-data-updated', function() { reportUrl(location.href); }, true);

                    setInterval(function() {
                        reportUrl(location.href);
                    }, 250);
                }

                // Sincronización de escritura de texto en tiempo real iPad -> TV
                function setupInputSync() {
                    function getSelector(el) {
                        if (!el) return '';
                        if (el.id) return '#' + CSS.escape(el.id);
                        if (el.getAttribute('name')) return el.tagName.toLowerCase() + '[name="' + CSS.escape(el.getAttribute('name')) + '"]';
                        if (el.getAttribute('placeholder')) return el.tagName.toLowerCase() + '[placeholder="' + CSS.escape(el.getAttribute('placeholder')) + '"]';
                        if (el.getAttribute('aria-label')) return '[aria-label="' + CSS.escape(el.getAttribute('aria-label')) + '"]';
                        if (el.className && typeof el.className === 'string') {
                            var cls = el.className.trim().split(/\\s+/).filter(function(c) { return c && !c.includes(':'); }).slice(0, 2).join('.');
                            if (cls) return el.tagName.toLowerCase() + '.' + cls;
                        }
                        return el.tagName.toLowerCase();
                    }

                    function onInputEvent(e) {
                        var el = e.target;
                        if (!el) return;
                        var tag = el.tagName ? el.tagName.toUpperCase() : '';
                        if (tag === 'INPUT' || tag === 'TEXTAREA' || el.isContentEditable) {
                            var val = (tag === 'INPUT' || tag === 'TEXTAREA') ? el.value : (el.innerText || '');
                            var sel = getSelector(el);
                            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.inputSyncHandler) {
                                window.webkit.messageHandlers.inputSyncHandler.postMessage({
                                    selector: sel,
                                    value: val,
                                    isEnter: false
                                });
                            }
                        }
                    }

                    document.addEventListener('input', onInputEvent, true);
                    document.addEventListener('keyup', onInputEvent, true);
                    document.addEventListener('change', onInputEvent, true);
                    document.addEventListener('keydown', function(e) {
                        if (e.key === 'Enter') {
                            var el = e.target;
                            if (!el) return;
                            var tag = el.tagName ? el.tagName.toUpperCase() : '';
                            if (tag === 'INPUT' || tag === 'TEXTAREA' || el.isContentEditable) {
                                var val = (tag === 'INPUT' || tag === 'TEXTAREA') ? el.value : (el.innerText || '');
                                var sel = getSelector(el);
                                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.inputSyncHandler) {
                                    window.webkit.messageHandlers.inputSyncHandler.postMessage({
                                        selector: sel,
                                        value: val,
                                        isEnter: true
                                    });
                                }
                            }
                        }
                    }, true);
                }

                // Reflejar toques, clics, enlaces y reproducciones desde el iPad hacia la TV
                function setupClickMirror() {
                    var lastMirrorTime = 0;
                    function handleMirror(e) {
                        var now = Date.now();
                        if (now - lastMirrorTime < 100) return;
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

                        // Reflejar inmediatamente la navegación de cualquier link o video card
                        var link = target.closest ? target.closest('a') : null;
                        if (link && link.href && link.href.indexOf('http') === 0 && link.href.indexOf('proxy.html') === -1) {
                            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.urlChangeHandler) {
                                window.webkit.messageHandlers.urlChangeHandler.postMessage(link.href);
                            }
                        }

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
                        if (lastAction === action && (now - lastActionTime) < 1500) return;
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
                        setupClickMirror();
                        setupVideoSync();
                        setupUrlChangeSync();
                        setupInputSync();
                        detectDocumentPages();
                        setTimeout(detectDocumentPages, 1000);
                    });
                } else {
                    setupClickMirror();
                    setupVideoSync();
                    setupUrlChangeSync();
                    setupInputSync();
                    detectDocumentPages();
                    setTimeout(detectDocumentPages, 1000);
                }
            })();
            """
            let userScript = WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: false)
            contentController.addUserScript(userScript)
        }
        config.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.bounces = true
        webView.scrollView.delegate = context.coordinator
        webView.backgroundColor = .black
        webView.isOpaque = false

        // User Agent de escritorio para YouTube y sitios web, pero manteniendo el User Agent nativo para Vimeo y videos directos
        if !urlString.lowercased().contains("vimeo") {
            webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15"
        }

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
            let pageHeight = max(200, sv.bounds.height > 100 ? sv.bounds.height * 0.95 : UIScreen.main.bounds.height * 0.95)

            // Desplazamiento por DOM de JavaScript (esencial para presentaciones Keynote y PPTX en QuickLook)
            let jsSlide: String
            if navAction == .next {
                jsSlide = "window.scrollBy({ top: \(pageHeight), behavior: 'smooth' });"
            } else if navAction == .prev {
                jsSlide = "window.scrollBy({ top: -\(pageHeight), behavior: 'smooth' });"
            } else {
                jsSlide = "window.scrollTo({ top: 0, behavior: 'instant' });"
            }
            uiView.evaluateJavaScript(jsSlide, completionHandler: nil)

            if maxOffset > 0 {
                let currentOffset = sv.contentOffset.y
                let targetOffset: CGFloat
                if navAction == .next {
                    targetOffset = min(maxOffset, currentOffset + pageHeight)
                } else if navAction == .prev {
                    targetOffset = max(0, currentOffset - pageHeight)
                } else {
                    targetOffset = 0
                }
                sv.setContentOffset(CGPoint(x: sv.contentOffset.x, y: targetOffset), animated: true)
            }
        }

        // 4. Ejecución de Controles de Video Web (desde la botonera DTB)
        if context.coordinator.lastWebActionId != appState.webControlTriggerId, let cmd = appState.webControlCommand {
            context.coordinator.lastWebActionId = appState.webControlTriggerId
            executeWebCommand(cmd, in: uiView, coordinator: context.coordinator)
        }

        // 5. Ejecución de sincronización de video iPad -> TV (exclusivo para modo .external, nunca en iPad)
        if mode == .external, context.coordinator.lastExternalActionId != appState.externalWebControlTriggerId, let cmd = appState.externalWebControlCommand {
            context.coordinator.lastExternalActionId = appState.externalWebControlTriggerId
            executeWebCommand(cmd, in: uiView, coordinator: context.coordinator)
        }
    }

    private func executeWebCommand(_ command: WebControlCommand, in webView: WKWebView, coordinator: Coordinator) {
        switch command {
        case .navigate(let url):
            let clean = url.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !clean.isEmpty, WebViewRepresentable.isValidTopLevelWebUrl(clean), let targetURL = URL(string: clean) else { return }
            if webView.url?.absoluteString != clean {
                coordinator.lastLoadedURL = clean
                webView.load(URLRequest(url: targetURL))
            }

        case .syncInput(let selector, let value):
            let escapedValue = value
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "'", with: "\\'")
                .replacingOccurrences(of: "\n", with: "\\n")
                .replacingOccurrences(of: "\r", with: "")
            let escapedSelector = selector
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "'", with: "\\'")
            let js = """
            (function() {
                var el = null;
                try {
                    if ('\(escapedSelector)' !== '') {
                        el = document.querySelector('\(escapedSelector)');
                    }
                } catch(e) {}
                if (!el) {
                    el = document.querySelector('input[name="search_query"], input#search, input[type="search"], input[type="text"], textarea');
                }
                if (el) {
                    if ('value' in el) {
                        el.value = '\(escapedValue)';
                    } else {
                        el.innerText = '\(escapedValue)';
                    }
                    try {
                        el.dispatchEvent(new Event('input', { bubbles: true }));
                        el.dispatchEvent(new Event('change', { bubbles: true }));
                    } catch(e) {}
                }
            })();
            """
            webView.evaluateJavaScript(js, completionHandler: nil)

        case .submitInput(let selector):
            let escapedSelector = selector
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "'", with: "\\'")
            let js = """
            (function() {
                var el = null;
                try {
                    if ('\(escapedSelector)' !== '') el = document.querySelector('\(escapedSelector)');
                } catch(e) {}
                if (!el) {
                    el = document.querySelector('input[name="search_query"], input#search, input[type="search"], input[type="text"]');
                }
                if (el) {
                    var enterEvent = new KeyboardEvent('keydown', { key: 'Enter', code: 'Enter', keyCode: 13, which: 13, bubbles: true });
                    el.dispatchEvent(enterEvent);
                    var form = el.closest('form');
                    if (form) {
                        if (typeof form.requestSubmit === 'function') {
                            form.requestSubmit();
                        } else {
                            form.submit();
                        }
                    }
                }
                var searchBtn = document.querySelector('button#search-icon-legacy, button[aria-label*="Search" i], button[aria-label*="Buscar" i], .search-btn');
                if (searchBtn) {
                    try { searchBtn.click(); } catch(e) {}
                }
            })();
            """
            webView.evaluateJavaScript(js, completionHandler: nil)

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
            let escapedSelector = selector
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "'", with: "\\'")
            let js = """
            (function() {
                // 1. Eliminar popup de Google si estuviera visible
                var gp = document.getElementById('credential_picker_container') || document.querySelector('iframe[src*="accounts.google.com/gsi"]');
                if (gp) {
                    gp.remove();
                    if (\(xRatio) > 0.5 && \(yRatio) < 0.35) return;
                }

                // 2. Click por selector directo si existe
                if ('\(escapedSelector)' && '\(escapedSelector)' !== '') {
                    try {
                        var elSel = document.querySelector('\(escapedSelector)');
                        if (elSel) {
                            elSel.click();
                            var pBtn = elSel.closest('button, a, [role="button"], video, .play, .vp-play-button');
                            if (pBtn && pBtn !== elSel) pBtn.click();
                            var link = elSel.closest('a');
                            if (link && link.href && link.href.indexOf('http') === 0 && link.href.indexOf('proxy.html') === -1) {
                                window.location.href = link.href;
                            }
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
                        var aTag = el.closest('a');
                        if (aTag && aTag.href && aTag.href.indexOf('http') === 0 && aTag.href.indexOf('proxy.html') === -1) {
                            window.location.href = aTag.href;
                        }
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

        if clean.hasPrefix("http://") || clean.hasPrefix("https://") {
            guard WebViewRepresentable.isValidTopLevelWebUrl(clean), let url = URL(string: clean) else { return }
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

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, UIScrollViewDelegate, WKScriptMessageHandler {
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
            } else if message.name == "urlChangeHandler", let newUrl = message.body as? String, !newUrl.isEmpty {
                guard WebViewRepresentable.isValidTopLevelWebUrl(newUrl) else { return }
                DispatchQueue.main.async {
                    if self.parent.appState.webUrl != newUrl {
                        self.parent.appState.webUrl = newUrl
                    }
                    if self.parent.appState.projection.content != newUrl {
                        self.parent.appState.projection = ProjectionData(type: .web, content: newUrl)
                    }
                    self.parent.onNavigation?(newUrl)
                    self.parent.appState.sendExternalWebCommand(.navigate(url: newUrl))
                }
            } else if message.name == "inputSyncHandler", let dict = message.body as? [String: Any] {
                let sel = dict["selector"] as? String ?? ""
                let val = dict["value"] as? String ?? ""
                let isEnter = dict["isEnter"] as? Bool ?? false
                DispatchQueue.main.async {
                    self.parent.appState.sendExternalWebCommand(.syncInput(selector: sel, value: val))
                    if isEnter {
                        self.parent.appState.sendExternalWebCommand(.submitInput(selector: sel))
                    }
                }
            } else if message.name == "documentPageCountHandler", let count = message.body as? Int, count > 1 {
                DispatchQueue.main.async {
                    if self.parent.appState.documentTotalPages != count {
                        self.parent.appState.documentTotalPages = count
                    }
                }
            } else if message.name == "clickMirrorHandler", let dict = message.body as? [String: Any] {
                let xRatio = dict["xRatio"] as? Double ?? 0.5
                let yRatio = dict["yRatio"] as? Double ?? 0.5
                let sel = dict["selector"] as? String ?? ""
                DispatchQueue.main.async {
                    self.parent.appState.sendExternalWebCommand(.mirrorClick(xRatio: xRatio, yRatio: yRatio, selector: sel))
                }
            } else if message.name == "videoPlaybackSync", let dict = message.body as? [String: Any], let action = dict["action"] as? String {
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

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Manejar links que abren en nueva pestaña (target="_blank")
            if navigationAction.targetFrame == nil {
                if let url = navigationAction.request.url?.absoluteString,
                   WebViewRepresentable.isValidTopLevelWebUrl(url),
                   let u = navigationAction.request.url {
                    webView.load(URLRequest(url: u))
                }
                decisionHandler(.cancel)
                return
            }

            // CRÍTICO: Solo frames principales deben cambiar la URL global de la app y del TV.
            // Los subframes / iframes (como proxy.html de Vimeo, auth frames o anuncios) NUNCA deben sobrescribir la URL.
            guard navigationAction.targetFrame?.isMainFrame == true else {
                decisionHandler(.allow)
                return
            }

            if parent.mode != .external,
               let url = navigationAction.request.url?.absoluteString,
               WebViewRepresentable.isValidTopLevelWebUrl(url) {
                DispatchQueue.main.async {
                    if self.parent.appState.webUrl != url {
                        self.parent.appState.webUrl = url
                    }
                    if self.parent.appState.projection.content != url {
                        self.parent.appState.projection = ProjectionData(type: .web, content: url)
                    }
                    self.parent.appState.sendExternalWebCommand(.navigate(url: url))
                }
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            if parent.mode != .external,
               let url = webView.url?.absoluteString,
               WebViewRepresentable.isValidTopLevelWebUrl(url) {
                DispatchQueue.main.async {
                    if self.parent.appState.webUrl != url {
                        self.parent.appState.webUrl = url
                    }
                    if self.parent.appState.projection.content != url {
                        self.parent.appState.projection = ProjectionData(type: .web, content: url)
                    }
                    self.parent.appState.sendExternalWebCommand(.navigate(url: url))
                }
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if let current = webView.url?.absoluteString, WebViewRepresentable.isValidTopLevelWebUrl(current) {
                parent.onNavigation?(current)
            }

            // Detección automática del número de páginas en presentaciones (.key, .pptx)
            let countScript = """
            (function() {
                var slides = document.querySelectorAll('.slide, .page, section, [data-slide-index], [data-page-number], div[id*="slide"], canvas');
                if (slides && slides.length > 1) return slides.length;
                var totalH = Math.max(document.body.scrollHeight, document.documentElement.scrollHeight, document.body.offsetHeight);
                var vh = window.innerHeight || 768;
                if (totalH > vh * 1.1) return Math.max(1, Math.round(totalH / vh));
                return 1;
            })();
            """
            webView.evaluateJavaScript(countScript) { [weak self] res, _ in
                if let detected = res as? Int, detected > 1 {
                    DispatchQueue.main.async {
                        if self?.parent.appState.documentTotalPages != detected {
                            self?.parent.appState.documentTotalPages = detected
                        }
                    }
                }
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

                    // Sincronización automática de videos y reproducción en TV
                    var autoplayCount = 0;
                    var autoplayTimer = setInterval(function() {
                        var vids = document.querySelectorAll('video');
                        if (vids.length > 0) {
                            for (var i = 0; i < vids.length; i++) {
                                vids[i].setAttribute('playsinline', '');
                                vids[i].setAttribute('webkit-playsinline', '');
                                vids[i].style.setProperty('object-fit', 'contain', 'important');
                                if (vids[i].paused && autoplayCount < 12) {
                                    autoplayCount++;
                                    var p = vids[i].play();
                                    if (p && p.catch) {
                                        p.catch(function() {
                                            vids[i].muted = true;
                                            vids[i].play();
                                        });
                                    }
                                }
                            }
                        }
                        if (autoplayCount >= 12) clearInterval(autoplayTimer);
                    }, 500);
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
