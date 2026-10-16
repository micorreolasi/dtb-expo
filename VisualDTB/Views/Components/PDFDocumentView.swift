import SwiftUI
import PDFKit

struct PDFDocumentView: View {
    @EnvironmentObject var appState: AppState
    let uri: String

    var body: some View {
        let isPDF = uri.lowercased().hasSuffix(".pdf")
        if isPDF, let docURL = resolveURL(uri) {
            PDFKitRepresentable(
                url: docURL,
                navAction: appState.documentPageAction,
                navTriggerId: appState.documentNavTriggerId
            )
            .ignoresSafeArea()
        } else {
            WebViewRepresentable(
                urlString: uri,
                navAction: appState.documentPageAction,
                navTriggerId: appState.documentNavTriggerId
            )
            .ignoresSafeArea()
        }
    }

    private func resolveURL(_ string: String) -> URL? {
        if string.hasPrefix("http://") || string.hasPrefix("https://") {
            return URL(string: string)
        }
        let cleanPath: String = {
            if string.hasPrefix("file://"), let u = URL(string: string) {
                return u.path
            }
            return string
        }()
        return URL(fileURLWithPath: cleanPath)
    }
}

private struct PDFKitRepresentable: UIViewRepresentable {
    let url: URL
    var navAction: DocumentNavAction?
    var navTriggerId: UUID?

    class Coordinator: NSObject {
        var lastTriggerId: UUID?
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .horizontal
        pdfView.usePageViewController(true)
        if let doc = PDFDocument(url: url) {
            pdfView.document = doc
        }
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document?.documentURL != url {
            uiView.document = PDFDocument(url: url)
        }

        if let triggerId = navTriggerId, triggerId != context.coordinator.lastTriggerId {
            context.coordinator.lastTriggerId = triggerId
            guard let doc = uiView.document else { return }
            let currentIndex = uiView.currentPage.flatMap { doc.index(for: $0) } ?? 0
            if navAction == .next {
                if currentIndex + 1 < doc.pageCount, let nextPage = doc.page(at: currentIndex + 1) {
                    uiView.go(to: nextPage)
                } else if uiView.canGoToNextPage {
                    uiView.goToNextPage(nil)
                }
            } else if navAction == .prev {
                if currentIndex > 0, let prevPage = doc.page(at: currentIndex - 1) {
                    uiView.go(to: prevPage)
                } else if uiView.canGoToPreviousPage {
                    uiView.goToPreviousPage(nil)
                }
            }
        }
    }
}
