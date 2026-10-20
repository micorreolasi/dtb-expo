import SwiftUI
import UniformTypeIdentifiers

struct DocumentsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showDocumentPicker = false

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
                        .chip(fill: Theme.blue.opacity(0.12), border: Theme.blue.opacity(0.3), radius: 6)

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

                // Panel de Control Remoto de Documento para TV (Flechas Direccionales, Zoom y Páginas)
                ScrollView {
                    VStack(spacing: 24) {
                        // 1. Tarjeta de Navegación de Hojas / Páginas
                        VStack(spacing: 12) {
                            HStack {
                                Label("Navegación de Hojas", systemImage: "book.pages")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Theme.textSoft)
                                Spacer()
                                Text("Pág. \(appState.documentCurrentPage + 1) de \(max(1, appState.documentTotalPages))")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Theme.blue)
                            }

                            HStack(spacing: 14) {
                                Button {
                                    appState.prevDocumentPage()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 15, weight: .bold))
                                        Text("Hoja Anterior")
                                            .font(.system(size: 14, weight: .bold))
                                    }
                                    .foregroundStyle(appState.documentCurrentPage > 0 ? Theme.textBright : Theme.dim)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .chip(
                                        fill: appState.documentCurrentPage > 0 ? Theme.border.opacity(0.7) : Theme.faint,
                                        border: Theme.border,
                                        radius: 10
                                    )
                                }
                                .buttonStyle(.plain)
                                .disabled(appState.documentCurrentPage <= 0)

                                Button {
                                    appState.nextDocumentPage()
                                } label: {
                                    HStack(spacing: 8) {
                                        Text("Hoja Siguiente")
                                            .font(.system(size: 14, weight: .bold))
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 15, weight: .bold))
                                    }
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(
                                        appState.documentCurrentPage + 1 < appState.documentTotalPages ? Theme.blue : Theme.dim,
                                        in: RoundedRectangle(cornerRadius: 10)
                                    )
                                }
                                .buttonStyle(.plain)
                                .disabled(appState.documentCurrentPage + 1 >= appState.documentTotalPages)
                            }
                        }
                        .padding(16)
                        .background(Theme.panel, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))

                        // 2. Tarjetas de Cruceta Direccional y Zoom
                        HStack(alignment: .top, spacing: 20) {
                            // Cruceta Direccional (Arriba, Abajo, Izquierda, Derecha, Centrar)
                            VStack(spacing: 12) {
                                HStack {
                                    Label("Mover en Pantalla (TV)", systemImage: "arrow.up.and.down.and.arrow.left.and.right")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(Theme.textSoft)
                                    Spacer()
                                }

                                VStack(spacing: 8) {
                                    // Botón Arriba
                                    Button {
                                        appState.scrollDocumentUp()
                                    } label: {
                                        VStack(spacing: 2) {
                                            Image(systemName: "arrow.up")
                                                .font(.system(size: 18, weight: .bold))
                                            Text("Arriba")
                                                .font(.system(size: 10, weight: .bold))
                                        }
                                        .foregroundStyle(Theme.textBright)
                                        .frame(width: 80, height: 54)
                                        .chip(fill: Theme.border.opacity(0.8), border: Theme.border, radius: 10)
                                    }
                                    .buttonStyle(.plain)

                                    // Fila Central: Izquierda - Centrar - Derecha
                                    HStack(spacing: 8) {
                                        Button {
                                            appState.scrollDocumentLeft()
                                        } label: {
                                            VStack(spacing: 2) {
                                                Image(systemName: "arrow.left")
                                                    .font(.system(size: 18, weight: .bold))
                                                Text("Izquierda")
                                                    .font(.system(size: 10, weight: .bold))
                                            }
                                            .foregroundStyle(Theme.textBright)
                                            .frame(width: 80, height: 54)
                                            .chip(fill: Theme.border.opacity(0.8), border: Theme.border, radius: 10)
                                        }
                                        .buttonStyle(.plain)

                                        Button {
                                            appState.centerDocumentScroll()
                                        } label: {
                                            VStack(spacing: 2) {
                                                Image(systemName: "scope")
                                                    .font(.system(size: 18, weight: .bold))
                                                Text("Centrar")
                                                    .font(.system(size: 10, weight: .bold))
                                            }
                                            .foregroundStyle(Theme.blue)
                                            .frame(width: 80, height: 54)
                                            .chip(fill: Theme.blue.opacity(0.12), border: Theme.blue.opacity(0.4), radius: 10)
                                        }
                                        .buttonStyle(.plain)

                                        Button {
                                            appState.scrollDocumentRight()
                                        } label: {
                                            VStack(spacing: 2) {
                                                Image(systemName: "arrow.right")
                                                    .font(.system(size: 18, weight: .bold))
                                                Text("Derecha")
                                                    .font(.system(size: 10, weight: .bold))
                                            }
                                            .foregroundStyle(Theme.textBright)
                                            .frame(width: 80, height: 54)
                                            .chip(fill: Theme.border.opacity(0.8), border: Theme.border, radius: 10)
                                        }
                                        .buttonStyle(.plain)
                                    }

                                    // Botón Abajo
                                    Button {
                                        appState.scrollDocumentDown()
                                    } label: {
                                        VStack(spacing: 2) {
                                            Image(systemName: "arrow.down")
                                                .font(.system(size: 18, weight: .bold))
                                            Text("Abajo")
                                                .font(.system(size: 10, weight: .bold))
                                        }
                                        .foregroundStyle(Theme.textBright)
                                        .frame(width: 80, height: 54)
                                        .chip(fill: Theme.border.opacity(0.8), border: Theme.border, radius: 10)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.vertical, 8)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(Theme.panel, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))

                            // Controles de Zoom
                            VStack(spacing: 12) {
                                HStack {
                                    Label("Control de Zoom", systemImage: "plus.magnifyingglass")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(Theme.textSoft)
                                    Spacer()
                                    Text("\(Int(appState.documentZoomScale * 100))%")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(Theme.blue)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .chip(fill: Theme.blue.opacity(0.12), radius: 6)
                                }

                                VStack(spacing: 10) {
                                    HStack(spacing: 10) {
                                        Button {
                                            appState.zoomInDocument()
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: "plus")
                                                    .font(.system(size: 15, weight: .bold))
                                                Text("Zoom In")
                                                    .font(.system(size: 13, weight: .bold))
                                            }
                                            .foregroundStyle(Theme.textBright)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 48)
                                            .chip(fill: Theme.border.opacity(0.8), border: Theme.border, radius: 8)
                                        }
                                        .buttonStyle(.plain)

                                        Button {
                                            appState.zoomOutDocument()
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: "minus")
                                                    .font(.system(size: 15, weight: .bold))
                                                Text("Zoom Out")
                                                    .font(.system(size: 13, weight: .bold))
                                            }
                                            .foregroundStyle(Theme.textBright)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 48)
                                            .chip(fill: Theme.border.opacity(0.8), border: Theme.border, radius: 8)
                                        }
                                        .buttonStyle(.plain)
                                    }

                                    Button {
                                        appState.resetDocumentZoom()
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                                .font(.system(size: 14, weight: .bold))
                                            Text("100% (Hoja Completa)")
                                                .font(.system(size: 13, weight: .bold))
                                        }
                                        .foregroundStyle(appState.documentZoomScale <= 1.05 ? Theme.blue : Theme.textSoft)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .chip(
                                            fill: appState.documentZoomScale <= 1.05 ? Theme.blue.opacity(0.12) : Theme.border.opacity(0.5),
                                            border: appState.documentZoomScale <= 1.05 ? Theme.blue.opacity(0.4) : Theme.border,
                                            radius: 8
                                        )
                                    }
                                    .buttonStyle(.plain)

                                    Button {
                                        appState.fitDocumentWidth()
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "arrow.left.and.right")
                                                .font(.system(size: 14, weight: .bold))
                                            Text("Ajustar al Ancho TV")
                                                .font(.system(size: 13, weight: .bold))
                                        }
                                        .foregroundStyle(Theme.textSoft)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .chip(fill: Theme.border.opacity(0.5), border: Theme.border, radius: 8)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.top, 4)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(Theme.panel, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                        }

                        // 3. Estado de Proyección en TV
                        HStack(spacing: 12) {
                            Image(systemName: "tv.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(Theme.blue)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Proyectando en Pantalla Externa (TV)")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Theme.textBright)
                                Text("El documento se muestra en la TV en formato completo. Utiliza la cruceta para moverte en la hoja cuando apliques zoom.")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.muted)
                            }

                            Spacer()
                        }
                        .padding(14)
                        .background(Theme.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.blue.opacity(0.2), lineWidth: 1))
                    }
                    .padding(20)
                }
                .background(Theme.bg)
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
            appState.documentCurrentPage = 0
            appState.resetDocumentZoom()
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
