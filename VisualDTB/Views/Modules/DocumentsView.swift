import SwiftUI
import UniformTypeIdentifiers

struct DocumentsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showDocumentPicker = false
    @State private var showDocumentTouchpad = true

    private var hasDoc: Bool {
        (appState.projection.type == .document || appState.projection.type == .pdf) && (!appState.currentDocPath.isEmpty || !appState.projection.content.isEmpty)
    }

    var body: some View {
        if hasDoc {
            VStack(spacing: 0) {
                // Barra superior de navegación interactiva del documento (idéntica a WebViewModule)
                HStack(spacing: 8) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.red)

                    Text(appState.projection.title ?? appState.currentDocName.nilIfEmpty ?? "Documento Activo")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.textBright)
                        .lineLimit(1)

                    Spacer()

                    // Indicador de página actual en la barra superior
                    Text("\(appState.documentCurrentPage + 1) / \(max(1, appState.documentTotalPages))")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .chip(fill: Theme.blue.opacity(0.15), border: Theme.blue.opacity(0.3), radius: 6)

                    // Selector Táctil 2D / Hoja
                    HStack(spacing: 0) {
                        Button {
                            showDocumentTouchpad = true
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: "scope")
                                    .font(.system(size: 11))
                                Text("Radar 2D TV")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundStyle(showDocumentTouchpad ? .white : Theme.textSoft)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(showDocumentTouchpad ? Theme.sky : Color.clear)
                        }
                        .buttonStyle(.plain)

                        Button {
                            showDocumentTouchpad = false
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: "doc.plaintext")
                                    .font(.system(size: 11))
                                Text("Hoja")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundStyle(!showDocumentTouchpad ? .white : Theme.textSoft)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(!showDocumentTouchpad ? Theme.blue : Color.clear)
                        }
                        .buttonStyle(.plain)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border, lineWidth: 1))

                    // Botón para cambiar de documento
                    Button {
                        showDocumentPicker = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "folder")
                                .font(.system(size: 12))
                            Text("Cambiar")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundStyle(Theme.textSoft)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .chip(fill: Theme.border, radius: 6)
                    }
                    .buttonStyle(.plain)

                    // Botón cerrar (xmark rojo como en WebViewModule)
                    Button {
                        appState.clearProjection()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(Theme.red, in: RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
                .padding(10)
                .background(Theme.panel)
                .bottomBorder(Theme.border)

                // Área de visualización y control
                if showDocumentTouchpad {
                    // Previsualización y Control Táctil 2D con la imagen del radar
                    VStack(spacing: 12) {
                        DocumentRadarTouchpadView(compactMode: false)

                        // Controles rápidos de Zoom
                        HStack(spacing: 8) {
                            Button {
                                appState.zoomOutDocument()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "minus.magnifyingglass")
                                    Text("Zoom -")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .foregroundStyle(Theme.blue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .chip(fill: Theme.blue.opacity(0.12), border: Theme.blue.opacity(0.3), radius: 8)
                            }
                            .buttonStyle(.plain)

                            Button {
                                appState.resetDocumentZoom()
                            } label: {
                                Text("100% (Reset)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(appState.documentZoomScale <= 1.05 ? .white : Theme.textSoft)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .chip(fill: Theme.panel, border: Theme.border, radius: 8)
                            }
                            .buttonStyle(.plain)

                            Button {
                                appState.fitDocumentWidth()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.left.and.right.square")
                                    Text("Ajustar Ancho TV")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .foregroundStyle(appState.documentZoomScale >= 2.1 ? .white : Theme.green)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .chip(
                                    fill: appState.documentZoomScale >= 2.1 ? Theme.green : Theme.green.opacity(0.15),
                                    border: Theme.green.opacity(0.4),
                                    radius: 8
                                )
                            }
                            .buttonStyle(.plain)

                            Button {
                                appState.zoomInDocument()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.magnifyingglass")
                                    Text("Zoom +")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .foregroundStyle(Theme.blue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .chip(fill: Theme.blue.opacity(0.12), border: Theme.blue.opacity(0.3), radius: 8)
                            }
                            .buttonStyle(.plain)
                        }

                        // Navegación de Hojas del Documento
                        HStack(spacing: 12) {
                            Button {
                                appState.prevDocumentPage()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                    Text("Hoja Anterior")
                                        .font(.system(size: 13, weight: .bold))
                                }
                                .foregroundStyle(appState.documentCurrentPage > 0 ? Theme.blue : Theme.dim)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .chip(
                                    fill: appState.documentCurrentPage > 0 ? Theme.blue.opacity(0.12) : Theme.panel,
                                    border: Theme.border,
                                    radius: 8
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(appState.documentCurrentPage <= 0)

                            Text("Página \(appState.documentCurrentPage + 1) de \(max(1, appState.documentTotalPages))")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Theme.textBright)

                            Button {
                                appState.nextDocumentPage()
                            } label: {
                                HStack(spacing: 4) {
                                    Text("Hoja Siguiente")
                                        .font(.system(size: 13, weight: .bold))
                                    Image(systemName: "chevron.right")
                                }
                                .foregroundStyle((appState.documentCurrentPage < appState.documentTotalPages - 1) ? Theme.blue : Theme.dim)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .chip(
                                    fill: (appState.documentCurrentPage < appState.documentTotalPages - 1) ? Theme.blue.opacity(0.12) : Theme.panel,
                                    border: Theme.border,
                                    radius: 8
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(appState.documentCurrentPage >= appState.documentTotalPages - 1)
                        }

                        Spacer()
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.bg)
                } else {
                    // Visualización directa 1:1 con la TV
                    ZStack {
                        Color.black

                        PDFDocumentView(
                            uri: appState.currentDocPath.isEmpty ? appState.projection.content : appState.currentDocPath,
                            mode: .presentation
                        )
                    }
                    .aspectRatio(appState.externalDisplayAspectRatio, contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                }
            }
            .fileImporter(
                isPresented: $showDocumentPicker,
                allowedContentTypes: [.pdf, .presentation, .spreadsheet, .text, .plainText, UTType(filenameExtension: "docx") ?? .data],
                allowsMultipleSelection: false
            ) { result in
                handleImportDoc(result)
            }
        } else {
            // Pantalla inicial para abrir archivo cuando no hay documento proyectado
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
                            Text("Visualización integrada nativa en iPad y sincronizada a TV")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.muted)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .chip(
                            fill: Theme.red.opacity(0.08),
                            border: Theme.red,
                            radius: 12,
                            lineWidth: 2
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(appState.isReadingDocument)
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
