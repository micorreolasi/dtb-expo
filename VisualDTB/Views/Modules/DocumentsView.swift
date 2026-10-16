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

                // Tarjeta de documento activo
                if hasDoc {
                    VStack(spacing: 14) {
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
                                Text("Proyectando actualmente en TV")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.green)
                            }
                            Spacer()
                        }

                        // Botones de Navegación de Hojas / Diapositivas
                        HStack(spacing: 12) {
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
                        }

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
