import SwiftUI
import UniformTypeIdentifiers

struct DocumentsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showDocumentPicker = false

    private var hasDoc: Bool {
        appState.projection.type == .document || appState.projection.type == .pdf || !appState.currentDocPath.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ModuleTitle(text: "Gestor de Documentos (PDF, PPTX, Word)")

                // Cuadro principal para seleccionar archivo
                Button {
                    showDocumentPicker = true
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(Theme.red)
                        Text(appState.isReadingDocument ? "Abriendo archivo..." : "Seleccionar Archivo (PDF, PPTX, Word, etc.)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Theme.red)
                        Text("Visualización integrada nativa en iPad")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.muted)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .chip(
                        fill: Theme.red.opacity(0.08),
                        border: Theme.red,
                        radius: 12,
                        lineWidth: 2
                    )
                }
                .buttonStyle(.plain)
                .disabled(appState.isReadingDocument)

                // Tarjeta de documento activo con vista previa y controles completos
                if hasDoc {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Theme.red.opacity(0.15))
                                .frame(width: 40, height: 40)
                                .overlay {
                                    Image(systemName: "doc.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(Theme.red)
                                }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(appState.projection.title ?? appState.currentDocName.nilIfEmpty ?? "Documento Activo")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                Text("Sincronizado 1:1 con la TV y Vista Previa")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.green)
                            }
                            Spacer()

                            Button {
                                appState.projection = .text("")
                                appState.currentDocPath = ""
                                appState.currentDocName = ""
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Theme.textSoft)
                                    .padding(8)
                                    .chip(fill: Theme.border, radius: 6)
                            }
                            .buttonStyle(.plain)
                        }

                        // Vista previa interactiva en tiempo real (proporción idéntica a la TV)
                        ZStack {
                            Color.black
                            PDFDocumentView(
                                uri: appState.currentDocPath.isEmpty ? appState.projection.content : appState.currentDocPath,
                                mode: .miniPreview
                            )
                        }
                        .aspectRatio(appState.externalDisplayAspectRatio, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1)
                        }

                        // CONTROLES DE ZOOM EN TIEMPO REAL (Ideal para PDFs verticales o diapositivas)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up.left.and.arrow.down.right.magnifyingglass")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Theme.blue)
                                    Text("Control de Zoom:")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(Theme.textBright)
                                }

                                Spacer()

                                Text("\(Int(appState.documentZoomScale * 100))%")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Theme.blue)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .chip(fill: Theme.blue.opacity(0.12), radius: 6)
                            }

                            HStack(spacing: 8) {
                                // Zoom Out
                                Button {
                                    appState.zoomOutDocument()
                                } label: {
                                    Image(systemName: "minus")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(Theme.blue)
                                        .frame(width: 38, height: 36)
                                        .chip(fill: Theme.border, radius: 6)
                                }
                                .buttonStyle(.plain)

                                // Slider de Zoom
                                Slider(
                                    value: Binding(
                                        get: { Double(appState.documentZoomScale) },
                                        set: { appState.setDocumentZoom(CGFloat($0)) }
                                    ),
                                    in: 1.0...3.5,
                                    step: 0.1
                                )
                                .tint(Theme.blue)

                                // Zoom In
                                Button {
                                    appState.zoomInDocument()
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(Theme.blue)
                                        .frame(width: 38, height: 36)
                                        .chip(fill: Theme.border, radius: 6)
                                }
                                .buttonStyle(.plain)
                            }

                            // Presets rápidos de Zoom
                            HStack(spacing: 8) {
                                Button {
                                    appState.resetDocumentZoom()
                                } label: {
                                    Text("100% Normal")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(appState.documentZoomScale <= 1.05 ? .white : Theme.textSoft)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 7)
                                        .chip(fill: appState.documentZoomScale <= 1.05 ? Theme.blue : Theme.border, radius: 6)
                                }
                                .buttonStyle(.plain)

                                Button {
                                    appState.fitDocumentWidth()
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.left.and.right.square.fill")
                                        Text("Ajustar al Ancho (Vertical)")
                                    }
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(appState.documentZoomScale >= 2.1 ? .white : Theme.green)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 7)
                                    .chip(fill: appState.documentZoomScale >= 2.1 ? Theme.green : Theme.green.opacity(0.12), radius: 6)
                                }
                                .buttonStyle(.plain)

                                // Si está en zoom, controles para mover verticalmente
                                if appState.documentZoomScale > 1.05 {
                                    HStack(spacing: 4) {
                                        Button {
                                            let cur = appState.documentScrollOffsetRatio.y
                                            appState.documentScrollOffsetRatio.y = max(0.0, cur - 0.15)
                                        } label: {
                                            Image(systemName: "chevron.up")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundStyle(Theme.blue)
                                                .frame(width: 32, height: 30)
                                                .chip(fill: Theme.border, radius: 6)
                                        }
                                        .buttonStyle(.plain)

                                        Button {
                                            let cur = appState.documentScrollOffsetRatio.y
                                            appState.documentScrollOffsetRatio.y = min(1.0, cur + 0.15)
                                        } label: {
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundStyle(Theme.blue)
                                                .frame(width: 32, height: 30)
                                                .chip(fill: Theme.border, radius: 6)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding(10)
                        .background(Theme.bg, in: RoundedRectangle(cornerRadius: 8))

                        // NAVEGACIÓN FLUIDA DE HOJAS / DIAPOSITIVAS
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                Button {
                                    appState.handlePrevSlide()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "chevron.left")
                                        Text("Hoja Anterior")
                                    }
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Theme.blue)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .chip(fill: Theme.blue.opacity(0.12), border: Theme.blue.opacity(0.3), radius: 8)
                                }
                                .buttonStyle(.plain)
                                .disabled(appState.documentCurrentPage <= 0)

                                Text("Hoja \(appState.documentCurrentPage + 1) de \(max(1, appState.documentTotalPages))")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Theme.textBright)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(Theme.border.opacity(0.4), in: RoundedRectangle(cornerRadius: 6))

                                Button {
                                    appState.handleNextSlide()
                                } label: {
                                    HStack(spacing: 6) {
                                        Text("Hoja Siguiente")
                                        Image(systemName: "chevron.right")
                                    }
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Theme.blue)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .chip(fill: Theme.blue.opacity(0.12), border: Theme.blue.opacity(0.3), radius: 8)
                                }
                                .buttonStyle(.plain)
                                .disabled(appState.documentCurrentPage + 1 >= appState.documentTotalPages)
                            }

                            // Slider de salto directo de hoja si tiene más de 2 páginas
                            if appState.documentTotalPages > 2 {
                                HStack(spacing: 8) {
                                    Text("Ir a:")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(Theme.muted)

                                    Slider(
                                        value: Binding(
                                            get: { Double(appState.documentCurrentPage) },
                                            set: { appState.goToDocumentPage(Int($0)) }
                                        ),
                                        in: 0...Double(max(1, appState.documentTotalPages - 1)),
                                        step: 1.0
                                    )
                                    .tint(Theme.violet)
                                }
                            }
                        }

                        // Botones de Acción (Presentar / Cambiar)
                        HStack(spacing: 10) {
                            Button {
                                appState.playlist = nil
                                let path = appState.currentDocPath.isEmpty ? appState.projection.content : appState.currentDocPath
                                appState.projection = ProjectionData(
                                    type: .document,
                                    content: path,
                                    title: appState.currentDocName
                                )
                                appState.isPresentationMode = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "tv")
                                    Text("Presentar en Pantalla Completa")
                                }
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Theme.blue, in: RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)

                            Button {
                                showDocumentPicker = true
                            } label: {
                                Text("Cambiar")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Theme.textSoft)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .chip(fill: Theme.border, radius: 8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                    .chip(fill: Theme.panel, border: Theme.border, radius: 10)
                }
            }
            .padding(20)
        }
        .background(Theme.bg)
        .fileImporter(
            isPresented: $showDocumentPicker,
            allowedContentTypes: [.pdf, .presentation, .spreadsheet, .text, .plainText, UTType(filenameExtension: "docx") ?? .data],
            allowsMultipleSelection: false
        ) { result in
            handleImportDoc(result)
        }
    }

    private func handleImportDoc(_ result: Result<[URL], Error>) {
        appState.isReadingDocument = true
        defer { appState.isReadingDocument = false }
        do {
            guard let selectedURL = try result.get().first else { return }
            let cachedURL = try MediaStorage.importDocument(from: selectedURL)
            let fileName = selectedURL.lastPathComponent
            appState.currentDocName = fileName
            appState.currentDocPath = cachedURL.path
            appState.playlist = nil // Limpiar playlist anterior para que no interfiera
            appState.projection = ProjectionData(
                type: .document,
                content: cachedURL.path,
                title: fileName
            )
        } catch {
            appState.currentAlert = AppAlert(title: "Aviso", message: "No se pudo seleccionar el documento: \(error.localizedDescription)")
        }
    }
}
