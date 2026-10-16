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
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.bounces = true
        webView.scrollView.delegate = context.coordinator

        loadURL(in: webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.parent = self

        // 1. Sincronizar URL si cambia
        if let currentURL = uiView.url?.absoluteString, currentURL != urlString {
            loadURL(in: uiView)
        } else if uiView.url == nil {
            loadURL(in: uiView)
        }

        // 2. Si es la TV externa (modo .external), reflejar el scroll que el operador hace en el iPad
        if mode == .external {
            let sv = uiView.scrollView
            let maxOffset = max(0, sv.contentSize.height - sv.bounds.height)
            if maxOffset > 0 {
                let targetY = maxOffset * appState.webScrollRatio
                if abs(sv.contentOffset.y - targetY) > 2 {
                    sv.setContentOffset(CGPoint(x: 0, y: targetY), animated: false)
                }
            }
        }

        // 3. Manejo de botones de scroll por página (Hoja Siguiente / Anterior)
        if let triggerId = navTriggerId, triggerId != context.coordinator.lastTriggerId {
            context.coordinator.lastTriggerId = triggerId
            let sv = uiView.scrollView
            let pageHeight = max(200, sv.bounds.height * 0.85)
            let currentOffset = sv.contentOffset.y

            if navAction == .next {
                let maxOffset = max(0, sv.contentSize.height - sv.bounds.height)
                let nextOffset = min(maxOffset, currentOffset + pageHeight)
                sv.setContentOffset(CGPoint(x: 0, y: nextOffset), animated: true)
                uiView.evaluateJavaScript("window.scrollBy({ top: window.innerHeight * 0.85, behavior: 'smooth' });", completionHandler: nil)
            } else if navAction == .prev {
                let prevOffset = max(0, currentOffset - pageHeight)
                sv.setContentOffset(CGPoint(x: 0, y: prevOffset), animated: true)
                uiView.evaluateJavaScript("window.scrollBy({ top: -window.innerHeight * 0.85, behavior: 'smooth' });", completionHandler: nil)
            }
        }
    }

    private func loadURL(in webView: WKWebView) {
        if urlString.hasPrefix("http://") || urlString.hasPrefix("https://"), let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        } else {
            let cleanPath: String = {
                if urlString.hasPrefix("file://"), let u = URL(string: urlString) {
                    return u.path
                }
                return urlString
            }()
            let localURL = URL(fileURLWithPath: cleanPath)
            let accessDir = localURL.deletingLastPathComponent().deletingLastPathComponent()
            webView.loadFileURL(localURL, allowingReadAccessTo: accessDir)
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate, UIScrollViewDelegate {
        var parent: WebViewRepresentable
        var lastTriggerId: UUID? = nil

        init(_ parent: WebViewRepresentable) {
            self.parent = parent
        }

        // Captura el scroll en el iPad y lo envía a AppState para reflejarlo en el TV
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            // Solo emitir si NO estamos en la pantalla externa para evitar bucle
            guard parent.mode != .external else { return }
            let maxOffset = max(1, scrollView.contentSize.height - scrollView.bounds.height)
            let ratio = max(0.0, min(1.0, scrollView.contentOffset.y / maxOffset))
            DispatchQueue.main.async {
                self.parent.appState.webScrollRatio = ratio
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if let current = webView.url?.absoluteString {
                parent.onNavigation?(current)
                if parent.mode != .external, current != parent.appState.projection.content && current.starts(with: "http") {
                    DispatchQueue.main.async {
                        self.parent.appState.webUrl = current
                        self.parent.appState.projection = ProjectionData(type: .web, content: current)
                    }
                }
            }
        }
    }
}
