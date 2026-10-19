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
                zoomScale: $appState.documentZoomScale,
                scrollOffsetRatio: $appState.documentScrollOffsetRatio,
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
    @Binding var zoomScale: CGFloat
    @Binding var scrollOffsetRatio: CGPoint
    var navAction: DocumentNavAction?
    var navTriggerId: UUID?
    let mode: ProjectionMode

    class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: PDFKitRepresentable
        var lastTriggerId: UUID?
        var isSelfUpdating = false
        var observers: [Any] = []
        weak var internalScrollView: UIScrollView? = nil

        init(_ parent: PDFKitRepresentable) {
            self.parent = parent
        }

        deinit {
            for obs in observers {
                NotificationCenter.default.removeObserver(obs)
            }
        }

        // Sincronizar scroll solo si hay zoom activo (> 1.01)
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard parent.mode != .external, !isSelfUpdating, parent.zoomScale > 1.01 else { return }
            if scrollView.isTracking || scrollView.isDragging || scrollView.isDecelerating {
                let maxW = max(1, scrollView.contentSize.width - scrollView.bounds.width)
                let maxH = max(1, scrollView.contentSize.height - scrollView.bounds.height)
                let ratioX = max(0.0, min(1.0, scrollView.contentOffset.x / maxW))
                let ratioY = max(0.0, min(1.0, scrollView.contentOffset.y / maxH))
                DispatchQueue.main.async {
                    self.parent.scrollOffsetRatio = CGPoint(x: ratioX, y: ratioY)
                }
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
        pdfView.usePageViewController(false)
        pdfView.pageBreakMargins = .zero
        pdfView.backgroundColor = .black
        pdfView.minScaleFactor = 0.1
        pdfView.maxScaleFactor = 6.0

        if let doc = PDFDocument(url: url) {
            pdfView.document = doc
            DispatchQueue.main.async {
                self.totalPages = doc.pageCount
            }
            if currentPage > 0, currentPage < doc.pageCount, let initialPage = doc.page(at: currentPage) {
                pdfView.go(to: initialPage)
            }
        }

        let coordinator = context.coordinator

        // 1. Notificación de cambio de página
        let pageObs = NotificationCenter.default.addObserver(
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
        coordinator.observers.append(pageObs)

        // Buscar el UIScrollView interno de PDFView para escuchar scroll de zoom en iPad
        if let sv = findScrollView(in: pdfView) {
            coordinator.internalScrollView = sv
            if mode != .external {
                sv.delegate = coordinator
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

        // 3. Sincronización idéntica 1:1 de Hoja Completa y Zoom entre iPad y TV
        if zoomScale <= 1.01 {
            // MODO HOJA COMPLETA: Dejar que autoScales maneje de forma nativa el ajuste perfecto 1:1
            // (Asignar scaleFactor directamente destruye autoScales y causa zoom recortado en PDFs verticales)
            if !uiView.autoScales {
                uiView.autoScales = true
                if let current = uiView.currentPage {
                    uiView.go(to: current)
                }
            }
        } else {
            // MODO ZOOM: Solo cuando el operador deliberadamente hace zoom
            if uiView.autoScales {
                uiView.autoScales = false
            }
            let baseFit = uiView.scaleFactorForSizeToFit > 0.001 ? uiView.scaleFactorForSizeToFit : 1.0
            let targetScale = baseFit * zoomScale
            if abs(uiView.scaleFactor - targetScale) > 0.02 {
                context.coordinator.isSelfUpdating = true
                uiView.scaleFactor = targetScale
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                    context.coordinator.isSelfUpdating = false
                }
            }

            if let sv = findScrollView(in: uiView) {
                let maxW = max(0, sv.contentSize.width - sv.bounds.width)
                let maxH = max(0, sv.contentSize.height - sv.bounds.height)
                if maxW > 0 || maxH > 0 {
                    let targetOffset = CGPoint(x: maxW * scrollOffsetRatio.x, y: maxH * scrollOffsetRatio.y)
                    if mode == .external || (!sv.isDragging && !sv.isDecelerating) {
                        if abs(sv.contentOffset.x - targetOffset.x) > 2 || abs(sv.contentOffset.y - targetOffset.y) > 2 {
                            context.coordinator.isSelfUpdating = true
                            sv.setContentOffset(targetOffset, animated: false)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                                context.coordinator.isSelfUpdating = false
                            }
                        }
                    }
                }
            }
        }

        // 4. Botones de Hoja Siguiente / Hoja Anterior
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

    private func findScrollView(in view: UIView) -> UIScrollView? {
        if let sv = view as? UIScrollView { return sv }
        for sub in view.subviews {
            if let found = findScrollView(in: sub) { return found }
        }
        return nil
    }
}
