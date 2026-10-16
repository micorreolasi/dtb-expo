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

        // 2. Si es la TV externa (modo .external), reflejar el scroll y el zoom que el operador hace en el iPad
        if mode == .external {
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

        // 3. Manejo de botones de salto de página (Hoja Siguiente / Anterior)
        if let triggerId = navTriggerId, triggerId != context.coordinator.lastTriggerId {
            context.coordinator.lastTriggerId = triggerId
            let sv = uiView.scrollView
            let pageHeight = max(200, sv.bounds.height * 0.85)
            let currentOffset = sv.contentOffset.y

            if navAction == .next {
                let maxOffset = max(0, sv.contentSize.height - sv.bounds.height)
                let nextOffset = min(maxOffset, currentOffset + pageHeight)
                sv.setContentOffset(CGPoint(x: sv.contentOffset.x, y: nextOffset), animated: true)
            } else if navAction == .prev {
                let prevOffset = max(0, currentOffset - pageHeight)
                sv.setContentOffset(CGPoint(x: sv.contentOffset.x, y: prevOffset), animated: true)
            }
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

    class Coordinator: NSObject, WKNavigationDelegate, UIScrollViewDelegate {
        var parent: WebViewRepresentable
        var lastTriggerId: UUID? = nil
        var lastLoadedURL: String? = nil

        init(_ parent: WebViewRepresentable) {
            self.parent = parent
        }

        // Captura el scroll y zoom en el iPad y lo envía a AppState para reflejarlo en el TV
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard parent.mode != .external else { return }
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
