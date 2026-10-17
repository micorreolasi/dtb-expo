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
                        .chip(fill: Theme.blue.opacity(0.15), border: Theme.blue.opacity(0.3), radius: 6)

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

                // Visualización a pantalla completa del documento dentro del módulo (igual que en web)
                PDFDocumentView(
                    uri: appState.currentDocPath.isEmpty ? appState.projection.content : appState.currentDocPath,
                    mode: .presentation
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
