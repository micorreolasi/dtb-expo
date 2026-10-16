import SwiftUI
import WebKit

struct WebViewRepresentable: UIViewRepresentable {
    let urlString: String
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

        loadURL(in: webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let currentURL = uiView.url?.absoluteString, currentURL != urlString {
            loadURL(in: uiView)
        } else if uiView.url == nil {
            loadURL(in: uiView)
        }

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

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebViewRepresentable
        var lastTriggerId: UUID? = nil

        init(_ parent: WebViewRepresentable) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if let current = webView.url?.absoluteString {
                parent.onNavigation?(current)
            }
        }
    }
}
