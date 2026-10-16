import SwiftUI
import PDFKit

struct PDFDocumentView: View {
    @EnvironmentObject var appState: AppState
    let uri: String
    var mode: ProjectionMode = .presentation

    var body: some View {
        let isPDF = uri.lowercased().hasSuffix(".pdf")
        if isPDF, let docURL = resolveURL(uri) {
            PDFKitRepresentable(
                url: docURL,
                currentPage: $appState.documentCurrentPage,
                totalPages: $appState.documentTotalPages,
                navAction: appState.documentPageAction,
                navTriggerId: appState.documentNavTriggerId,
                mode: mode
            )
            .ignoresSafeArea()
        } else {
            WebViewRepresentable(
                urlString: uri,
                mode: mode,
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
    @Binding var currentPage: Int
    @Binding var totalPages: Int
    var navAction: DocumentNavAction?
    var navTriggerId: UUID?
    let mode: ProjectionMode

    class Coordinator: NSObject {
        var parent: PDFKitRepresentable
        var lastTriggerId: UUID?
        var isSelfUpdating = false
        var observer: Any?

        init(_ parent: PDFKitRepresentable) {
            self.parent = parent
        }

        deinit {
            if let observer {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .horizontal
        // usePageViewController(false) elimina el bug en iOS donde la página queda a la mitad y regresa a la 1
        pdfView.usePageViewController(false)
        pdfView.backgroundColor = .black

        if let doc = PDFDocument(url: url) {
            pdfView.document = doc
            DispatchQueue.main.async {
                self.totalPages = doc.pageCount
            }
            if currentPage > 0, currentPage < doc.pageCount, let initialPage = doc.page(at: currentPage) {
                pdfView.go(to: initialPage)
            }
        }

        // Si es la vista previa interactiva o presentación en iPad, escuchar cuando el usuario cambia de página con gestos
        let coordinator = context.coordinator
        coordinator.observer = NotificationCenter.default.addObserver(
            forName: .PDFViewPageChanged,
            object: pdfView,
            queue: .main
        ) { [weak coordinator] _ in
            guard let coord = coordinator, !coord.isSelfUpdating else { return }
            guard let doc = pdfView.document, let current = pdfView.currentPage else { return }
            let index = doc.index(for: current)
            if index != coord.parent.currentPage {
                DispatchQueue.main.async {
                    coord.parent.currentPage = index
                }
            }
        }

        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        context.coordinator.parent = self

        // 1. Cargar nuevo documento si cambió la URL
        if uiView.document?.documentURL != url {
            if let newDoc = PDFDocument(url: url) {
                uiView.document = newDoc
                DispatchQueue.main.async {
                    self.totalPages = newDoc.pageCount
                }
                if currentPage < newDoc.pageCount, let p = newDoc.page(at: currentPage) {
                    uiView.go(to: p)
                }
            }
            return
        }

        guard let doc = uiView.document else { return }

        // 2. Sincronización precisa por número de página
        let activeIndex = uiView.currentPage.flatMap { doc.index(for: $0) } ?? 0
        if activeIndex != currentPage, currentPage >= 0, currentPage < doc.pageCount {
            context.coordinator.isSelfUpdating = true
            if let targetPage = doc.page(at: currentPage) {
                uiView.go(to: targetPage)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                context.coordinator.isSelfUpdating = false
            }
        }

        // 3. Manejo de botones de navegación (Hoja siguiente / anterior)
        if let triggerId = navTriggerId, triggerId != context.coordinator.lastTriggerId {
            context.coordinator.lastTriggerId = triggerId
            context.coordinator.isSelfUpdating = true

            let nextIdx: Int
            if navAction == .next {
                nextIdx = min(doc.pageCount - 1, activeIndex + 1)
            } else if navAction == .prev {
                nextIdx = max(0, activeIndex - 1)
            } else {
                nextIdx = activeIndex
            }

            if nextIdx != activeIndex, let targetPage = doc.page(at: nextIdx) {
                uiView.go(to: targetPage)
                DispatchQueue.main.async {
                    self.currentPage = nextIdx
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                context.coordinator.isSelfUpdating = false
            }
        }
    }
}
